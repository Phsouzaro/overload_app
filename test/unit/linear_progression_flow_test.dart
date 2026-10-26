import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/linear_progression.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Fluxo completo da Progressão Linear com o registry real do app.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  var clock = DateTime(2026, 5, 1, 18);

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    clock = DateTime(2026, 5, 1, 18);
    service = ProgressionService(db, clock: () => clock);
    exId = await insertExercise(db, name: 'Agachamento Teste');
    tplId = await insertTemplate(db);
    await linkToTemplate(db, tplId, exId);
  });

  tearDown(() => db.close());

  Future<void> configure(LinearProgressionConfig config) =>
      progression.saveConfig(
        exerciseId: exId,
        strategy: StrategyId.linear,
        params: config.toJson(),
        incrementKg: 2.5,
        now: DateTime(2026, 4, 1),
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

  /// Uma sessão real: inicia, registra [reps] em [kg], encerra e avalia.
  Future<ProgressionRecommendationEntry> train(
    double kg,
    List<int> reps,
  ) async {
    clock = clock.add(const Duration(days: 2));
    final s = await sessions.startSession(tplId);
    var sets = await setsOf(s);
    final seId = (await (db.select(
      db.sessionExercises,
    )..where((x) => x.sessionId.equals(s))).getSingle()).id;
    while (sets.length < reps.length) {
      await sessions.addSet(seId, SetType.weight);
      sets = await setsOf(s);
    }
    for (var i = 0; i < reps.length; i++) {
      await sessions.updateSet(sets[i].id, weightKg: kg, reps: reps[i]);
    }
    await sessions.finishSession(s);
    await service.evaluateFinishedSession(s);
    return (await progression.pendingRecommendation(exId))!;
  }

  test('3 falhas seguidas → sugere redução, aplicada só se aceita', () async {
    await configure(const LinearProgressionConfig(targetReps: 5));

    var rec = await train(100, [5, 5, 5]);
    expect(rec.status, RecommendationStatus.increaseWeight);
    await progression.decide(
      rec.id,
      RecommendationDecision.accepted,
      now: clock,
    );

    for (final n in [1, 2]) {
      rec = await train(102.5, [5, 4, 3]);
      expect(rec.reasonCode, 'failedAttempt');
      expect(jsonDecode(rec.strategyStateJson)['failStreak'], n);
      await progression.decide(rec.id, RecommendationDecision.kept, now: clock);
    }

    rec = await train(102.5, [5, 4, 3]);
    expect(rec.status, RecommendationStatus.decreaseWeight);
    expect(rec.reasonCode, 'stalledReduce');
    final suggested = ProgressionRepository.decodeTargets(
      rec.recommendedTargetsJson,
    );
    // 102,5 − 10% = 92,25, arredondado para baixo em passos de 2,5.
    expect(suggested.first.weightKg, 90.0);

    // Sem aceite, a próxima sessão não muda.
    var s = await sessions.startSession(tplId);
    expect((await setsOf(s)).every((x) => x.targetWeightKg == null), isTrue);
    await sessions.discardSession(s);

    // Aceitando, a próxima sessão já vem com a carga reduzida.
    await progression.decide(
      rec.id,
      RecommendationDecision.accepted,
      now: clock,
    );
    s = await sessions.startSession(tplId);
    expect(
      (await setsOf(s)).map((x) => (x.targetWeightKg, x.targetRepsMin)),
      everyElement((90.0, 5)),
    );
  });

  test('tentativas malsucedidas ficam registradas no histórico', () async {
    await configure(const LinearProgressionConfig(targetReps: 5));
    await train(100, [5, 5, 4]);
    await train(100, [5, 4, 4]);

    final recs = await progression.watchRecommendations(exId).first;
    expect(recs.map((r) => r.reasonCode), ['failedAttempt', 'failedAttempt']);
    expect(recs.first.explanation, contains('Falha 2 de 3'));
  });

  test('exigindo 2 sessões bem-sucedidas, sobe só na segunda', () async {
    await configure(
      const LinearProgressionConfig(targetReps: 5, successesRequired: 2),
    );

    var rec = await train(80, [5, 5, 5]);
    expect(rec.reasonCode, 'needMoreSuccesses');
    rec = await train(80, [5, 5, 5]);
    expect(rec.status, RecommendationStatus.increaseWeight);
    expect(
      ProgressionRepository.decodeTargets(
        rec.recommendedTargetsJson,
      ).first.weightKg,
      82.5,
    );
  });
}
