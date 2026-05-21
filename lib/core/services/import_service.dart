import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

class ImportResult {
  final String templateName;
  final int exercisesAdded;
  final int exercisesReused;

  const ImportResult({
    required this.templateName,
    required this.exercisesAdded,
    required this.exercisesReused,
  });
}

class ImportService {
  final AppDatabase _db;

  ImportService(this._db);

  /// Opens a file picker for `.overload` files and imports the template.
  /// Returns null if the user cancels.
  Future<ImportResult?> importTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    return _parseAndImport(content);
  }

  Future<ImportResult> _parseAndImport(String content) async {
    final Map<String, dynamic> json = jsonDecode(content);

    final version = json['version'] as int? ?? 1;
    if (version != 1) {
      throw Exception('Versão de arquivo não suportada: $version');
    }

    final templateJson = json['template'] as Map<String, dynamic>;
    final templateName = templateJson['name'] as String;
    final exercisesJson =
        (templateJson['exercises'] as List<dynamic>).cast<Map<String, dynamic>>();

    int added = 0;
    int reused = 0;

    // ── Resolve unique template name ─────────────────────────────────────────
    final resolvedName = await _resolveTemplateName(templateName);

    // ── Create template ──────────────────────────────────────────────────────
    final templateId = await _db
        .into(_db.workoutTemplates)
        .insert(WorkoutTemplatesCompanion.insert(name: resolvedName));

    // ── For each exercise: reuse existing by name or create ──────────────────
    for (var i = 0; i < exercisesJson.length; i++) {
      final exJson = exercisesJson[i];
      final name = exJson['name'] as String;
      final muscleGroup = exJson['muscleGroup'] as String;
      final setTypeStr = exJson['setType'] as String;
      final restSeconds = exJson['restSeconds'] as int? ?? 90;

      final setType = SetType.values.firstWhere(
        (t) => t.name == setTypeStr,
        orElse: () => SetType.weight,
      );

      // Look up existing (non-archived) exercise by name (case-insensitive)
      final existing = await (_db.select(_db.exercises)
            ..where((e) =>
                e.name.lower().equals(name.toLowerCase()) &
                e.isArchived.equals(false)))
          .getSingleOrNull();

      final int exerciseId;
      if (existing != null) {
        exerciseId = existing.id;
        reused++;
      } else {
        exerciseId = await _db.into(_db.exercises).insert(
              ExercisesCompanion.insert(
                name: name,
                muscleGroup: muscleGroup,
                setType: setType,
                restSeconds: Value(restSeconds),
              ),
            );
        added++;
      }

      // Link exercise to template
      await _db.into(_db.templateExercises).insert(
            TemplateExercisesCompanion.insert(
              templateId: templateId,
              exerciseId: exerciseId,
              position: i,
            ),
          );
    }

    return ImportResult(
      templateName: resolvedName,
      exercisesAdded: added,
      exercisesReused: reused,
    );
  }

  /// If a template with the same name already exists, appends (2), (3), etc.
  Future<String> _resolveTemplateName(String name) async {
    final existing = await (_db.select(_db.workoutTemplates)
          ..where((t) => t.name.lower().like('${name.toLowerCase()}%')))
        .get();

    if (existing.isEmpty) return name;

    final existingNames = existing.map((t) => t.name.toLowerCase()).toSet();
    if (!existingNames.contains(name.toLowerCase())) return name;

    int counter = 2;
    while (existingNames.contains('$name ($counter)'.toLowerCase())) {
      counter++;
    }
    return '$name ($counter)';
  }
}
