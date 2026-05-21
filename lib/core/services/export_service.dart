import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

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
