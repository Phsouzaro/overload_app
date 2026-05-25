import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'tables.dart';

part 'app_database.g.dart';
part 'seed_data.dart';

@DriftDatabase(tables: [
  Exercises,
  WorkoutTemplates,
  TemplateExercises,
  Sessions,
  SessionExercises,
  SessionSets,
  BodyWeightEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Construtor para testes: aceita qualquer executor (ex: NativeDatabase.memory()).
  @visibleForTesting
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((b) => b.insertAll(exercises, seedExercises));
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add position column (defaults to 0 for existing rows)
          await m.addColumn(workoutTemplates, workoutTemplates.position);

          // Assign sequential positions ordered by creation date
          final rows = await (select(workoutTemplates)
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
          for (var i = 0; i < rows.length; i++) {
            await (update(workoutTemplates)
                  ..where((t) => t.id.equals(rows[i].id)))
                .write(WorkoutTemplatesCompanion(position: Value(i)));
          }
        }
      },
      beforeOpen: (_) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'overload_db');
  }
}
