import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

class TemplateExerciseWithDetails {
  final TemplateExercise templateExercise;
  final Exercise exercise;

  TemplateExerciseWithDetails({
    required this.templateExercise,
    required this.exercise,
  });
}

class WorkoutRepository {
  final AppDatabase _db;

  WorkoutRepository(this._db);

  // ── Templates ──────────────────────────────────────────────────────────────

  Stream<List<WorkoutTemplate>> watchActiveTemplates() {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<WorkoutTemplate?> getTemplate(int id) {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createTemplate(String name) {
    return _db
        .into(_db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(name: name));
  }

  Future<void> renameTemplate(int id, String newName) {
    return (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(id)))
        .write(WorkoutTemplatesCompanion(name: Value(newName)));
  }

  Future<void> archiveTemplate(int id) {
    return (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(id)))
        .write(const WorkoutTemplatesCompanion(isArchived: Value(true)));
  }

  Future<void> unarchiveTemplate(int id) {
    return (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(id)))
        .write(const WorkoutTemplatesCompanion(isArchived: Value(false)));
  }

  Stream<List<WorkoutTemplate>> watchArchivedTemplates() {
    return (_db.select(_db.workoutTemplates)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  // ── Template Exercises ─────────────────────────────────────────────────────

  Stream<List<TemplateExerciseWithDetails>> watchTemplateExercises(
      int templateId) {
    final query = _db.select(_db.templateExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.templateExercises.exerciseId),
      ),
    ])
      ..where(_db.templateExercises.templateId.equals(templateId))
      ..orderBy([OrderingTerm.asc(_db.templateExercises.position)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TemplateExerciseWithDetails(
                  templateExercise: row.readTable(_db.templateExercises),
                  exercise: row.readTable(_db.exercises),
                ),
              )
              .toList(),
        );
  }

  Future<void> addExerciseToTemplate(int templateId, int exerciseId) async {
    final existing = await (_db.select(_db.templateExercises)
          ..where((te) => te.templateId.equals(templateId)))
        .get();
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((e) => e.position).reduce(max) + 1;

    await _db.into(_db.templateExercises).insert(
          TemplateExercisesCompanion.insert(
            templateId: templateId,
            exerciseId: exerciseId,
            position: nextPosition,
          ),
        );
  }

  Future<void> removeExerciseFromTemplate(int templateExerciseId) {
    return (_db.delete(_db.templateExercises)
          ..where((te) => te.id.equals(templateExerciseId)))
        .go();
  }

  Future<void> updateExercisePositions(
      List<TemplateExerciseWithDetails> items) {
    return _db.batch((batch) {
      for (var i = 0; i < items.length; i++) {
        batch.update(
          _db.templateExercises,
          TemplateExercisesCompanion(position: Value(i)),
          where: (te) => te.id.equals(items[i].templateExercise.id),
        );
      }
    });
  }
}
