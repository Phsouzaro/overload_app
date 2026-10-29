import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/strategies/wave_loading.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Progressão em ondas de ponta a ponta com o registry real: o estado do
/// ciclo passa de uma recomendação para a seguinte pelo banco.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  final now = DateTime(2026, 8, 1, 18);

  const config = WaveLoadingConfig(
    waves: [
      [
        WaveStep(reps: 8, percent: 75),
        WaveStep(reps: 8, percent: 75),
      ],
      [
        WaveStep(reps: 5, percent: 80),
        WaveStep(reps: 3, percent: 85),
        WaveStep(reps: 1, percent: 90),
      ],
    ],
  );

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    service = ProgressionService(db, clock: () => now);
    exId = await insertExercise(db, name: 'Agachamento Teste');
    tplId = await insertTemplate(db);
    await linkToTemplate(db, tplId, exId);
    await progression.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.waveLoading,
      params: config.toJson(),
      incrementKg: 2.5,
      now: DateTime(2026, 7, 1),
    );
  });

  tearDown(() => db.close());

  Future<List<SessionSet>> setsOf(int sessionId) async {
    final se = await (db.select(
      db.sessionExercises,
    )..where((s) => s.sessionId.equals(sessionId))).getSingle();
    return (db.select(db.sessionSets)
          ..where((s) => s.sessionExerciseId.equals(se.id))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  /// Aceita a sugestão pendente, inicia o treino seguinte, preenche cada
  /// série com a meta (ou com [reps]) e finaliza.
  Future<List<SessionSet>> acceptAndTrain({List<int>? reps}) async {
    final rec = (await progression.pendingRecommendation(exId))!;
    await progression.decide(rec.id, RecommendationDecision.accepted, now: now);
    final s = await sessions.startSession(tplId);
    final sets = await setsOf(s);
    for (var i = 0; i < sets.length; i++) {
      await sessions.updateSet(
        sets[i].id,
        weightKg: sets[i].targetWeightKg,
        reps: reps?[i] ?? sets[i].targetRepsMin,
      );
    }
    await sessions.finishSession(s);
    await service.evaluateFinishedSession(s);
    return sets;
  }

  Future<ProgressionRecommendationEntry> pending() async =>
      (await progression.pendingRecommendation(exId))!;

  test('ciclo inteiro: começa, avança, fecha e sobe a referência', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    for (var i = 0; i < 3; i++) {
      await insertSet(db, seId, weightKg: 60, reps: 10, position: i);
    }
    await service.evaluateFinishedSession(s);
    expect((await pending()).reasonCode, 'cycleStart');

    // Onda 1, montada a partir das metas aceitas.
    final wave1 = await acceptAndTrain();
    expect(wave1.map((x) => (x.setRole, x.targetWeightKg, x.targetRepsMin)), [
      (SetRole.wave, 60.0, 8),
      (SetRole.wave, 60.0, 8),
    ]);
    expect((await pending()).reasonCode, 'waveCompleted');

    // Onda 2: estrutura diferente (3 séries, cargas subindo).
    final wave2 = await acceptAndTrain();
    expect(wave2.map((x) => (x.targetWeightKg, x.targetRepsMin)), [
      (65.0, 5),
      (67.5, 3),
      (72.5, 1),
    ]);
    final closed = await pending();
    expect(closed.reasonCode, 'cycleCompleted');

    final state = WaveState.fromJson(
      await progression.latestState(exId, closed.configId),
    )!;
    expect((state.cycle, state.wave, state.baseKg), (2, 0, 82.5));
    expect(state.results.map((r) => r['outcome']), [
      'completed',
      'completed',
    ]);
  });

  test('reavaliar a mesma sessão não avança o ciclo duas vezes', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 60, reps: 10);
    await service.evaluateFinishedSession(s);
    await acceptAndTrain();
    final first = await pending();
    expect(first.reasonCode, 'waveCompleted');

    // "Reavaliar" depois de corrigir uma série: mesma sessão de origem.
    await service.evaluateFinishedSession(first.sourceSessionId);
    final again = await pending();
    expect(again.id, isNot(first.id));
    expect(again.reasonCode, 'waveCompleted');
    expect(again.recommendedTargetsJson, first.recommendedTargetsJson);
    final state = WaveState.fromJson(
      await progression.latestState(exId, again.configId),
    )!;
    expect((state.wave, state.results.length), (1, 1));
  });

  test('onda malsucedida é repetida com as mesmas metas', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 60, reps: 10);
    await service.evaluateFinishedSession(s);

    await acceptAndTrain(reps: [8, 6]);
    final rec = await pending();
    expect(rec.reasonCode, 'waveFailed');
    expect(
      ProgressionRepository.decodeTargets(
        rec.recommendedTargetsJson,
      ).map((t) => (t.weightKg, t.repsMin)),
      [(60.0, 8), (60.0, 8)],
    );
  });

  test('nova versão da config recomeça o ciclo', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 60, reps: 10);
    await service.evaluateFinishedSession(s);
    await acceptAndTrain();
    expect((await pending()).reasonCode, 'waveCompleted');

    await progression.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.waveLoading,
      params: config.copyWith(baseKg: () => 100).toJson(),
      incrementKg: 2.5,
      now: now,
    );
    final s2 = await insertSession(db, tplId, startedAt: now);
    final se2 = await insertSessionExercise(db, s2, exId);
    await insertSet(db, se2, weightKg: 75, reps: 8, role: SetRole.wave);
    await service.evaluateFinishedSession(s2);

    final rec = await pending();
    expect(rec.reasonCode, 'cycleStart');
    expect(
      ProgressionRepository.decodeTargets(
        rec.recommendedTargetsJson,
      ).map((t) => t.weightKg),
      [75.0, 75.0],
    );
  });

  test('ajuste manual mantém a ordem e as cargas de cada série', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 60, reps: 10);
    await service.evaluateFinishedSession(s);
    await acceptAndTrain();
    final rec = await pending();

    await progression.decide(
      rec.id,
      RecommendationDecision.adjusted,
      now: now,
      finalTargets: const [
        SetTarget(role: SetRole.wave, weightKg: 62.5, repsMin: 5, repsMax: 5),
        SetTarget(role: SetRole.wave, weightKg: 67.5, repsMin: 3, repsMax: 3),
        SetTarget(role: SetRole.wave, weightKg: 70, repsMin: 1, repsMax: 1),
      ],
    );
    final next = await sessions.startSession(tplId);
    final sets = await setsOf(next);
    expect(sets.map((x) => (x.setRole, x.targetWeightKg)), [
      (SetRole.wave, 62.5),
      (SetRole.wave, 67.5),
      (SetRole.wave, 70.0),
    ]);
  });
}
