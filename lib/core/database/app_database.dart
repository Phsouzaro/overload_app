import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((b) => b.insertAll(exercises, seedExercises));
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
