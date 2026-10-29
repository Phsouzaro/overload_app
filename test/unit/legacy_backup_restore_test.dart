import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/double_progression.dart';
import 'package:overload/core/services/backup_service.dart';
import 'package:overload/core/services/progression_service.dart';
import 'package:path/path.dart' as p;

import '../helpers/legacy_db.dart';

/// Critério 7: backups feitos por versões antigas do app (antes da
/// progressão inteligente) restauram pelo fluxo real e passam a funcionar
/// com a progressão.
void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('overload'));
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Backup de um app na versão [version], com um treino de supino.
  Future<File> legacyBackup(int version) async {
    final file = File(p.join(tmp.path, 'backup_v$version.sqlite'));
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final exId = await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: 'Supino Antigo',
            muscleGroup: 'Peito',
            setType: SetType.weight,
          ),
        );
    final tplId = await db
        .into(db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(name: 'Treino Antigo'));
    final sessionId = await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2026, 7, 20),
            finishedAt: Value(DateTime(2026, 7, 20, 1)),
          ),
        );
    final seId = await db
        .into(db.sessionExercises)
        .insert(
          SessionExercisesCompanion.insert(
            sessionId: sessionId,
            exerciseId: exId,
            position: 0,
          ),
        );
    for (var i = 0; i < 3; i++) {
      await db
          .into(db.sessionSets)
          .insert(
            SessionSetsCompanion.insert(
              sessionExerciseId: seId,
              setType: SetType.weight,
              position: i,
              weightKg: const Value(50),
              reps: const Value(12),
            ),
          );
    }
    await downgradeTo(db, version);
    await db.close();
    return file;
  }

  for (final version in [3, 4, 5]) {
    test('backup v$version restaura, migra e aceita progressão', () async {
      final backup = await legacyBackup(version);

      // App atual (v6) com dados próprios, em arquivo.
      final target = File(p.join(tmp.path, 'overload_db.sqlite'));
      final current = AppDatabase.forTesting(NativeDatabase(target));
      expect(
        BackupService.validateHeader(
          await backup.openRead(0, 100).expand((b) => b).toList(),
          currentSchema: current.schemaVersion,
        ),
        version,
      );
      await BackupService(current).restore(backup, target: target);

      final db = AppDatabase.forTesting(NativeDatabase(target));
      addTearDown(db.close);
      final userVersion = await db
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 6);

      // Dados do backup intactos.
      final ex = await (db.select(
        db.exercises,
      )..where((e) => e.name.equals('Supino Antigo'))).getSingle();
      final template = await (db.select(
        db.workoutTemplates,
      )..where((t) => t.name.equals('Treino Antigo'))).getSingle();
      expect(template.groupName, isNull);
      final sets = await db.select(db.sessionSets).get();
      expect(sets.map((s) => (s.weightKg, s.reps)), everyElement((50.0, 12)));
      expect(sets.map((s) => s.setRole), everyElement(isNull));

      // Progressão funciona sobre o histórico antigo.
      final repo = ProgressionRepository(db);
      await repo.saveConfig(
        exerciseId: ex.id,
        strategy: StrategyId.doubleProgression,
        params: const DoubleProgressionConfig().toJson(),
        incrementKg: 2.5,
        now: DateTime(2026, 7, 21),
      );
      final session = await db.select(db.sessions).getSingle();
      final ids = await ProgressionService(
        db,
        clock: () => DateTime(2026, 7, 21),
      ).evaluateFinishedSession(session.id);
      expect(ids, hasLength(1));
      final rec = (await repo.pendingRecommendation(ex.id))!;
      expect(rec.status, RecommendationStatus.increaseWeight);
    });
  }
}
