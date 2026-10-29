import 'dart:convert';

import 'package:drift/drift.dart';

import '../../progression/progression_enums.dart';
import '../../progression/progression_models.dart';
import '../app_database.dart';
import 'session_repository.dart' show isFilledSet;

class RecommendationWithExercise {
  final ProgressionRecommendationEntry recommendation;
  final Exercise exercise;

  const RecommendationWithExercise({
    required this.recommendation,
    required this.exercise,
  });
}

/// Persistência do mecanismo de progressão: configurações versionadas,
/// recomendações e decisões do usuário, e leitura do histórico no formato do
/// motor.
class ProgressionRepository {
  final AppDatabase _db;

  ProgressionRepository(this._db);

  // ── Configurações ──────────────────────────────────────────────────────────

  /// Config em vigor do exercício; `null` = sem progressão automática.
  Future<ProgressionConfigEntry?> activeConfig(int exerciseId) =>
      _activeConfigQuery(exerciseId).getSingleOrNull();

  Stream<ProgressionConfigEntry?> watchActiveConfig(int exerciseId) =>
      _activeConfigQuery(exerciseId).watchSingleOrNull();

  SimpleSelectStatement<$ProgressionConfigsTable, ProgressionConfigEntry>
  _activeConfigQuery(int exerciseId) {
    return _db.select(_db.progressionConfigs)
      ..where((c) => c.exerciseId.equals(exerciseId) & c.supersededAt.isNull())
      ..orderBy([(c) => OrderingTerm.desc(c.id)])
      ..limit(1);
  }

