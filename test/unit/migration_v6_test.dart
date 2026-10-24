import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:path/path.dart' as p;

/// Volta um banco v6 para o formato v5: sem as tabelas de progressão e sem
/// as colunas novas de `session_sets` e `session_exercises`.
Future<void> _downgradeToV5(AppDatabase db) async {
  await db.customStatement('PRAGMA foreign_keys = OFF');
  await db.customStatement('DROP TABLE progression_recommendations');
  await db.customStatement('DROP TABLE progression_configs');
  for (final (table, columns) in [
    (
      'session_exercises',
      'id, session_id, exercise_id, position, rest_seconds, is_extra',
    ),
    (
      'session_sets',
      'id, session_exercise_id, set_type, weight_kg, reps, duration_seconds, '
          'is_warmup, to_failure, position',
    ),
  ]) {
    await db.customStatement(
      'CREATE TABLE ${table}_v5 AS SELECT $columns FROM $table',
    );
    await db.customStatement('DROP TABLE $table');
    await db.customStatement('ALTER TABLE ${table}_v5 RENAME TO $table');
  }
  await db.customStatement('PRAGMA user_version = 5');
}

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('overload_migration');
    file = File(p.join(tmp.path, 'overload_db.sqlite'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('banco v5 com dados migra para v6 sem perder nada', () async {
    // ── Banco "antigo" com um treino registrado ──
    final old = AppDatabase.forTesting(NativeDatabase(file));
    final exId = await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: 'Supino',
            muscleGroup: 'Peito',
            setType: SetType.weight,
          ),
        );
    final tplId = await old
        .into(old.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            name: 'Treino A',
            groupName: const Value('GYM'),
          ),
        );
    final sessionId = await old
        .into(old.sessions)
        .insert(
          SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2026, 1, 1),
            finishedAt: Value(DateTime(2026, 1, 1, 1)),
            notes: const Value('Ombro ok'),
          ),
        );
    final seId = await old
        .into(old.sessionExercises)
        .insert(
          SessionExercisesCompanion.insert(
            sessionId: sessionId,
            exerciseId: exId,
            position: 0,
            restSeconds: const Value(120),
            isExtra: const Value(true),
          ),
        );
    await old
        .into(old.sessionSets)
        .insert(
          SessionSetsCompanion.insert(
            sessionExerciseId: seId,
            setType: SetType.weight,
            position: 0,
            weightKg: const Value(50),
            reps: const Value(10),
            toFailure: const Value(true),
          ),
        );
    await _downgradeToV5(old);
    await old.close();

    // ── App atualizado abre o banco: roda a migration 5 → 6 ──
    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 6);

    // Dados antigos intactos
    final template = await db.select(db.workoutTemplates).getSingle();
    expect((template.name, template.groupName), ('Treino A', 'GYM'));
    final session = await db.select(db.sessions).getSingle();
    expect(session.notes, 'Ombro ok');
    final se = await db.select(db.sessionExercises).getSingle();
    expect((se.restSeconds, se.isExtra), (120, true));
    final set = await db.select(db.sessionSets).getSingle();
    expect((set.weightKg, set.reps, set.toFailure), (50.0, 10, true));

    // Colunas novas existem com valores neutros
    expect(se.progressionConfigId, isNull);
    expect(se.recommendationId, isNull);
    expect(se.excludeFromProgression, isFalse);
    expect(
      (set.rir, set.rpe, set.executionQuality, set.setRole),
      (null, null, null, null),
    );
    expect(set.targetWeightKg, isNull);

    // Tabelas novas utilizáveis
    final repo = ProgressionRepository(db);
    await repo.saveConfig(
      exerciseId: exId,
      strategy: StrategyId.doubleProgression,
      params: const {'sets': 3},
      incrementKg: 2.5,
      now: DateTime(2026, 1, 2),
    );
    expect(await repo.activeConfig(exId), isNotNull);
    expect((await repo.loadHistory(exId)).single.sessionId, sessionId);
  });
}
