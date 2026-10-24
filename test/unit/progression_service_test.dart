import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_registry.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

void main() {
  late AppDatabase db;
  late ProgressionRepository repo;
  late FakeStrategy strategy;
  late ProgressionService service;
  late int exId;
  late int tplId;
  final now = DateTime(2026, 2, 1, 18);

  ProgressionService serviceWith(FakeStrategy s) => ProgressionService(
    db,
    registry: ProgressionRegistry([s]),
    clock: () => now,
  );

  Future<int> configure({
    Map<String, Object?> params = const {'sets': 3, 'nextWeightKg': 52.5},
    int? exerciseId,
    DateTime? baselineFrom,
  }) => repo.saveConfig(
    exerciseId: exerciseId ?? exId,
    strategy: StrategyId.doubleProgression,
    params: params,
    incrementKg: 2.5,
    now: DateTime(2026, 1, 1),
    baselineFrom: baselineFrom,
  );

  Future<List<ProgressionRecommendationEntry>> allRecs() =>
      db.select(db.progressionRecommendations).get();

  setUp(() async {
    db = await openTestDb();
    repo = ProgressionRepository(db);
    strategy = FakeStrategy();
    service = serviceWith(strategy);
    exId = await insertExercise(db);
    tplId = await insertTemplate(db);
  });

  tearDown(() => db.close());

  group('sem estratégia ativa (comportamento atual preservado)', () {
    test('exercício sem config não gera recomendação', () async {
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      expect(await service.evaluateFinishedSession(s), isEmpty);
      expect(await allRecs(), isEmpty);
      expect(strategy.inputs, isEmpty);
    });

    test(
      'registro padrão do app (sem estratégias nesta etapa) não grava nada',
      () async {
        await configure();
        final s = await insertWorkout(
          db,
          templateId: tplId,
          exerciseId: exId,
          date: now,
        );

        final standard = ProgressionService(db, clock: () => now);
        expect(await standard.evaluateFinishedSession(s), isEmpty);
        expect(await allRecs(), isEmpty);
      },
    );

    test('sessão não finalizada não é avaliada', () async {
      await configure();
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
        finished: false,
      );
      expect(await service.evaluateFinishedSession(s), isEmpty);
    });

    test('exercício por tempo fica fora da progressão', () async {
      final prancha = await insertExercise(
        db,
        name: 'Prancha',
        setType: SetType.time,
      );
      await configure(exerciseId: prancha);
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: prancha,
        date: now,
      );

      expect(await service.evaluateFinishedSession(s), isEmpty);
    });

    test(
      'exercício marcado para não avaliar nesta sessão é ignorado',
      () async {
        await configure();
        final s = await insertWorkout(
          db,
          templateId: tplId,
          exerciseId: exId,
          date: now,
          excluded: true,
        );
        expect(await service.evaluateFinishedSession(s), isEmpty);
      },
    );
  });

  group('com estratégia ativa', () {
    test(
      'grava recomendação pendente com config, sessão e resultado',
      () async {
        final configId = await configure();
        final s = await insertWorkout(
          db,
          templateId: tplId,
          exerciseId: exId,
          date: now,
          weightKg: 50,
        );

        final ids = await service.evaluateFinishedSession(s);

        final r = (await allRecs()).single;
        expect(ids, [r.id]);
        expect(r.decision, RecommendationDecision.pending);
        expect(r.configId, configId);
        expect(r.sourceSessionId, s);
        expect(r.generatedAt, now);
        expect(r.status, RecommendationStatus.increaseWeight);
        expect(r.currentWeightKg, 50);
      },
    );

    test('entrega à estratégia contexto, histórico e data corretos', () async {
      await configure();
      final older = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now.subtract(const Duration(days: 3)),
      );
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );

      await service.evaluateFinishedSession(s);

      final input = strategy.inputs.single;
      expect(input.now, now);
      expect(input.exercise.exerciseId, exId);
      expect(input.exercise.incrementKg, 2.5);
      expect(input.exercise.loadType, ExerciseLoadType.weighted);
      expect(input.history.map((h) => h.sessionId), [s, older]);
      expect(input.config.nextWeightKg, 52.5);
    });

    test('peso corporal é informado como tal à estratégia', () async {
      final barra = await insertExercise(
        db,
        name: 'Barra fixa',
        setType: SetType.bodyweight,
      );
      await configure(exerciseId: barra);
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: barra,
        date: now,
        weightKg: 10,
      );

      await service.evaluateFinishedSession(s);
      expect(
        strategy.inputs.single.exercise.loadType,
        ExerciseLoadType.bodyweight,
      );
    });

    test('respeita a "nova referência" da config', () async {
      await configure(baselineFrom: now.subtract(const Duration(days: 1)));
      await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now.subtract(const Duration(days: 10)),
      );
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );

      await service.evaluateFinishedSession(s);
      expect(strategy.inputs.single.history.map((h) => h.sessionId), [s]);
    });

    test('passa o estado da recomendação anterior da mesma config', () async {
      await configure();
      final s1 = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now.subtract(const Duration(days: 2)),
      );
      await service.evaluateFinishedSession(s1);
      final s2 = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      await service.evaluateFinishedSession(s2);

      expect(strategy.inputs.map((i) => i.previousState['count']), [null, 1]);
    });

    test(
      'config inválida gera "revisão manual" sem chamar a estratégia',
      () async {
        await configure(params: const {'sets': 0, 'nextWeightKg': 50});
        final s = await insertWorkout(
          db,
          templateId: tplId,
          exerciseId: exId,
          date: now,
        );

        await service.evaluateFinishedSession(s);

        final r = (await allRecs()).single;
        expect(r.status, RecommendationStatus.manualReview);
        expect(r.reasonCode, 'invalidConfig');
        expect(strategy.inputs, isEmpty);
      },
    );

    test('erro na estratégia não interrompe nem grava recomendação', () async {
      await configure();
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );

      final failing = serviceWith(FakeStrategy(throwOnEvaluate: true));
      expect(await failing.evaluateFinishedSession(s), isEmpty);
      expect(await allRecs(), isEmpty);
    });

    test('exercício repetido na sessão é avaliado uma vez', () async {
      await configure();
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      final seId = await insertSessionExercise(db, s, exId);
      await insertSet(db, seId, weightKg: 40, reps: 12);

      expect(await service.evaluateFinishedSession(s), hasLength(1));
    });

    test('mesma entrada gera o mesmo resultado (determinístico)', () async {
      await configure();
      final s = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      await service.evaluateFinishedSession(s);
      await service.evaluateFinishedSession(s);

      final recs = await allRecs();
      expect(recs[0].recommendedTargetsJson, recs[1].recommendedTargetsJson);
      expect(recs[0].analyzedSessionIdsJson, recs[1].analyzedSessionIdsJson);
    });
  });

  group('início da sessão (sem alterações não autorizadas)', () {
    late SessionRepository sessions;

    setUp(() async {
      sessions = SessionRepository(db);
      await linkToTemplate(db, tplId, exId);
    });

    Future<SessionExercise> sessionExercise(int sessionId) => (db.select(
      db.sessionExercises,
    )..where((se) => se.sessionId.equals(sessionId))).getSingle();

    Future<List<SessionSet>> setsOf(int seId) =>
        (db.select(db.sessionSets)
              ..where((s) => s.sessionExerciseId.equals(seId))
              ..orderBy([(s) => OrderingTerm.asc(s.position)]))
            .get();

    test('guarda a config vigente em cada exercício da sessão', () async {
      final configId = await configure();
      final s = await sessions.startSession(tplId);
      expect((await sessionExercise(s)).progressionConfigId, configId);
    });

    test('sem config: nada muda no início da sessão', () async {
      await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
        reps: const [10, 9],
      );
      final s = await sessions.startSession(tplId);

      final se = await sessionExercise(s);
      expect(se.progressionConfigId, isNull);
      expect(se.recommendationId, isNull);
      final sets = await setsOf(se.id);
      expect(sets, hasLength(2)); // pré-criação de sempre
      expect(sets.every((x) => x.targetWeightKg == null), isTrue);
    });

    test('recomendação pendente (não decidida) não muda as metas', () async {
      await configure();
      final done = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      await service.evaluateFinishedSession(done);

      final s = await sessions.startSession(tplId);
      final se = await sessionExercise(s);
      expect(se.recommendationId, isNull);
      expect(
        (await setsOf(se.id)).every((x) => x.targetWeightKg == null),
        isTrue,
      );
    });

    test('recomendação aceita vira meta das séries, uma única vez', () async {
      await configure();
      final done = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      final recId = (await service.evaluateFinishedSession(done)).single;
      await repo.decide(recId, RecommendationDecision.accepted, now: now);

      final s = await sessions.startSession(tplId);
      final se = await sessionExercise(s);
      final sets = await setsOf(se.id);
      expect(se.recommendationId, recId);
      expect(sets, hasLength(3));
      expect(
        sets.map((x) => (x.targetWeightKg, x.targetRepsMin, x.targetRepsMax)),
        everyElement((52.5, 8, 12)),
      );
      // Meta não é valor registrado: o usuário ainda confirma cada série.
      expect(sets.every((x) => x.weightKg == null && x.reps == null), isTrue);

      await sessions.finishSession(s);
      final next = await sessions.startSession(tplId);
      expect((await sessionExercise(next)).recommendationId, isNull);
    });

    test('sessão descartada libera as metas aceitas para a próxima', () async {
      await configure();
      final done = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: now,
      );
      final recId = (await service.evaluateFinishedSession(done)).single;
      await repo.decide(recId, RecommendationDecision.accepted, now: now);

      final discarded = await sessions.startSession(tplId);
      await sessions.discardSession(discarded);

      final s = await sessions.startSession(tplId);
      expect((await sessionExercise(s)).recommendationId, recId);
    });
  });
}