  Future<ProgressionConfigEntry?> configById(int id) => (_db.select(
    _db.progressionConfigs,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Salva uma nova versão da config do exercício. A versão anterior é
  /// encerrada (nunca editada), preservando o vínculo das recomendações
  /// antigas.
  Future<int> saveConfig({
    required int exerciseId,
    required StrategyId strategy,
    required Map<String, Object?> params,
    required double incrementKg,
    required DateTime now,
    DateTime? baselineFrom,
  }) {
    return _db.transaction(() async {
      await _supersedeActive(exerciseId, now);
      return _db
          .into(_db.progressionConfigs)
          .insert(
            ProgressionConfigsCompanion.insert(
              exerciseId: exerciseId,
              strategy: strategy,
              paramsJson: jsonEncode(params),
              incrementKg: incrementKg,
              createdAt: now,
              baselineFrom: Value(baselineFrom),
            ),
          );
    });
  }

  /// Volta o exercício para "sem progressão automática". Configs e
  /// recomendações antigas continuam no histórico; pendentes deixam de valer.
  Future<void> deactivate(int exerciseId, DateTime now) {
    return _db.transaction(() async {
      await _supersedeActive(exerciseId, now);
      await _supersedePending(exerciseId);
    });
  }

  Future<void> _supersedeActive(int exerciseId, DateTime now) {
    return (_db.update(_db.progressionConfigs)..where(
          (c) => c.exerciseId.equals(exerciseId) & c.supersededAt.isNull(),
        ))
        .write(ProgressionConfigsCompanion(supersededAt: Value(now)));
  }

  // ── Recomendações ──────────────────────────────────────────────────────────

  /// Grava uma recomendação como pendente. A pendente anterior do mesmo
  /// exercício, se houver, passa a `superseded`.
  Future<int> insertRecommendation({
    required int exerciseId,
    required int configId,
    required StrategyId strategy,
    required int sourceSessionId,
    required DateTime generatedAt,
    required ProgressionResult result,
  }) {
    return _db.transaction(() async {
      await _supersedePending(exerciseId);
      return _db
          .into(_db.progressionRecommendations)
          .insert(
            ProgressionRecommendationsCompanion.insert(
              exerciseId: exerciseId,
              configId: configId,
              strategy: strategy,
              generatedAt: generatedAt,
              sourceSessionId: sourceSessionId,
              analyzedSessionIdsJson: jsonEncode(result.analyzedSessionIds),
              status: result.status,
              reasonCode: result.reasonCode,
              explanation: result.explanation,
              criteriaMetJson: _encodeCriteria(result.met),
              criteriaUnmetJson: _encodeCriteria(result.unmet),
              currentWeightKg: Value(result.currentWeightKg),
              recommendedTargetsJson: encodeTargets(result.nextTargets),
              strategyStateJson: jsonEncode(result.state),
            ),
          );
    });
  }

  Future<void> _supersedePending(int exerciseId) {
    return (_db.update(_db.progressionRecommendations)..where(
          (r) =>
              r.exerciseId.equals(exerciseId) &
              r.decision.equalsValue(RecommendationDecision.pending),
        ))
        .write(
          const ProgressionRecommendationsCompanion(
            decision: Value(RecommendationDecision.superseded),
          ),
        );
  }

  /// Registra a decisão do usuário sobre uma recomendação pendente.
  ///
  /// `adjusted` exige [finalTargets]. Recomendações já decididas não mudam:
  /// retorna `false` nesse caso.
  Future<bool> decide(
    int recommendationId,
    RecommendationDecision decision, {
    required DateTime now,
    List<SetTarget>? finalTargets,
  }) async {
    if (decision == RecommendationDecision.pending ||
        decision == RecommendationDecision.superseded) {
      throw ArgumentError.value(decision, 'decision', 'não é uma decisão');
    }
    if (decision == RecommendationDecision.adjusted &&
        (finalTargets == null || finalTargets.isEmpty)) {
      throw ArgumentError('Ajuste manual exige as metas finais');
    }

    final updated =
        await (_db.update(_db.progressionRecommendations)..where(
              (r) =>
                  r.id.equals(recommendationId) &
                  r.decision.equalsValue(RecommendationDecision.pending),
            ))
            .write(
              ProgressionRecommendationsCompanion(
                decision: Value(decision),
                decidedAt: Value(now),
                finalTargetsJson: Value(
                  decision == RecommendationDecision.adjusted
                      ? encodeTargets(finalTargets!)
                      : null,
                ),
              ),
            );
    return updated > 0;
  }

  Future<ProgressionRecommendationEntry?> pendingRecommendation(
    int exerciseId,
  ) {
    return (_db.select(_db.progressionRecommendations)
          ..where(
            (r) =>
                r.exerciseId.equals(exerciseId) &
                r.decision.equalsValue(RecommendationDecision.pending),
          )
          ..orderBy([(r) => OrderingTerm.desc(r.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Recomendações geradas ao fim da sessão [sessionId], com o exercício.
  Stream<List<RecommendationWithExercise>> watchSessionRecommendations(
      int sessionId) {
    final query = _withExercise()
      ..where(_db.progressionRecommendations.sourceSessionId.equals(sessionId) &
          _db.progressionRecommendations.decision
              .equalsValue(RecommendationDecision.superseded)
              .not())
      ..orderBy([OrderingTerm.asc(_db.progressionRecommendations.id)]);
    return query.watch().map(_mapWithExercise);
  }

  /// Recomendações ainda pendentes dos exercícios informados.
  Future<List<RecommendationWithExercise>> pendingForExercises(
      Iterable<int> exerciseIds) async {
    final query = _withExercise()
      ..where(_db.progressionRecommendations.exerciseId.isIn(exerciseIds) &
          _db.progressionRecommendations.decision
              .equalsValue(RecommendationDecision.pending))
      ..orderBy([OrderingTerm.asc(_db.progressionRecommendations.id)]);
    return _mapWithExercise(await query.get());
  }

  JoinedSelectStatement _withExercise() {
    return _db.select(_db.progressionRecommendations).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.progressionRecommendations.exerciseId),
      ),
    ]);
  }

  List<RecommendationWithExercise> _mapWithExercise(List<TypedResult> rows) => [
        for (final row in rows)
          RecommendationWithExercise(
            recommendation: row.readTable(_db.progressionRecommendations),
            exercise: row.readTable(_db.exercises),
          ),
      ];

  /// Recomendações do exercício, mais recentes primeiro (todas as decisões).
  Stream<List<ProgressionRecommendationEntry>> watchRecommendations(
    int exerciseId,
  ) {
    return (_db.select(_db.progressionRecommendations)
          ..where((r) => r.exerciseId.equals(exerciseId))
          ..orderBy([(r) => OrderingTerm.desc(r.id)]))
        .watch();
  }

  /// Estado da estratégia gravado na recomendação mais recente gerada com a
  /// mesma config (vazio se não houver). Com [beforeSession], só considera
  /// recomendações anteriores à primeira gerada por aquela sessão.
  Future<Map<String, Object?>> latestState(
    int exerciseId,
    int configId, {
    int? beforeSession,
  }) async {
    // Reavaliar uma sessão parte do estado de antes da primeira avaliação
    // dela; senão o estado (ex: posição no ciclo de ondas) avançaria duas
    // vezes pela mesma sessão.
    final first = beforeSession == null
        ? null
        : await (_db.select(_db.progressionRecommendations)
                ..where(
                  (r) =>
                      r.exerciseId.equals(exerciseId) &
                      r.configId.equals(configId) &
                      r.sourceSessionId.equals(beforeSession),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.id)])
                ..limit(1))
              .getSingleOrNull();
    final row =
        await (_db.select(_db.progressionRecommendations)
              ..where(
                (r) =>
                    r.exerciseId.equals(exerciseId) &
                    r.configId.equals(configId) &
                    (first == null
                        ? const Constant(true)
                        : r.id.isSmallerThanValue(first.id)),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return const {};
    return (jsonDecode(row.strategyStateJson) as Map).cast<String, Object?>();
  }

  /// Metas a aplicar na próxima sessão do exercício: as da recomendação
  /// aceita (ou ajustada) mais recente da config vigente que ainda não foi
  /// usada em nenhuma sessão. `null` = manter o comportamento padrão.
  Future<({int recommendationId, List<SetTarget> targets})?> targetsToApply(
    int exerciseId,
    int activeConfigId,
  ) async {
    final row =
        await (_db.select(_db.progressionRecommendations)
              ..where(
                (r) =>
                    r.exerciseId.equals(exerciseId) &
                    r.configId.equals(activeConfigId) &
                    r.decision.isInValues([
                      RecommendationDecision.accepted,
                      RecommendationDecision.adjusted,
                    ]),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;

    final used =
        await (_db.select(_db.sessionExercises)
              ..where((se) => se.recommendationId.equals(row.id))
              ..limit(1))
            .getSingleOrNull();
    if (used != null) return null;

    final targets = decodeTargets(
      row.finalTargetsJson ?? row.recommendedTargetsJson,
    );
    if (targets.isEmpty) return null;
    return (recommendationId: row.id, targets: targets);
  }

  // ── Histórico ──────────────────────────────────────────────────────────────

  /// Sessões finalizadas do exercício, mais recente primeiro, no formato do
  /// motor. Ignora sessões marcadas para não avaliar, séries vazias e (se
  /// [since] for informado) sessões anteriores à "nova referência".
  Future<List<SessionRecord>> loadHistory(
    int exerciseId, {
    DateTime? since,
    int limit = 20,
  }) async {
    final query =
        _db.select(_db.sessionExercises).join([
            innerJoin(
              _db.sessions,
              _db.sessions.id.equalsExp(_db.sessionExercises.sessionId),
            ),
          ])
          ..where(
            _db.sessionExercises.exerciseId.equals(exerciseId) &
                _db.sessions.finishedAt.isNotNull() &
                _db.sessionExercises.excludeFromProgression.equals(false),
          )
          ..orderBy([
            OrderingTerm.desc(_db.sessions.startedAt),
            OrderingTerm.desc(_db.sessionExercises.id),
          ])
          ..limit(limit);
    if (since != null) {
      query.where(_db.sessions.startedAt.isBiggerOrEqualValue(since));
    }

    final rows = await query.get();
    final records = <SessionRecord>[];
    for (final row in rows) {
      final session = row.readTable(_db.sessions);
      final se = row.readTable(_db.sessionExercises);
      final sets =
          await (_db.select(_db.sessionSets)
                ..where(
                  (s) => s.sessionExerciseId.equals(se.id) & isFilledSet(s),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.position)]))
              .get();
      if (sets.isEmpty) continue;

      records.add(
        SessionRecord(
          sessionId: session.id,
          date: session.startedAt,
          configId: se.progressionConfigId,
          sets: [
            for (final s in sets)
              SetRecord(
                weightKg: s.weightKg,
                reps: s.reps,
                isWarmup: s.isWarmup,
                toFailure: s.toFailure,
                rir: s.rir,
                rpe: s.rpe,
                quality: s.executionQuality,
                role: s.setRole,
              ),
          ],
        ),
      );
    }
    return records;
  }

  // ── JSON ───────────────────────────────────────────────────────────────────

  static String encodeTargets(List<SetTarget> targets) =>
      jsonEncode([for (final t in targets) t.toJson()]);

  static List<SetTarget> decodeTargets(String json) => [
    for (final t in jsonDecode(json) as List)
      SetTarget.fromJson((t as Map).cast<String, Object?>()),
  ];

  static String _encodeCriteria(List<Criterion> criteria) =>
      jsonEncode([for (final c in criteria) c.toJson()]);

  static List<Criterion> decodeCriteria(String json) => [
    for (final c in jsonDecode(json) as List)
      Criterion.fromJson((c as Map).cast<String, Object?>()),
  ];
}
