import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/double_progression.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Fluxo completo da Progressão Dupla com o registry real do app.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  var clock = DateTime(2026, 4, 1, 18);

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    service = ProgressionService(db, clock: () => clock);
    exId = await insertExercise(db);
    tplId = await insertTemplate(db);
    await linkToTemplate(db, tplId, exId);
  });

  tearDown(() => db.close());

  Future<int> configure([
    DoubleProgressionConfig config = const DoubleProgressionConfig(),
  ]) => progression.saveConfig(
    exerciseId: exId,
    strategy: StrategyId.doubleProgression,
    params: config.toJson(),
    incrementKg: 2.5,
    now: DateTime(2026, 3, 1),
  );

  Future<List<SessionSet>> setsOf(int sessionId) async {
    final se = await (db.select(
      db.sessionExercises,
    )..where((s) => s.sessionId.equals(sessionId))).getSingle();
    return (db.select(db.sessionSets)
          ..where((s) => s.sessionExerciseId.equals(se.id))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  /// Registra [reps] em [kg] nas séries pré-criadas (criando as que faltarem)
  /// e encerra a sessão, como o usuário faria na tela.
  Future<void> logAndFinish(
    int sessionId,
    double kg,
    List<int> reps, {
    ExecutionQuality? quality,
  }) async {
    var sets = await setsOf(sessionId);
    final seId = sets.isEmpty
        ? (await (db.select(
            db.sessionExercises,
          )..where((s) => s.sessionId.equals(sessionId))).getSingle()).id
        : sets.first.sessionExerciseId;
    while (sets.length < reps.length) {
      await sessions.addSet(seId, SetType.weight);
      sets = await setsOf(sessionId);
    }
    for (var i = 0; i < reps.length; i++) {
      await sessions.updateSet(sets[i].id, weightKg: kg, reps: reps[i]);
      if (quality != null) {
        await sessions.updateSetDetails(
          sets[i].id,
          rir: null,
          rpe: null,
          quality: quality,
        );
      }
    }
    await sessions.finishSession(sessionId);
  }

  test('config salva é lida de volta com os mesmos parâmetros', () async {
    const config = DoubleProgressionConfig(
      sets: 4,
      repsMin: 6,
      repsMax: 10,
      targetRir: 2,
    );
    await configure(config);

    final entry = await progression.activeConfig(exId);
    final parsed = const DoubleProgressionStrategy().configFromJson(
      _decode(entry!),
    );
    expect(parsed.toJson(), config.toJson());
  });

  test(
    'ciclo completo: faixa → topo → aceita → nova carga na próxima sessão',
    () async {
      await configure();

      // Sessão 1: 10/9/8 com 50 kg → buscar mais repetições
      var s = await sessions.startSession(tplId);
      await logAndFinish(s, 50, [10, 9, 8]);
      var recId = (await service.evaluateFinishedSession(s)).single;
      var rec = await progression.pendingRecommendation(exId);
      expect(rec!.status, RecommendationStatus.increaseReps);
      await progression.decide(
        recId,
        RecommendationDecision.accepted,
        now: clock,
      );

      // Sessão 2: metas aceitas = 50 kg, base da faixa
      clock = clock.add(const Duration(days: 2));
      s = await sessions.startSession(tplId);
      var planned = await setsOf(s);
      expect(
        planned.map((x) => (x.targetWeightKg, x.targetRepsMin)),
        everyElement((50.0, 8)),
      );
      await logAndFinish(s, 50, [12, 12, 12]);
      recId = (await service.evaluateFinishedSession(s)).single;
      rec = await progression.pendingRecommendation(exId);
      expect(rec!.status, RecommendationStatus.increaseWeight);
      expect(rec.explanation, contains('52,5 kg'));

      // Usuário aceita → sessão 3 já nasce com 52,5 kg × 8–12
      await progression.decide(
        recId,
        RecommendationDecision.accepted,
        now: clock,
      );
      clock = clock.add(const Duration(days: 2));
      s = await sessions.startSession(tplId);
      planned = await setsOf(s);
      expect(planned, hasLength(3));
      expect(
        planned.map(
          (x) => (x.targetWeightKg, x.targetRepsMin, x.targetRepsMax),
        ),
        everyElement((52.5, 8, 12)),
      );
    },
  );

  test('"manter carga atual" não muda nada na próxima sessão', () async {
    await configure();
    var s = await sessions.startSession(tplId);
    await logAndFinish(s, 50, [12, 12, 12]);
    final recId = (await service.evaluateFinishedSession(s)).single;
    await progression.decide(recId, RecommendationDecision.kept, now: clock);

    s = await sessions.startSession(tplId);
    final sets = await setsOf(s);
    expect(sets.every((x) => x.targetWeightKg == null), isTrue);
  });

  test(
    'sem decisão, a próxima sessão não muda (nunca silenciosamente)',
    () async {
      await configure();
      var s = await sessions.startSession(tplId);
      await logAndFinish(s, 50, [12, 12, 12]);
      await service.evaluateFinishedSession(s);

      s = await sessions.startSession(tplId);
      expect((await setsOf(s)).every((x) => x.targetWeightKg == null), isTrue);
      expect((await progression.pendingRecommendation(exId)), isNotNull);
    },
  );

  test('falha técnica registrada na série impede o aumento', () async {
    await configure();
    final s = await sessions.startSession(tplId);
    await logAndFinish(s, 50, [
      12,
      12,
      12,
    ], quality: ExecutionQuality.technicalFailure);
    await service.evaluateFinishedSession(s);

    final rec = await progression.pendingRecommendation(exId);
    expect(rec!.status, RecommendationStatus.maintain);
    expect(rec.reasonCode, 'invalidExecution');
  });

  test('RIR corrigido depois de confirmar a série é o que vale', () async {
    await configure(const DoubleProgressionConfig(targetRir: 2));
    final s = await sessions.startSession(tplId);
    await logAndFinish(s, 50, [12, 12, 12]);
    final sets = await setsOf(s);
    for (final x in sets) {
      await sessions.updateSetDetails(x.id, rir: 0, rpe: null, quality: null);
      await sessions.updateSetDetails(x.id, rir: 3, rpe: null, quality: null); // correção
    }
    await service.evaluateFinishedSession(s);

    expect(
      (await progression.pendingRecommendation(exId))!.status,
      RecommendationStatus.increaseWeight,
    );
  });

  test('justificativa respeita a unidade do usuário', () async {
    await configure();
    final inLbs = ProgressionService(
      db,
      clock: () => clock,
      formatLoad: (kg) => '${(kg / 0.45359237).toStringAsFixed(0)} lbs',
    );
    final s = await sessions.startSession(tplId);
    await logAndFinish(s, 50, [12, 12, 12]);
    await inLbs.evaluateFinishedSession(s);

    final rec = await progression.pendingRecommendation(exId);
    expect(rec!.explanation, contains('110 lbs'));
    expect(rec.explanation, isNot(contains(' kg')));
  });
}

Map<String, Object?> _decode(ProgressionConfigEntry entry) =>
    (jsonDecode(entry.paramsJson) as Map).cast<String, Object?>();
