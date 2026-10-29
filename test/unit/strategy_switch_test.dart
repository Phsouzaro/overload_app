import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/double_progression.dart';
import 'package:overload/core/progression/strategies/top_set_back_off.dart';
import 'package:overload/core/progression/strategies/wave_loading.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Troca de estratégia (ou de parâmetros) no meio de um ciclo, com o banco e o
/// registry reais.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  final now = DateTime(2026, 8, 1, 18);

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    service = ProgressionService(db, clock: () => now);
    exId = await insertExercise(db, name: 'Terra Teste');
    tplId = await insertTemplate(db);
    await linkToTemplate(db, tplId, exId);
  });

  tearDown(() => db.close());

  Future<int> configure(StrategyId strategy, Map<String, Object?> params) =>
      progression.saveConfig(
        exerciseId: exId,
        strategy: strategy,
        params: params,
        incrementKg: 2.5,
        now: now,
      );

  /// Sessão finalizada com as séries (carga, reps, papel) e avaliada.
  Future<int> train(List<(double, int, SetRole?)> sets) async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    for (var i = 0; i < sets.length; i++) {
      final (kg, reps, role) = sets[i];
      await insertSet(
        db,
        seId,
        weightKg: kg,
        reps: reps,
        role: role,
        position: i,
      );
    }
    await service.evaluateFinishedSession(s);
    return s;
  }

  Future<List<ProgressionRecommendationEntry>> allRecs() =>
      db.select(db.progressionRecommendations).get();

  test('trocar a estratégia descarta a pendente da config anterior', () async {
    await configure(
      StrategyId.doubleProgression,
      const DoubleProgressionConfig().toJson(),
    );
    await train([(50, 12, null), (50, 12, null), (50, 12, null)]);
    final old = (await progression.pendingRecommendation(exId))!;

    await configure(StrategyId.linear, const {
      'sets': 3,
      'targetReps': 5,
    });

    expect(await progression.pendingRecommendation(exId), isNull);
    final kept = (await allRecs()).single;
    expect(kept.id, old.id);
    expect(kept.decision, RecommendationDecision.superseded);
    // Auditoria intacta: estratégia, config, metas e justificativa antigas.
    expect(
      (kept.strategy, kept.configId, kept.recommendedTargetsJson),
      (old.strategy, old.configId, old.recommendedTargetsJson),
    );
    expect(kept.explanation, old.explanation);
  });

  test('meta aceita da config anterior não vale para a nova', () async {
    await configure(
      StrategyId.doubleProgression,
      const DoubleProgressionConfig().toJson(),
    );
    await train([(50, 12, null), (50, 12, null), (50, 12, null)]);
    final rec = (await progression.pendingRecommendation(exId))!;
    await progression.decide(rec.id, RecommendationDecision.accepted, now: now);

    await configure(
      StrategyId.topSetBackOff,
      const TopSetBackOffConfig().toJson(),
    );
    final next = await sessions.startSession(tplId);
    final sets = await (db.select(db.sessionSets)).get();
    final planned = sets.where((s) => s.targetWeightKg != null);
    expect(planned, isEmpty, reason: 'sessão $next sem metas da config antiga');
  });

  test('ondas → principal + back-off: identifica pela carga, não trava', () async {
    await configure(StrategyId.waveLoading, const WaveLoadingConfig().toJson());
    // Última sessão feita como onda (papéis "wave", cargas diferentes).
    await train([
      (80, 5, SetRole.wave),
      (85, 3, SetRole.wave),
      (90, 1, SetRole.wave),
    ]);

    await configure(
      StrategyId.topSetBackOff,
      const TopSetBackOffConfig(
        topRepsMin: 1,
        topRepsMax: 3,
        backOffRepsMin: 3,
        backOffRepsMax: 5,
      ).toJson(),
    );
    await train([
      (80, 5, SetRole.wave),
      (85, 3, SetRole.wave),
      (90, 1, SetRole.wave),
    ]);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.reasonCode, isNot('topSetNotIdentified'));
    expect(rec.strategy, StrategyId.topSetBackOff);
    final targets = ProgressionRepository.decodeTargets(
      rec.recommendedTargetsJson,
    );
    expect(targets.first.role, SetRole.topSet);
  });

  test('principal + back-off → dupla: cargas diferentes pedem revisão', () async {
    await configure(
      StrategyId.topSetBackOff,
      const TopSetBackOffConfig().toJson(),
    );
    await train([
      (70, 6, SetRole.topSet),
      (60, 8, SetRole.backOff),
      (60, 8, SetRole.backOff),
    ]);

    await configure(
      StrategyId.doubleProgression,
      const DoubleProgressionConfig().toJson(),
    );
    await train([
      (70, 6, SetRole.topSet),
      (60, 8, SetRole.backOff),
      (60, 8, SetRole.backOff),
    ]);

    // Conservador: não escolhe sozinho uma carga de trabalho.
    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.status, RecommendationStatus.manualReview);
    expect(rec.reasonCode, 'mixedLoads');
  });

  test('dupla → ondas: o ciclo começa do zero', () async {
    await configure(
      StrategyId.doubleProgression,
      const DoubleProgressionConfig().toJson(),
    );
    await train([(60, 10, null), (60, 10, null), (60, 10, null)]);

    await configure(StrategyId.waveLoading, const WaveLoadingConfig().toJson());
    await train([(60, 10, null), (60, 10, null), (60, 10, null)]);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.reasonCode, 'cycleStart');
    expect(
      ProgressionRepository.decodeTargets(
        rec.recommendedTargetsJson,
      ).map((t) => t.weightKg),
      [60.0, 60.0, 60.0],
    );
  });

  test('ondas → ondas com outros parâmetros: estado não vaza', () async {
    final first = await configure(
      StrategyId.waveLoading,
      const WaveLoadingConfig().toJson(),
    );
    await train([(60, 10, null)]);
    final start = (await progression.pendingRecommendation(exId))!;
    expect(start.reasonCode, 'cycleStart');
    await train([
      (60, 8, SetRole.wave),
      (60, 8, SetRole.wave),
      (60, 8, SetRole.wave),
    ]);
    expect(
      (await progression.pendingRecommendation(exId))!.reasonCode,
      'waveCompleted',
    );

    final second = await configure(
      StrategyId.waveLoading,
      const WaveLoadingConfig(cycleIncrements: 2).toJson(),
    );
    expect(second, isNot(first));
    expect(await progression.latestState(exId, second), isEmpty);
    await train([
      (64, 6, SetRole.wave),
      (64, 6, SetRole.wave),
      (64, 6, SetRole.wave),
    ]);
    expect(
      (await progression.pendingRecommendation(exId))!.reasonCode,
      'cycleStart',
    );
  });

  test('desativar no meio do ciclo para de gerar sugestões', () async {
    await configure(StrategyId.waveLoading, const WaveLoadingConfig().toJson());
    await train([(60, 10, null)]);
    await progression.deactivate(exId, now);

    await train([(60, 8, SetRole.wave)]);
    expect(await progression.pendingRecommendation(exId), isNull);
    expect((await allRecs()).length, 1);
  });
}
