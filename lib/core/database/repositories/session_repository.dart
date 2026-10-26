import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
import '../../progression/progression_enums.dart';
import 'progression_repository.dart';

class SessionExerciseWithExercise {
  final SessionExercise sessionExercise;
  final Exercise exercise;

  const SessionExerciseWithExercise({
    required this.sessionExercise,
    required this.exercise,
  });
}

class FinishedSessionSummary {
  final Session session;
  final String templateName;

  const FinishedSessionSummary({
    required this.session,
    required this.templateName,
  });
}

class ActiveSessionSummary {
  final Session session;
  final String templateName;

  const ActiveSessionSummary({
    required this.session,
    required this.templateName,
  });
}

class SessionSetDetail {
  final Exercise exercise;
  final List<SessionSet> sets;

  const SessionSetDetail({required this.exercise, required this.sets});
}

/// Série com algum valor registrado. As séries pré-criadas que o usuário não
/// preencheu ficam com tudo nulo e não devem contar em resumos e históricos.
Expression<bool> isFilledSet($SessionSetsTable s) =>
    s.weightKg.isNotNull() | s.reps.isNotNull() | s.durationSeconds.isNotNull();

class SessionRepository {
  final AppDatabase _db;

  SessionRepository(this._db);

  Future<int> startSession(int templateId) {
    return _db.transaction(() async {
      // Só existe uma sessão ativa por vez: qualquer sessão não finalizada
      // ainda no banco foi abandonada (ex: app encerrado no meio do treino).
      final stale = await (_db.select(_db.sessions)
            ..where((s) => s.finishedAt.isNull()))
          .get();
      for (final session in stale) {
        await _deleteSessionData(session.id);
      }

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
        // Se não há histórico, o usuário adiciona as séries manualmente.
        await _addSessionExercise(
          sessionId: sessionId,
          exercise: exercise,
          position: i,
          restSeconds: te.restSecondsOverride ?? exercise.restSeconds,
          minSets: 0,
        );
      }

      return sessionId;
    });
  }

  /// Adiciona [exercise] só a esta sessão (o treino salvo não muda). Pré-cria
  /// as séries como no início da sessão, ou uma série vazia sem histórico.
  Future<void> addExtraExercise(int sessionId, Exercise exercise) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.sessionExercises)
            ..where((se) => se.sessionId.equals(sessionId)))
          .get();
      final position = existing.isEmpty
          ? 0
          : existing.map((se) => se.position).reduce(max) + 1;

      await _addSessionExercise(
        sessionId: sessionId,
        exercise: exercise,
        position: position,
        restSeconds: exercise.restSeconds,
        minSets: 1,
        isExtra: true,
      );
    });
  }

  /// Cria o exercício na sessão e pré-cria suas séries.
  ///
  /// Guarda a config de progressão vigente. Se houver recomendação aceita
  /// (ou ajustada) ainda não usada, as séries nascem com as metas dela;
  /// senão, uma série vazia por série de trabalho da última vez (mínimo
  /// [minSets]).
  Future<void> _addSessionExercise({
    required int sessionId,
    required Exercise exercise,
    required int position,
    required int restSeconds,
    required int minSets,
    bool isExtra = false,
  }) async {
    final progression = ProgressionRepository(_db);
    final config = await progression.activeConfig(exercise.id);
    final planned = config == null
        ? null
        : await progression.targetsToApply(exercise.id, config.id);

    final seId = await _db.into(_db.sessionExercises).insert(
          SessionExercisesCompanion.insert(
            sessionId: sessionId,
            exerciseId: exercise.id,
            position: position,
            restSeconds: Value(restSeconds),
            isExtra: Value(isExtra),
            progressionConfigId: Value(config?.id),
            recommendationId: Value(planned?.recommendationId),
          ),
        );

    if (planned != null) {
      for (var j = 0; j < planned.targets.length; j++) {
        final t = planned.targets[j];
        await _db.into(_db.sessionSets).insert(
              SessionSetsCompanion.insert(
                sessionExerciseId: seId,
                setType: exercise.setType,
                position: j,
                setRole: Value(t.role),
                targetWeightKg: Value(t.weightKg),
                targetRepsMin: Value(t.repsMin),
                targetRepsMax: Value(t.repsMax),
              ),
            );
      }
      return;
    }

    final prevSets = await getPreviousSets(0, exercise.id);
    final count = max(prevSets.length, minSets);
    for (var j = 0; j < count; j++) {
      await _db.into(_db.sessionSets).insert(
            SessionSetsCompanion.insert(
              sessionExerciseId: seId,
              setType: exercise.setType,
              position: j,
            ),
          );
    }
  }

  /// Tira um exercício da sessão, junto com as séries registradas nele.
  Future<void> removeSessionExercise(int sessionExerciseId) {
    return _db.transaction(() async {
      await (_db.delete(_db.sessionSets)
            ..where((s) => s.sessionExerciseId.equals(sessionExerciseId)))
          .go();
      await (_db.delete(_db.sessionExercises)
            ..where((se) => se.id.equals(sessionExerciseId)))
          .go();
    });
  }

  Future<Session> getSession(int sessionId) {
    return (_db.select(_db.sessions)..where((s) => s.id.equals(sessionId)))
        .getSingle();
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

  /// Grava RIR e qualidade da execução de uma série. `null` limpa o valor
  /// (volta a "não registrado"), permitindo corrigir o que foi informado.
  Future<void> updateSetDetails(
    int setId, {
    required int? rir,
    required ExecutionQuality? quality,
  }) {
    return (_db.update(_db.sessionSets)..where((s) => s.id.equals(setId)))
        .write(SessionSetsCompanion(
      rir: Value(rir),
      executionQuality: Value(quality),
    ));
  }

  Future<void> deleteSet(int setId) {
    return (_db.delete(_db.sessionSets)..where((s) => s.id.equals(setId)))
        .go();
  }

  /// Finaliza a sessão, descartando as séries que ficaram sem valores.
  Future<void> finishSession(int sessionId) {
    return _db.transaction(() async {
      await (_db.delete(_db.sessionSets)
            ..where((s) =>
                s.sessionExerciseId.isInQuery(_sessionExerciseIds(sessionId)) &
                isFilledSet(s).not()))
          .go();

      await (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId)))
          .write(SessionsCompanion(finishedAt: Value(DateTime.now())));
    });
  }

  /// Salva as anotações da sessão; texto vazio remove a anotação.
  Future<void> updateNotes(int sessionId, String? notes) {
    final trimmed = notes?.trim();
    return (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId)))
        .write(SessionsCompanion(
      notes: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
    ));
  }

  /// Apaga a sessão e tudo que foi registrado nela ("Sair sem salvar").
  Future<void> discardSession(int sessionId) {
    return _db.transaction(() => _deleteSessionData(sessionId));
  }

  Future<void> _deleteSessionData(int sessionId) async {
    await (_db.delete(_db.sessionSets)
          ..where((s) =>
              s.sessionExerciseId.isInQuery(_sessionExerciseIds(sessionId))))
        .go();
    await (_db.delete(_db.sessionExercises)
          ..where((se) => se.sessionId.equals(sessionId)))
        .go();
    await (_db.delete(_db.sessions)..where((s) => s.id.equals(sessionId)))
        .go();
  }

  BaseSelectStatement _sessionExerciseIds(int sessionId) {
    return _db.selectOnly(_db.sessionExercises)
      ..addColumns([_db.sessionExercises.id])
      ..where(_db.sessionExercises.sessionId.equals(sessionId));
  }

  /// Retorna as séries (não-aquecimento) da última vez que [exerciseId] foi
  /// executado em qualquer treino finalizado — independente do template.
  Future<List<SessionSet>> getPreviousSets(
      int templateId, int exerciseId) async {
    // Busca o sessionExercise mais recente para esse exercício em qualquer
    // sessão finalizada, independente do template, que tenha ao menos uma
    // série de trabalho preenchida.
    final query = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
      ),
      innerJoin(
        _db.sessionSets,
        _db.sessionSets.sessionExerciseId.equalsExp(_db.sessionExercises.id),
      ),
    ])
      ..where(
        _db.sessionExercises.exerciseId.equals(exerciseId) &
            _db.sessions.finishedAt.isNotNull() &
            _db.sessionSets.isWarmup.equals(false) &
            isFilledSet(_db.sessionSets),
      )
      ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)])
      ..limit(1);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final se = rows.first.readTable(_db.sessionExercises);

    return (_db.select(_db.sessionSets)
          ..where((s) =>
              s.sessionExerciseId.equals(se.id) &
              s.isWarmup.equals(false) &
              isFilledSet(s))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  /// Sessão iniciada e ainda não encerrada (no máximo uma por vez).
  Stream<ActiveSessionSummary?> watchActiveSession() =>
      _activeSessionQuery().watch().map(_toActiveSession);

  Future<ActiveSessionSummary?> getActiveSession() async =>
      _toActiveSession(await _activeSessionQuery().get());

  JoinedSelectStatement _activeSessionQuery() {
    return _db.select(_db.sessions).join([
      innerJoin(
        _db.workoutTemplates,
        _db.workoutTemplates.id.equalsExp(_db.sessions.templateId),
      ),
    ])
      ..where(_db.sessions.finishedAt.isNull())
      ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)])
      ..limit(1);
  }

  ActiveSessionSummary? _toActiveSession(List<TypedResult> rows) {
    if (rows.isEmpty) return null;
    return ActiveSessionSummary(
      session: rows.first.readTable(_db.sessions),
      templateName: rows.first.readTable(_db.workoutTemplates).name,
    );
  }

  Stream<List<FinishedSessionSummary>> watchFinishedSessions() {
    final query = _db.select(_db.sessions).join([
      innerJoin(
        _db.workoutTemplates,
        _db.workoutTemplates.id.equalsExp(_db.sessions.templateId),
      ),
    ])
      ..where(_db.sessions.finishedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)]);

    return query.watch().map((rows) => rows
        .map((row) => FinishedSessionSummary(
              session: row.readTable(_db.sessions),
              templateName: row.readTable(_db.workoutTemplates).name,
            ))
        .toList());
  }

  Future<List<SessionSetDetail>> getSessionDetail(int sessionId) async {
    final query = _db.select(_db.sessionExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.sessionExercises.exerciseId),
      ),
    ])
      ..where(_db.sessionExercises.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm.asc(_db.sessionExercises.position)]);

    final rows = await query.get();
    final result = <SessionSetDetail>[];

    for (final row in rows) {
      final exercise = row.readTable(_db.exercises);
      final seId = row.readTable(_db.sessionExercises).id;
      final sets = await (_db.select(_db.sessionSets)
            ..where((s) => s.sessionExerciseId.equals(seId) & isFilledSet(s))
            ..orderBy([(s) => OrderingTerm.asc(s.position)]))
          .get();
      result.add(SessionSetDetail(exercise: exercise, sets: sets));
    }

    return result;
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
              s.sessionExerciseId.isIn(ids) &
              s.isWarmup.equals(false) &
              isFilledSet(s)))
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
