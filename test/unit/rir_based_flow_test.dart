import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/rir_based_progression.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Progressão por RIR com o registry real: captura, avaliação e correção.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  final now = DateTime(2026, 6, 10, 18);

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    service = ProgressionService(db, clock: () => now);
    exId = await insertExercise(db, name: 'Rosca Scott Teste');
    tplId = await insertTemplate(db);
    await progression.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.rirBased,
      params: const RirBasedConfig(repsMin: 8, repsMax: 10).toJson(),
      incrementKg: 2.5,
      now: DateTime(2026, 6, 1),
    );
  });

  tearDown(() => db.close());

  /// Sessão finalizada com 3 × [reps] em 30 kg e [rir] em cada série.
  Future<(int, List<SessionSet>)> workout(int reps, int? rir) async {
    final s = await insertSession(
      db,
      tplId,
      startedAt: now.subtract(const Duration(hours: 2)),
    );
    final seId = await insertSessionExercise(db, s, exId);
    for (var i = 0; i < 3; i++) {
      await insertSet(
        db,
        seId,
        weightKg: 30,
        reps: reps,
        rir: rir,
        position: i,
      );
    }
    final sets = await (db.select(
      db.sessionSets,
    )..where((x) => x.sessionExerciseId.equals(seId))).get();
    return (s, sets);
  }

  test('RIR registrado no alvo e topo da faixa → sugere subir', () async {
    final (s, _) = await workout(10, 2);
    await service.evaluateFinishedSession(s);

    final rec = await progression.pendingRecommendation(exId);
    expect(rec!.status, RecommendationStatus.increaseWeight);
    expect(
      ProgressionRepository.decodeTargets(rec.recommendedTargetsJson).first.rir,
      2,
    );
  });

  test(
    'sem RIR: dados insuficientes; corrigir e reavaliar gera nova sugestão',
    () async {
      final (s, sets) = await workout(10, null);
      await service.evaluateFinishedSession(s);
      final first = (await progression.pendingRecommendation(exId))!;
      expect(first.status, RecommendationStatus.insufficientData);

      // Correção manual do RIR depois do treino.
      for (final x in sets) {
        await sessions.updateSetDetails(x.id, rir: 2, rpe: null, quality: null);
      }
      await service.evaluateFinishedSession(s);

      final second = (await progression.pendingRecommendation(exId))!;
      expect(second.id, isNot(first.id));
      expect(second.status, RecommendationStatus.increaseWeight);
      final old = await (db.select(
        db.progressionRecommendations,
      )..where((r) => r.id.equals(first.id))).getSingle();
      expect(old.decision, RecommendationDecision.superseded);
    },
  );

  test('reavaliar não reescreve recomendação já decidida', () async {
    final (s, sets) = await workout(10, 0);
    await service.evaluateFinishedSession(s);
    final decided = (await progression.pendingRecommendation(exId))!;
    expect(decided.reasonCode, 'effortAboveTarget');
    await progression.decide(decided.id, RecommendationDecision.kept, now: now);

    for (final x in sets) {
      await sessions.updateSetDetails(x.id, rir: 2, rpe: null, quality: null);
    }
    await service.evaluateFinishedSession(s);

    final after = await (db.select(
      db.progressionRecommendations,
    )..where((r) => r.id.equals(decided.id))).getSingle();
    expect(after.decision, RecommendationDecision.kept);
    expect(after.reasonCode, 'effortAboveTarget');
    expect(after.explanation, decided.explanation);
  });

  test('falha técnica marcada na correção impede o aumento', () async {
    final (s, sets) = await workout(10, 2);
    await sessions.updateSetDetails(
      sets.last.id,
      rir: 2,
      rpe: null,
      quality: ExecutionQuality.technicalFailure,
    );
    await service.evaluateFinishedSession(s);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.reasonCode, 'invalidExecution');
  });
}
