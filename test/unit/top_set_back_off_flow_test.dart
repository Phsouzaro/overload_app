import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/strategies/top_set_back_off.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Série principal + back-off de ponta a ponta com o registry real.
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
    exId = await insertExercise(db, name: 'Remada Teste');
    tplId = await insertTemplate(db);
    await linkToTemplate(db, tplId, exId);
    await progression.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.topSetBackOff,
      params: const TopSetBackOffConfig(
        topRepsMin: 4,
        topRepsMax: 6,
        backOffSets: 3,
        backOffPercent: 15,
        backOffRepsMin: 8,
        backOffRepsMax: 10,
      ).toJson(),
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

  test('1ª sessão sem papéis: identifica a principal pela carga', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 70, reps: 6, position: 0);
    for (var i = 1; i <= 3; i++) {
      await insertSet(db, seId, weightKg: 60, reps: 9, position: i);
    }
    await service.evaluateFinishedSession(s);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.reasonCode, 'topSetUp');
    final targets = ProgressionRepository.decodeTargets(
      rec.recommendedTargetsJson,
    );
    expect(targets.map((t) => (t.role, t.weightKg)), [
      (SetRole.topSet, 72.5),
      (SetRole.backOff, 62.5),
      (SetRole.backOff, 62.5),
      (SetRole.backOff, 62.5),
    ]);
  });

  test('aceita: o treino seguinte nasce com a estrutura e as metas', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 70, reps: 6, position: 0);
    for (var i = 1; i <= 3; i++) {
      await insertSet(db, seId, weightKg: 60, reps: 9, position: i);
    }
    await service.evaluateFinishedSession(s);
    final rec = (await progression.pendingRecommendation(exId))!;
    await progression.decide(rec.id, RecommendationDecision.accepted, now: now);

    final next = await sessions.startSession(tplId);
    final sets = await setsOf(next);
    expect(sets.map((x) => (x.setRole, x.targetWeightKg, x.targetRepsMin)), [
      (SetRole.topSet, 72.5, 4),
      (SetRole.backOff, 62.5, 8),
      (SetRole.backOff, 62.5, 8),
      (SetRole.backOff, 62.5, 8),
    ]);
  });

  test(
    'com papéis gravados, a avaliação usa os papéis (não a carga)',
    () async {
      final s = await insertSession(db, tplId, startedAt: now);
      final seId = await insertSessionExercise(db, s, exId);
      // Back-off registrado antes da principal, e mais pesado que o esperado:
      // os papéis mandam.
      for (var i = 0; i < 3; i++) {
        await insertSet(
          db,
          seId,
          weightKg: 62.5,
          reps: 10,
          role: SetRole.backOff,
          position: i,
        );
      }
      await insertSet(
        db,
        seId,
        weightKg: 72.5,
        reps: 5,
        role: SetRole.topSet,
        position: 3,
      );
      await service.evaluateFinishedSession(s);

      final rec = (await progression.pendingRecommendation(exId))!;
      expect(rec.reasonCode, 'backOffUp');
    },
  );

  test('ajuste por papel preserva a estrutura e o esforço-alvo', () async {
    final s = await insertSession(db, tplId, startedAt: now);
    final seId = await insertSessionExercise(db, s, exId);
    await insertSet(db, seId, weightKg: 70, reps: 6, position: 0);
    for (var i = 1; i <= 3; i++) {
      await insertSet(db, seId, weightKg: 60, reps: 9, position: i);
    }
    await service.evaluateFinishedSession(s);
    final rec = (await progression.pendingRecommendation(exId))!;

    await progression.decide(
      rec.id,
      RecommendationDecision.adjusted,
      now: now,
      finalTargets: const [
        SetTarget(
          role: SetRole.topSet,
          weightKg: 71.25,
          repsMin: 4,
          repsMax: 6,
        ),
        SetTarget(role: SetRole.backOff, weightKg: 60, repsMin: 8, repsMax: 10),
        SetTarget(role: SetRole.backOff, weightKg: 60, repsMin: 8, repsMax: 10),
        SetTarget(role: SetRole.backOff, weightKg: 60, repsMin: 8, repsMax: 10),
      ],
    );
    final next = await sessions.startSession(tplId);
    final sets = await setsOf(next);
    expect(sets.first.setRole, SetRole.topSet);
    expect(sets.first.targetWeightKg, 71.25);
    expect(sets.skip(1).map((x) => x.targetWeightKg), everyElement(60.0));
  });
}
