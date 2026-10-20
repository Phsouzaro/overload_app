import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';

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
          ..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.createdAt), // tiebreaker
          ]))
        .watch();
  }

  Future<void> reorderTemplates(List<WorkoutTemplate> templates) {
    return _db.batch((batch) {
      for (var i = 0; i < templates.length; i++) {
        batch.update(
          _db.workoutTemplates,
          WorkoutTemplatesCompanion(position: Value(i)),
          where: (t) => t.id.equals(templates[i].id),
        );
      }
    });
  }

  Future<WorkoutTemplate?> getTemplate(int id) {
    return (_db.select(
      _db.workoutTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createTemplate(String name, {String? group}) {
    return _db
        .into(_db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            name: name,
            groupName: Value(normalizeGroup(group)),
          ),
        );
  }

  /// Define o grupo do treino; vazio ou `null` tira do grupo.
  Future<void> setTemplateGroup(int id, String? group) {
    return (_db.update(
      _db.workoutTemplates,
    )..where((t) => t.id.equals(id))).write(
      WorkoutTemplatesCompanion(groupName: Value(normalizeGroup(group))),
    );
  }

  static String? normalizeGroup(String? group) {
    final trimmed = group?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Grupos usados pelos [templates], sem repetição, em ordem alfabética.
  static List<String> groupsOf(List<WorkoutTemplate> templates) {
    final groups = <String>{
      for (final t in templates)
        if (t.groupName != null) t.groupName!,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return groups;
  }

  /// Reordena dentro da lista filtrada ([visible], subconjunto de [all]) e
  /// devolve a ordem completa: os treinos fora do filtro ficam onde estão, e
  /// os visíveis trocam de lugar entre si.
  static List<WorkoutTemplate> reorderVisible(
    List<WorkoutTemplate> all,
    List<WorkoutTemplate> visible,
    int oldIndex,
    int newIndex,
  ) {
    final moved = List<WorkoutTemplate>.from(visible);
    moved.insert(newIndex, moved.removeAt(oldIndex));

    final visibleIds = {for (final t in visible) t.id};
    var next = 0;
    return [for (final t in all) visibleIds.contains(t.id) ? moved[next++] : t];
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
    int templateId,
  ) {
    final query =
        _db.select(_db.templateExercises).join([
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
    final existing = await (_db.select(
      _db.templateExercises,
    )..where((te) => te.templateId.equals(templateId))).get();
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((e) => e.position).reduce(max) + 1;

    await _db
        .into(_db.templateExercises)
        .insert(
          TemplateExercisesCompanion.insert(
            templateId: templateId,
            exerciseId: exerciseId,
            position: nextPosition,
          ),
        );
  }

  /// Define o descanso do exercício neste treino; `null` volta ao padrão do
  /// exercício.
  Future<void> setRestOverride(int templateExerciseId, int? seconds) {
    return (_db.update(_db.templateExercises)
          ..where((te) => te.id.equals(templateExerciseId)))
        .write(TemplateExercisesCompanion(restSecondsOverride: Value(seconds)));
  }

  Future<void> removeExerciseFromTemplate(int templateExerciseId) {
    return (_db.delete(
      _db.templateExercises,
    )..where((te) => te.id.equals(templateExerciseId))).go();
  }

  Future<void> updateExercisePositions(
    List<TemplateExerciseWithDetails> items,
  ) {
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
