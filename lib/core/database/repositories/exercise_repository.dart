import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

class ExerciseRepository {
  final AppDatabase _db;

  ExerciseRepository(this._db);

  Stream<List<Exercise>> watchExercises({
    String? muscleGroup,
    String search = '',
  }) {
    return (_db.select(_db.exercises)
          ..where((e) {
            Expression<bool> filter = e.isArchived.equals(false);
            if (muscleGroup != null) {
              filter = filter & e.muscleGroup.equals(muscleGroup);
            }
            if (search.isNotEmpty) {
              filter = filter &
                  e.name.lower().like('%${search.toLowerCase()}%');
            }
            return filter;
          })
          ..orderBy([
            (e) => OrderingTerm.asc(e.muscleGroup),
            (e) => OrderingTerm.asc(e.name),
          ]))
        .watch();
  }

  Future<List<Exercise>> getAll() {
    return (_db.select(_db.exercises)
          ..where((e) => e.isArchived.equals(false)))
        .get();
  }

  Future<int> createExercise({
    required String name,
    required String muscleGroup,
    required SetType setType,
    int restSeconds = 90,
  }) {
    return _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            name: name,
            muscleGroup: muscleGroup,
            setType: setType,
            restSeconds: Value(restSeconds),
          ),
        );
  }

  Future<void> updateExercise(
    int id, {
    String? name,
    String? muscleGroup,
    SetType? setType,
    int? restSeconds,
  }) {
    return (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        muscleGroup:
            muscleGroup != null ? Value(muscleGroup) : const Value.absent(),
        setType: setType != null ? Value(setType) : const Value.absent(),
        restSeconds:
            restSeconds != null ? Value(restSeconds) : const Value.absent(),
      ),
    );
  }

  Future<void> archiveExercise(int id) {
    return (_db.update(_db.exercises)..where((e) => e.id.equals(id)))
        .write(const ExercisesCompanion(isArchived: Value(true)));
  }

  Future<bool> hasHistory(int exerciseId) async {
    final rows = await (_db.select(_db.sessionExercises)
          ..where((se) => se.exerciseId.equals(exerciseId)))
        .get();
    return rows.isNotEmpty;
  }
}
