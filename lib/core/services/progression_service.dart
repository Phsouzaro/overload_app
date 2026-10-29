import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/repositories/progression_repository.dart';
import '../database/tables.dart';
import '../progression/progression_enums.dart';
import '../progression/progression_models.dart';
import '../progression/progression_registry.dart';
import '../progression/progression_strategy.dart';

/// Liga o motor de progressão ao app: ao fim de uma sessão, avalia cada
/// exercício com estratégia ativa e grava a recomendação como pendente.
///
/// Nunca altera metas por conta própria: as metas só mudam quando o usuário
/// aceita ou ajusta a recomendação (ver `ProgressionRepository.decide`).
class ProgressionService {
  final AppDatabase _db;
  final ProgressionRepository _repo;
  final ProgressionRegistry _registry;
  final DateTime Function() _clock;
  final String Function(double kg) _formatLoad;

  ProgressionService(
    this._db, {
    ProgressionRegistry? registry,
    DateTime Function()? clock,
    String Function(double kg)? formatLoad,
  }) : _repo = ProgressionRepository(_db),
       _registry = registry ?? ProgressionRegistry.standard,
       _clock = clock ?? DateTime.now,
       _formatLoad = formatLoad ?? ExerciseContext.formatKg;

  /// Avalia a sessão finalizada [sessionId]. Retorna os ids das recomendações
  /// geradas (vazio quando nenhum exercício tem estratégia ativa).
  ///
  /// Falhas em um exercício são registradas no log e não impedem os demais
  /// nem interrompem o encerramento da sessão.
  Future<List<int>> evaluateFinishedSession(int sessionId) async {
    final session = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    if (session == null || session.finishedAt == null) return const [];

    final sessionExercises =
        await (_db.select(_db.sessionExercises)..where(
              (se) =>
                  se.sessionId.equals(sessionId) &
                  se.excludeFromProgression.equals(false),
            ))
            .get();

    final created = <int>[];
    // Um exercício repetido na sessão (ex: extra duplicado) é avaliado uma vez.
    for (final exerciseId in {
      for (final se in sessionExercises) se.exerciseId,
    }) {
      try {
        final id = await _evaluateExercise(exerciseId, sessionId);
        if (id != null) created.add(id);
      } catch (e, st) {
        developer.log(
          'Falha ao avaliar progressão do exercício $exerciseId',
          name: 'progression',
          error: e,
          stackTrace: st,
        );
      }
    }
    return created;
  }

  Future<int?> _evaluateExercise(int exerciseId, int sessionId) async {
    final config = await _repo.activeConfig(exerciseId);
    if (config == null) return null;

    final exercise = await (_db.select(
      _db.exercises,
    )..where((e) => e.id.equals(exerciseId))).getSingle();
    // Exercícios por tempo ficam fora da progressão automática.
    if (exercise.setType == SetType.time) return null;

    final strategy = _registry.strategyFor(config.strategy);
    if (strategy == null) return null;

    final now = _clock();
    final result = await _run(strategy, config, exercise, now, sessionId);
    return _repo.insertRecommendation(
      exerciseId: exerciseId,
      configId: config.id,
      strategy: config.strategy,
      sourceSessionId: sessionId,
      generatedAt: now,
      result: result,
    );
  }

  Future<ProgressionResult> _run(
    ProgressionStrategy strategy,
    ProgressionConfigEntry config,
    Exercise exercise,
    DateTime now,
    int sessionId,
  ) async {
    final params = (jsonDecode(config.paramsJson) as Map)
        .cast<String, Object?>();
    final ProgressionConfig parsed;
    try {
      parsed = strategy.configFromJson(params);
    } on Object catch (e) {
      return _invalidConfig(['Parâmetros ilegíveis: $e']);
    }

    final issues = strategy.validateConfig(parsed);
    if (issues.isNotEmpty) {
      return _invalidConfig([for (final i in issues) i.toString()]);
    }

    return strategy.evaluateWith(
      config: parsed,
      exercise: ExerciseContext(
        exerciseId: exercise.id,
        name: exercise.name,
        loadType: exercise.setType == SetType.bodyweight
            ? ExerciseLoadType.bodyweight
            : ExerciseLoadType.weighted,
        incrementKg: config.incrementKg,
        formatLoad: _formatLoad,
      ),
      history: await _repo.loadHistory(exercise.id, since: config.baselineFrom),
      previousState: await _repo.latestState(
        exercise.id,
        config.id,
        beforeSession: sessionId,
      ),
      now: now,
    );
  }

  static ProgressionResult _invalidConfig(List<String> problems) {
    return ProgressionResult(
      status: RecommendationStatus.manualReview,
      reasonCode: 'invalidConfig',
      explanation:
          'A configuração de progressão deste exercício tem '
          'problemas e precisa ser revisada: ${problems.join('; ')}.',
      unmet: [for (final p in problems) Criterion('invalidConfig', p)],
    );
  }
}
