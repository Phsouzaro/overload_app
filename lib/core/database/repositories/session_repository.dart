import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

class SessionExerciseWithExercise {
  final SessionExercise sessionExercise;
  final Exercise exercise;

  const SessionExerciseWithExercise({
    required this.sessionExercise,
    required this.exercise,
  });
}

class SessionRepository {
  final AppDatabase _db;

  SessionRepository(this._db);

  Future<int> startSession(int templateId) {
    return _db.transaction(() async {
      final sessionId = await _db.into(_db.sessions).insert(
            SessionsCompanion.insert(
              templateId: templateId,
              startedAt: DateTime.now(),
            ),
          );

      // Join templateExercises + exercises para obter o setType
      final query = _db.select(_db.templateExercises).join([
        innerJoin(
          _db.exercises,
          _db.exercises.id.equalsExp(_db.templateExercises.exerciseId),
        ),
      ])
        ..where(_db.templateExercises.templateId.equals(templateId))
        ..orderBy([OrderingTerm.asc(_db.templateExercises.position)]);

      final rows = await query.get();

      for (var i = 0; i < rows.length; i++) {
        final te = rows[i].readTable(_db.templateExercises);
        final exercise = rows[i].readTable(_db.exercises);

        final seId = await _db.into(_db.sessionExercises).insert(
              SessionExercisesCompanion.insert(
                sessionId: sessionId,
                exerciseId: te.exerciseId,
                position: i,
              ),
            );

        // Pré-cria séries vazias com base na sessão anterior
        final prevSets = await getPreviousSets(templateId, te.exerciseId);
        for (var j = 0; j < prevSets.length; j++) {
          await _db.into(_db.sessionSets).insert(
                SessionSetsCompanion.insert(
                  sessionExerciseId: seId,
                  setType: exercise.setType,
                  position: j,
                ),
              );
        }
        // Se não há histórico, o usuário adiciona manualmente (comportamento original)
      }

      return sessionId;
    });
  }

  Stream<List<SessionExerciseWithExercise>> watchSessionExercises(
      int sessionId) {
    final query = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
      ),
    ])
      ..where(_db.sessionExercises.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm.asc(_db.sessionExercises.position)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => SessionExerciseWithExercise(
                  sessionExercise: row.readTable(_db.sessionExercises),
                  exercise: row.readTable(_db.exercises),
                ),
              )
              .toList(),
        );
  }

  Stream<List<SessionSet>> watchSets(int sessionExerciseId) {
    return (_db.select(_db.sessionSets)
          ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .watch();
  }

  Future<void> addSet(int sessionExerciseId, SetType setType) async {
    final existing = await (_db.select(_db.sessionSets)
          ..where((s) => s.sessionExerciseId.equals(sessionExerciseId)))
        .get();
    final position = existing.isEmpty
        ? 0
        : existing.map((s) => s.position).reduce(max) + 1;

    await _db.into(_db.sessionSets).insert(
          SessionSetsCompanion.insert(
            sessionExerciseId: sessionExerciseId,
            setType: setType,
            position: position,
          ),
        );
  }

  Future<void> updateSet(
    int setId, {
    double? weightKg,
    int? reps,
    int? durationSeconds,
    bool? isWarmup,
    bool? toFailure,
  }) {
    return (_db.update(_db.sessionSets)..where((s) => s.id.equals(setId)))
        .write(
      SessionSetsCompanion(
        weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        durationSeconds: durationSeconds != null
            ? Value(durationSeconds)
            : const Value.absent(),
        isWarmup: isWarmup != null ? Value(isWarmup) : const Value.absent(),
        toFailure: toFailure != null ? Value(toFailure) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteSet(int setId) {
    return (_db.delete(_db.sessionSets)..where((s) => s.id.equals(setId)))
        .go();
  }

  Future<void> finishSession(int sessionId) {
    return (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId)))
        .write(SessionsCompanion(finishedAt: Value(DateTime.now())));
  }

  Future<List<SessionSet>> getPreviousSets(
      int templateId, int exerciseId) async {
    final lastSession = await (_db.select(_db.sessions)
          ..where((s) =>
              s.templateId.equals(templateId) & s.finishedAt.isNotNull())
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (lastSession == null) return [];

    final sessionExercise = await (_db.select(_db.sessionExercises)
          ..where((se) =>
              se.sessionId.equals(lastSession.id) &
              se.exerciseId.equals(exerciseId)))
        .getSingleOrNull();

    if (sessionExercise == null) return [];

    return (_db.select(_db.sessionSets)
          ..where((s) =>
              s.sessionExerciseId.equals(sessionExercise.id) &
              s.isWarmup.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  Future<({int totalSets, double totalVolume})> getSessionSummary(
      int sessionId) async {
    final sessionExercises = await (_db.select(_db.sessionExercises)
          ..where((se) => se.sessionId.equals(sessionId)))
        .get();

    if (sessionExercises.isEmpty) return (totalSets: 0, totalVolume: 0.0);

    final ids = sessionExercises.map((e) => e.id).toList();
    final sets = await (_db.select(_db.sessionSets)
          ..where((s) =>
              s.sessionExerciseId.isIn(ids) & s.isWarmup.equals(false)))
        .get();

    final volume = sets.fold<double>(0, (sum, s) {
      if (s.weightKg != null && s.reps != null) {
        return sum + s.weightKg! * s.reps!;
      }
      return sum;
    });

    return (totalSets: sets.length, totalVolume: volume);
  }
}
