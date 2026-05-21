import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';

class ExerciseHistoryEntry {
  final DateTime date;
  final String templateName;
  final List<SessionSet> sets;

  const ExerciseHistoryEntry({
    required this.date,
    required this.templateName,
    required this.sets,
  });
}

class ExerciseProgressPoint {
  final DateTime date;
  final double maxWeight;
  final double volume;

  const ExerciseProgressPoint({
    required this.date,
    required this.maxWeight,
    required this.volume,
  });
}

class WorkoutSessionPoint {
  final DateTime date;
  final double volume;
  final int totalSets;

  const WorkoutSessionPoint({
    required this.date,
    required this.volume,
    required this.totalSets,
  });
}

class ReportRepository {
  final AppDatabase _db;

  ReportRepository(this._db);

  Future<List<ExerciseProgressPoint>> getExerciseProgress(
    int exerciseId, {
    DateTime? from,
  }) async {
    final query = _db.select(_db.sessionSets).join([
      innerJoin(
        _db.sessionExercises,
        _db.sessionExercises.id
            .equalsExp(_db.sessionSets.sessionExerciseId),
      ),
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
      ),
    ])
      ..where(
        _db.sessionExercises.exerciseId.equals(exerciseId) &
            _db.sessionSets.isWarmup.equals(false) &
            _db.sessions.finishedAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.asc(_db.sessions.startedAt)]);

    if (from != null) {
      query.where(_db.sessions.startedAt.isBiggerOrEqualValue(from));
    }

    final rows = await query.get();

    final Map<String, ({double maxWeight, double volume})> byDate = {};

    for (final row in rows) {
      final session = row.readTable(_db.sessions);
      final set = row.readTable(_db.sessionSets);
      if (set.weightKg == null) continue;

      final key =
          '${session.startedAt.year}-${session.startedAt.month.toString().padLeft(2, '0')}-${session.startedAt.day.toString().padLeft(2, '0')}';
      final prev = byDate[key] ?? (maxWeight: 0.0, volume: 0.0);
      final vol = set.weightKg! * (set.reps ?? 0);
      byDate[key] = (
        maxWeight: max(prev.maxWeight, set.weightKg!),
        volume: prev.volume + vol,
      );
    }

    final list = byDate.entries
        .map((e) => ExerciseProgressPoint(
              date: DateTime.parse(e.key),
              maxWeight: e.value.maxWeight,
              volume: e.value.volume,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return list;
  }

  Future<List<ExerciseHistoryEntry>> getExerciseHistory(int exerciseId) async {
    final query = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
      ),
      innerJoin(
        _db.workoutTemplates,
        _db.workoutTemplates.id.equalsExp(_db.sessions.templateId),
      ),
    ])
      ..where(
        _db.sessionExercises.exerciseId.equals(exerciseId) &
            _db.sessions.finishedAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)]);

    final rows = await query.get();
    final result = <ExerciseHistoryEntry>[];

    for (final row in rows) {
      final session = row.readTable(_db.sessions);
      final templateName = row.readTable(_db.workoutTemplates).name;
      final se = row.readTable(_db.sessionExercises);

      final sets = await (_db.select(_db.sessionSets)
            ..where((s) => s.sessionExerciseId.equals(se.id))
            ..orderBy([(s) => OrderingTerm.asc(s.position)]))
          .get();

      if (sets.isNotEmpty) {
        result.add(ExerciseHistoryEntry(
          date: session.startedAt,
          templateName: templateName,
          sets: sets,
        ));
      }
    }

    return result;
  }

  Future<double?> getExerciseMaxWeight(int exerciseId) async {
    final query = _db.select(_db.sessionSets).join([
      innerJoin(
        _db.sessionExercises,
        _db.sessionExercises.id
            .equalsExp(_db.sessionSets.sessionExerciseId),
      ),
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
      ),
    ])
      ..where(
        _db.sessionExercises.exerciseId.equals(exerciseId) &
            _db.sessionSets.isWarmup.equals(false) &
            _db.sessions.finishedAt.isNotNull() &
            _db.sessionSets.weightKg.isNotNull(),
      );

    final rows = await query.get();
    if (rows.isEmpty) return null;

    double best = 0;
    for (final row in rows) {
      final set = row.readTable(_db.sessionSets);
      if (set.weightKg != null && set.weightKg! > best) {
        best = set.weightKg!;
      }
    }
    return best > 0 ? best : null;
  }

  Future<List<WorkoutSessionPoint>> getWorkoutProgress(
    int templateId, {
    DateTime? from,
  }) async {
    final sessionsQuery = _db.select(_db.sessions)
      ..where((s) =>
          s.templateId.equals(templateId) & s.finishedAt.isNotNull())
      ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]);

    if (from != null) {
      sessionsQuery
          .where((s) => s.startedAt.isBiggerOrEqualValue(from));
    }

    final sessions = await sessionsQuery.get();
    final List<WorkoutSessionPoint> points = [];

    for (final session in sessions) {
      final exercises = await (_db.select(_db.sessionExercises)
            ..where((se) => se.sessionId.equals(session.id)))
          .get();
      if (exercises.isEmpty) continue;

      final ids = exercises.map((e) => e.id).toList();
      final sets = await (_db.select(_db.sessionSets)
            ..where((s) =>
                s.sessionExerciseId.isIn(ids) &
                s.isWarmup.equals(false)))
          .get();

      final volume = sets.fold<double>(0, (sum, s) {
        if (s.weightKg != null && s.reps != null) {
          return sum + s.weightKg! * s.reps!;
        }
        return sum;
      });

      points.add(WorkoutSessionPoint(
        date: session.startedAt,
        volume: volume,
        totalSets: sets.length,
      ));
    }

    return points;
  }
}
