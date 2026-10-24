import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';

import '../helpers/progression_fixtures.dart';

void main() {
  late AppDatabase db;
  late ProgressionRepository repo;
  late int exId;
  late int tplId;
  final t0 = DateTime(2026, 1, 10);

  setUp(() async {
    db = await openTestDb();
    repo = ProgressionRepository(db);
    exId = await insertExercise(db);
    tplId = await insertTemplate(db);
  });

  tearDown(() => db.close());

  Future<int> save({double increment = 2.5, DateTime? at, DateTime? since}) =>
      repo.saveConfig(
        exerciseId: exId,
        strategy: StrategyId.doubleProgression,
        params: const {'sets': 3},
        incrementKg: increment,
        now: at ?? t0,
        baselineFrom: since,
      );

  Future<int> recommend(int configId, int sessionId) =>
      repo.insertRecommendation(
        exerciseId: exId,
        configId: configId,
        strategy: StrategyId.doubleProgression,
        sourceSessionId: sessionId,
        generatedAt: t0,
        result: const ProgressionResult(
          status: RecommendationStatus.increaseWeight,
          reasonCode: 'r',
          explanation: 'e',
          nextTargets: [SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12)],
        ),
      );

  Future<ProgressionRecommendationEntry> rec(int id) => (db.select(
    db.progressionRecommendations,
  )..where((r) => r.id.equals(id))).getSingle();

  group('configurações versionadas', () {
    test('sem config, o exercício fica em registro manual', () async {
      expect(await repo.activeConfig(exId), isNull);
    });

    test('salvar grava os parâmetros e vira a config ativa', () async {
      final id = await save();
      final active = await repo.activeConfig(exId);
      expect(active!.id, id);
      expect(active.strategy, StrategyId.doubleProgression);
      expect(jsonDecode(active.paramsJson), {'sets': 3});
      expect(active.incrementKg, 2.5);
    });

    test(
      'editar cria nova versão e encerra a anterior sem alterá-la',
      () async {
        final v1 = await save(increment: 2.5);
        final v2 = await save(
          increment: 1.25,
          at: t0.add(const Duration(days: 3)),
        );

        expect((await repo.activeConfig(exId))!.id, v2);
        final old = await repo.configById(v1);
        expect(old!.incrementKg, 2.5); // conteúdo preservado
        expect(old.supersededAt, t0.add(const Duration(days: 3)));
      },
    );

    test(
      'desativar volta para registro manual e preserva o histórico',
      () async {
        final v1 = await save();
        final sessionId = await insertWorkout(
          db,
          templateId: tplId,
          exerciseId: exId,
          date: t0,
        );
        final recId = await recommend(v1, sessionId);

        await repo.deactivate(exId, t0);

        expect(await repo.activeConfig(exId), isNull);
        expect(await repo.configById(v1), isNotNull);
        expect((await rec(recId)).decision, RecommendationDecision.superseded);
      },
    );
  });

  group('recomendações', () {
    late int configId;
    late int sessionId;

    setUp(() async {
      configId = await save();
      sessionId = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0,
      );
    });

    test('nasce pendente com todos os campos de auditoria', () async {
      final id = await repo.insertRecommendation(
        exerciseId: exId,
        configId: configId,
        strategy: StrategyId.doubleProgression,
        sourceSessionId: sessionId,
        generatedAt: t0,
        result: const ProgressionResult(
          status: RecommendationStatus.increaseWeight,
          reasonCode: 'topOfRange',
          explanation: 'Todas as séries no topo da faixa',
          currentWeightKg: 50,
          analyzedSessionIds: [7, 6],
          met: [Criterion('allSetsAtTop', 'todas no topo')],
          unmet: [Criterion('rir', 'RIR não informado')],
          nextTargets: [SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12)],
          state: {'streak': 2},
        ),
      );

      final r = await rec(id);
      expect(r.decision, RecommendationDecision.pending);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.reasonCode, 'topOfRange');
      expect(r.configId, configId);
      expect(r.sourceSessionId, sessionId);
      expect(r.currentWeightKg, 50);
      expect(jsonDecode(r.analyzedSessionIdsJson), [7, 6]);
      expect(
        ProgressionRepository.decodeCriteria(r.criteriaMetJson).single.code,
        'allSetsAtTop',
      );
      expect(ProgressionRepository.decodeTargets(r.recommendedTargetsJson), [
        const SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12),
      ]);
      expect(jsonDecode(r.strategyStateJson), {'streak': 2});
    });

    test('nova recomendação substitui a pendente anterior', () async {
      final first = await recommend(configId, sessionId);
      final second = await recommend(configId, sessionId);

      expect((await rec(first)).decision, RecommendationDecision.superseded);
      expect((await rec(second)).decision, RecommendationDecision.pending);
      expect((await repo.pendingRecommendation(exId))!.id, second);
    });

    test('nova recomendação não altera as já decididas', () async {
      final first = await recommend(configId, sessionId);
      await repo.decide(first, RecommendationDecision.kept, now: t0);
      await recommend(configId, sessionId);

      expect((await rec(first)).decision, RecommendationDecision.kept);
    });

    for (final decision in [
      RecommendationDecision.accepted,
      RecommendationDecision.kept,
      RecommendationDecision.dismissed,
    ]) {
      test(
        'decidir "$decision" registra a data e não guarda metas finais',
        () async {
          final id = await recommend(configId, sessionId);
          final ok = await repo.decide(id, decision, now: t0);

          final r = await rec(id);
          expect(ok, isTrue);
          expect(r.decision, decision);
          expect(r.decidedAt, t0);
          expect(r.finalTargetsJson, isNull);
        },
      );
    }

    test('ajustar guarda as metas finais escolhidas pelo usuário', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(
        id,
        RecommendationDecision.adjusted,
        now: t0,
        finalTargets: const [SetTarget(weightKg: 51.25)],
      );

      final r = await rec(id);
      expect(ProgressionRepository.decodeTargets(r.finalTargetsJson!), [
        const SetTarget(weightKg: 51.25),
      ]);
    });

    test('ajustar sem metas finais é recusado', () async {
      final id = await recommend(configId, sessionId);
      expect(
        () => repo.decide(id, RecommendationDecision.adjusted, now: t0),
        throwsArgumentError,
      );
    });

    test('"pendente" e "substituída" não são decisões válidas', () async {
      final id = await recommend(configId, sessionId);
      for (final d in [
        RecommendationDecision.pending,
        RecommendationDecision.superseded,
      ]) {
        expect(() => repo.decide(id, d, now: t0), throwsArgumentError);
      }
    });

    test('recomendação já decidida não muda de novo', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(id, RecommendationDecision.kept, now: t0);

      final changed = await repo.decide(
        id,
        RecommendationDecision.accepted,
        now: t0,
      );
      expect(changed, isFalse);
      expect((await rec(id)).decision, RecommendationDecision.kept);
    });
  });

  group('targetsToApply', () {
    late int configId;
    late int sessionId;

    setUp(() async {
      configId = await save();
      sessionId = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0,
      );
    });

    test('pendente não aplica nada (sem ação do usuário)', () async {
      await recommend(configId, sessionId);
      expect(await repo.targetsToApply(exId, configId), isNull);
    });

    test('"manter carga" e "ignorar" não aplicam nada', () async {
      for (final d in [
        RecommendationDecision.kept,
        RecommendationDecision.dismissed,
      ]) {
        final id = await recommend(configId, sessionId);
        await repo.decide(id, d, now: t0);
        expect(await repo.targetsToApply(exId, configId), isNull);
      }
    });

    test('aceita: aplica as metas recomendadas', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(id, RecommendationDecision.accepted, now: t0);

      final planned = await repo.targetsToApply(exId, configId);
      expect(planned!.recommendationId, id);
      expect(planned.targets.single.weightKg, 52.5);
    });

    test('ajustada: aplica as metas finais, não as recomendadas', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(
        id,
        RecommendationDecision.adjusted,
        now: t0,
        finalTargets: const [SetTarget(weightKg: 51.25)],
      );

      final planned = await repo.targetsToApply(exId, configId);
      expect(planned!.targets.single.weightKg, 51.25);
    });

    test('aceita de uma config antiga não vale para a config nova', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(id, RecommendationDecision.accepted, now: t0);
      final v2 = await save(increment: 1.25);

      expect(await repo.targetsToApply(exId, v2), isNull);
    });

    test('metas já usadas em uma sessão não são aplicadas de novo', () async {
      final id = await recommend(configId, sessionId);
      await repo.decide(id, RecommendationDecision.accepted, now: t0);
      final next = await insertSession(
        db,
        tplId,
        startedAt: t0.add(const Duration(days: 2)),
        finished: false,
      );
      final seId = await insertSessionExercise(db, next, exId);
      await (db.update(db.sessionExercises)..where((se) => se.id.equals(seId)))
          .write(SessionExercisesCompanion(recommendationId: Value(id)));

      expect(await repo.targetsToApply(exId, configId), isNull);
    });
  });

  group('loadHistory', () {
    test('só sessões finalizadas, mais recente primeiro', () async {
      final older = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0,
      );
      final newer = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0.add(const Duration(days: 3)),
      );
      await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0.add(const Duration(days: 5)),
        finished: false,
      ); // interrompida

      final history = await repo.loadHistory(exId);
      expect(history.map((h) => h.sessionId), [newer, older]);
    });

    test('ignora sessões marcadas para não avaliar', () async {
      final kept = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0,
      );
      await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0.add(const Duration(days: 2)),
        excluded: true,
      ); // deload

      expect((await repo.loadHistory(exId)).map((h) => h.sessionId), [kept]);
    });

    test('"nova referência" descarta o que veio antes', () async {
      await insertWorkout(db, templateId: tplId, exerciseId: exId, date: t0);
      final after = await insertWorkout(
        db,
        templateId: tplId,
        exerciseId: exId,
        date: t0.add(const Duration(days: 10)),
      );

      final history = await repo.loadHistory(
        exId,
        since: t0.add(const Duration(days: 5)),
      );
      expect(history.map((h) => h.sessionId), [after]);
    });

    test('sessão só com séries vazias não entra', () async {
      final s = await insertSession(db, tplId, startedAt: t0);
      final seId = await insertSessionExercise(db, s, exId);
      await insertSet(db, seId); // vazia

      expect(await repo.loadHistory(exId), isEmpty);
    });

    test('traz RIR, RPE, qualidade, papel e config da sessão', () async {
      final configId = await save();
      final s = await insertSession(db, tplId, startedAt: t0);
      final seId = await insertSessionExercise(db, s, exId, configId: configId);
      await insertSet(db, seId, weightKg: 20, reps: 10, isWarmup: true);
      await insertSet(
        db,
        seId,
        weightKg: 70,
        reps: 6,
        rir: 1,
        rpe: 9,
        quality: ExecutionQuality.valid,
        role: SetRole.topSet,
        position: 1,
      );
      await insertSet(
        db,
        seId,
        weightKg: 60,
        reps: 9,
        quality: ExecutionQuality.technicalFailure,
        role: SetRole.backOff,
        position: 2,
      );

      final record = (await repo.loadHistory(exId)).single;
      expect(record.configId, configId);
      expect(record.sets, hasLength(3));
      expect(record.sets[0].isWarmup, isTrue);
      final top = record.sets[1];
      expect(
        (top.weightKg, top.reps, top.rir, top.rpe, top.quality, top.role),
        (70.0, 6, 1, 9.0, ExecutionQuality.valid, SetRole.topSet),
      );
      expect(record.sets[2].quality, ExecutionQuality.technicalFailure);
    });

    test(
      'histórico antigo sem os campos novos vira "não registrado"',
      () async {
        await insertWorkout(db, templateId: tplId, exerciseId: exId, date: t0);
        final set = (await repo.loadHistory(exId)).single.sets.first;
        expect(
          (set.rir, set.rpe, set.quality, set.role),
          (null, null, null, null),
        );
      },
    );
  });
}
