import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/rpe_based_progression.dart';
import 'package:overload/core/services/progression_service.dart';

import '../helpers/progression_fixtures.dart';

/// Progressão por RPE com o registry real: captura, avaliação e correção.
void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late SessionRepository sessions;
  late ProgressionService service;
  late int exId;
  late int tplId;
  final now = DateTime(2026, 7, 1, 18);

  setUp(() async {
    db = await openTestDb();
    progression = ProgressionRepository(db);
    sessions = SessionRepository(db);
    service = ProgressionService(db, clock: () => now);
    exId = await insertExercise(db, name: 'Supino Inclinado Teste');
    tplId = await insertTemplate(db);
    await progression.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.rpeBased,
      params: const RpeBasedConfig(repsMin: 8, repsMax: 10).toJson(),
      incrementKg: 2.5,
      now: DateTime(2026, 6, 1),
    );
  });

  tearDown(() => db.close());

  Future<(int, List<SessionSet>)> workout({double? rpe, int? rir}) async {
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
        weightKg: 40,
        reps: 10,
        rpe: rpe,
        rir: rir,
        position: i,
      );
    }
    final sets = await (db.select(
      db.sessionSets,
    )..where((x) => x.sessionExerciseId.equals(seId))).get();
    return (s, sets);
  }

  test('RPE no alvo e topo da faixa → sugere subir com RPE-alvo', () async {
    final (s, _) = await workout(rpe: 8);
    await service.evaluateFinishedSession(s);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.status, RecommendationStatus.increaseWeight);
    final target = ProgressionRepository.decodeTargets(
      rec.recommendedTargetsJson,
    ).first;
    expect((target.weightKg, target.rpe, target.rir), (42.5, 8.0, null));
  });

  test('só RIR registrado: dados insuficientes (sem conversão)', () async {
    final (s, _) = await workout(rir: 2);
    await service.evaluateFinishedSession(s);

    final rec = (await progression.pendingRecommendation(exId))!;
    expect(rec.reasonCode, 'rpeMissing');
  });

  test('RPE corrigido depois do treino: reavaliar usa o valor novo', () async {
    final (s, sets) = await workout(rpe: 9.5);
    await service.evaluateFinishedSession(s);
    expect(
      (await progression.pendingRecommendation(exId))!.reasonCode,
      'effortAboveTarget',
    );

    for (final x in sets) {
      await sessions.updateSetDetails(x.id, rir: null, rpe: 8, quality: null);
    }
    await service.evaluateFinishedSession(s);
    expect(
      (await progression.pendingRecommendation(exId))!.status,
      RecommendationStatus.increaseWeight,
    );
  });

  test('gravar RPE não altera o RIR já registrado (e vice-versa)', () async {
    final (_, sets) = await workout(rir: 2);
    await sessions.updateSetDetails(
      sets.first.id,
      rir: 2,
      rpe: 8.5,
      quality: null,
    );

    final saved = await (db.select(
      db.sessionSets,
    )..where((x) => x.id.equals(sets.first.id))).getSingle();
    expect((saved.rir, saved.rpe), (2, 8.5));
  });
}
