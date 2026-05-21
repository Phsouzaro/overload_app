import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  // ── Template export ───────────────────────────────────────────────────────

  Future<void> exportTemplate(int templateId) async {
    // Load template
    final template = await (_db.select(_db.workoutTemplates)
          ..where((t) => t.id.equals(templateId)))
        .getSingleOrNull();
    if (template == null) return;

    // Load exercises via join
    final rows = await (_db.select(_db.templateExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.templateExercises.exerciseId),
      ),
    ])
          ..where(_db.templateExercises.templateId.equals(templateId))
          ..orderBy([OrderingTerm.asc(_db.templateExercises.position)]))
        .get();

    final exercises = rows.map((row) {
      final ex = row.readTable(_db.exercises);
      final te = row.readTable(_db.templateExercises);
      return {
        'name': ex.name,
        'muscleGroup': ex.muscleGroup,
        'setType': ex.setType.name,
        'restSeconds': te.restSecondsOverride ?? ex.restSeconds,
      };
    }).toList();

    final payload = jsonEncode({
      'version': 1,
      'template': {
        'name': template.name,
        'exercises': exercises,
      },
    });

    final dir = await getTemporaryDirectory();
    // Sanitize file name
    final safeName = template.name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${dir.path}/$safeName.overload');
    await file.writeAsString(payload);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: 'Overload — ${template.name}',
    );
  }

  Future<void> exportCsv() async {
    final query = _db.select(_db.sessionSets).join([
      innerJoin(
        _db.sessionExercises,
        _db.sessionExercises.id
            .equalsExp(_db.sessionSets.sessionExerciseId),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
      ),
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
      ),
      innerJoin(
        _db.workoutTemplates,
        _db.workoutTemplates.id.equalsExp(_db.sessions.templateId),
      ),
    ])
      ..where(_db.sessions.finishedAt.isNotNull())
      ..orderBy([
        OrderingTerm.asc(_db.sessions.startedAt),
        OrderingTerm.asc(_db.sessionExercises.id),
        OrderingTerm.asc(_db.sessionSets.id),
      ]);

    final rows = await query.get();

    final csvData = <List<dynamic>>[
      [
        'Data',
        'Treino',
        'Exercício',
        'Grupo Muscular',
        'Aquecimento',
        'Carga (kg)',
        'Reps',
        'Duração (s)',
        'Volume (kg)',
        'Até a Falha',
      ],
    ];

    for (final row in rows) {
      final session = row.readTable(_db.sessions);
      final exercise = row.readTable(_db.exercises);
      final set = row.readTable(_db.sessionSets);
      final template = row.readTable(_db.workoutTemplates);

      final d = session.startedAt;
      final date =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

      final volume = (set.weightKg != null && set.reps != null)
          ? (set.weightKg! * set.reps!).toStringAsFixed(1)
          : '';

      csvData.add([
        date,
        template.name,
        exercise.name,
        exercise.muscleGroup,
        set.isWarmup ? 'Sim' : 'Não',
        set.weightKg?.toStringAsFixed(1) ?? '',
        set.reps?.toString() ?? '',
        set.durationSeconds?.toString() ?? '',
        volume,
        set.toFailure ? 'Sim' : 'Não',
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/overload_export.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Overload — Export de Treinos',
    );
  }
}
