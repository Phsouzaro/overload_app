import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

/// O que sugerir depois de várias tentativas malsucedidas seguidas na mesma
/// carga. Nada é aplicado sem o usuário aceitar.
enum StallPolicy {
  /// Continuar na mesma carga.
  maintain,

  /// Pedir revisão manual (o usuário decide).
  review,

  /// Sugerir reduzir a carga em `deloadPercent`.
  reduce,
}

class LinearProgressionConfig extends ProgressionConfig {
  final int sets;
  final int targetReps;

  /// Sessões bem-sucedidas seguidas, na mesma carga, para subir.
  final int successesRequired;

  /// Tentativas malsucedidas seguidas, na mesma carga, antes de aplicar a
  /// [stallPolicy].
  final int failureTolerance;
  final StallPolicy stallPolicy;

  /// Redução sugerida (%) com [StallPolicy.reduce].
  final int deloadPercent;
  final int? targetRir;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  const LinearProgressionConfig({
    this.sets = 3,
    this.targetReps = 5,
    this.successesRequired = 1,
    this.failureTolerance = 3,
    this.stallPolicy = StallPolicy.reduce,
    this.deloadPercent = 10,
    this.targetRir,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.linear;

  @override
  bool get usesRir => targetRir != null;

  @override
  String get summary =>
      '$sets × $targetReps'
      '${successesRequired > 1 ? ' · $successesRequired sessões' : ''}'
      '${targetRir != null ? ' · RIR $targetRir' : ''}';

  @override
  Map<String, Object?> toJson() => {
    'sets': sets,
    'targetReps': targetReps,
    'successesRequired': successesRequired,
    'failureTolerance': failureTolerance,
    'stallPolicy': stallPolicy.name,
    'deloadPercent': deloadPercent,
    if (targetRir != null) 'targetRir': targetRir,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory LinearProgressionConfig.fromJson(Map<String, Object?> json) =>
      LinearProgressionConfig(
        sets: json['sets'] as int,
        targetReps: json['targetReps'] as int,
        successesRequired: json['successesRequired'] as int? ?? 1,
        failureTolerance: json['failureTolerance'] as int? ?? 3,
        stallPolicy: StallPolicy.values.byName(
          json['stallPolicy'] as String? ?? 'reduce',
        ),
        deloadPercent: json['deloadPercent'] as int? ?? 10,
        targetRir: json['targetRir'] as int?,
        rounding: LoadRounding.values.byName(
          json['rounding'] as String? ?? 'nearest',
        ),
        requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
      );

  LinearProgressionConfig copyWith({
    int? sets,
    int? targetReps,
    int? successesRequired,
    int? failureTolerance,
    StallPolicy? stallPolicy,
    int? deloadPercent,
    int? Function()? targetRir,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return LinearProgressionConfig(
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
      successesRequired: successesRequired ?? this.successesRequired,
      failureTolerance: failureTolerance ?? this.failureTolerance,
      stallPolicy: stallPolicy ?? this.stallPolicy,
      deloadPercent: deloadPercent ?? this.deloadPercent,
      targetRir: targetRir != null ? targetRir() : this.targetRir,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }
}

/// Como uma sessão conta para as sequências de sucesso e falha.
enum _Outcome {
  success,
  failure,

  /// Não conta para nenhum lado: sessão interrompida (séries a menos),
  /// cargas diferentes ou meta atingida sem RIR registrado.
  inconclusive,
}

class _SessionResult {
  final _Outcome outcome;

  /// Carga comum das séries; `null` quando não há uma só carga.
  final double? load;
  final int sessionId;

  const _SessionResult(this.outcome, this.load, this.sessionId);
}

/// Progressão Linear: sobe a carga após sessões bem-sucedidas, com meta fixa
/// de repetições.
///
/// Regras (docs/PROGRESSAO.md, Modo 2):
/// - sessão bem-sucedida = todas as séries com a meta de reps, execução
///   válida e, se houver, o RIR-alvo;
/// - pode exigir várias sessões bem-sucedidas seguidas na mesma carga;
/// - tentativas malsucedidas são registradas; após `failureTolerance`
///   seguidas, aplica a política de estagnação (manter, revisar ou sugerir
///   redução), sempre como sugestão;
/// - sequências são recalculadas a partir do histórico real, sem contador
///   guardado.
class LinearProgressionStrategy
    extends ProgressionStrategy<LinearProgressionConfig> {
  const LinearProgressionStrategy();

  @override
  StrategyId get id => StrategyId.linear;

  @override
  String get displayName => 'Progressão Linear';

  @override
  LinearProgressionConfig configFromJson(Map<String, Object?> json) =>
      LinearProgressionConfig.fromJson(json);

  @override
  List<ConfigIssue> validate(LinearProgressionConfig config) => [
    if (config.sets < 1 || config.sets > 10)
      const ConfigIssue('sets', 'use de 1 a 10 séries'),
    if (config.targetReps < 1 || config.targetReps > 50)
      const ConfigIssue('targetReps', 'a meta vai de 1 a 50 repetições'),
    if (config.successesRequired < 1 || config.successesRequired > 5)
      const ConfigIssue(
        'successesRequired',
        'exija de 1 a 5 sessões bem-sucedidas',
      ),
    if (config.failureTolerance < 1 || config.failureTolerance > 10)
      const ConfigIssue('failureTolerance', 'tolere de 1 a 10 falhas'),
    if (config.stallPolicy == StallPolicy.reduce &&
        (config.deloadPercent < 5 || config.deloadPercent > 30))
      const ConfigIssue('deloadPercent', 'a redução vai de 5% a 30%'),
    if (config.targetRir != null &&
        (config.targetRir! < 0 || config.targetRir! > 5))
      const ConfigIssue('targetRir', 'RIR-alvo vai de 0 a 5'),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<LinearProgressionConfig> input) {
    final c = input.config;
    final ex = input.exercise;

    SetTarget targetFor(double? weightKg) => SetTarget(
      weightKg: weightKg,
      repsMin: c.targetReps,
      repsMax: c.targetReps,
      rir: c.targetRir,
    );
    List<SetTarget> targetsAt(double weightKg) => [
      for (var i = 0; i < c.sets; i++)
        targetFor(SessionChecks.loadOrNull(weightKg, ex)),
    ];

    final check0 = SessionChecks.latest(
      input,
      sets: c.sets,
      targetFor: targetFor,
    );
    if (check0.stop != null) return check0.stop!;
    final checked = check0.session!;
    final considered = checked.considered;
    final load = checked.load;
    final loadText = SessionChecks.describeLoad(load, ex);
    final repsText = checked.repsText;

    // Sequências na carga atual, da sessão mais recente para trás. Sessões
    // inconclusivas não contam nem interrompem a sequência.
    final results = [for (final s in input.history) _classify(s, c)];
    var successStreak = 0;
    var failStreak = 0;
    var countingSuccess = true;
    var countingFailure = true;
    final analyzed = <int>[];
    for (final r in results) {
      if (r.load != null && r.load != load) break;
      if (r.outcome == _Outcome.inconclusive) continue;
      analyzed.add(r.sessionId);
      if (r.outcome == _Outcome.success) {
        countingFailure = false;
        if (countingSuccess) successStreak++;
      } else {
        countingSuccess = false;
        if (countingFailure) failStreak++;
      }
      if (!countingSuccess && !countingFailure) break;
    }
    if (analyzed.isEmpty || analyzed.first != checked.session.sessionId) {
      analyzed.insert(0, checked.session.sessionId);
    }
    final latest = results.first.outcome;

    // Critérios da sessão mais recente.
    final met = <Criterion>[];
    final unmet = <Criterion>[];
    void check(bool ok, Criterion criterion) =>
        (ok ? met : unmet).add(criterion);

    final enoughSets = considered.length >= c.sets;
    check(
      enoughSets,
      Criterion(
        'setsCompleted',
        '${c.sets} séries de trabalho registradas (${considered.length} feitas)',
      ),
    );
    final invalid = SessionChecks.invalidSets(
      considered,
      requireMarkedValid: c.requireMarkedValid,
    );
    check(
      invalid.isEmpty,
      Criterion(
        'validExecution',
        c.requireMarkedValid
            ? 'Todas as séries marcadas como execução válida'
            : 'Nenhuma série com falha técnica ou execução inválida',
      ),
    );
    final repsMet = considered.every((s) => (s.reps ?? 0) >= c.targetReps);
    check(
      repsMet,
      Criterion('targetReps', 'Todas as séries com ${c.targetReps} reps'),
    );
    var rirMissing = false;
    if (c.targetRir != null) {
      final rir = SessionChecks.checkRir(considered, c.targetRir!);
      rirMissing = rir.missing;
      check(
        !rir.missing && rir.ok,
        Criterion('targetRir', 'Esforço dentro do RIR-alvo (≥ ${c.targetRir})'),
      );
    }
    check(
      successStreak >= c.successesRequired,
      Criterion(
        'successStreak',
        '${c.successesRequired} sessão(ões) bem-sucedida(s) seguida(s) com '
            '$loadText ($successStreak feita(s))',
      ),
    );

    final qualityNote = SessionChecks.qualityNote(
      considered,
      requireMarkedValid: c.requireMarkedValid,
    );
    final state = {
      'successStreak': successStreak,
      'failStreak': failStreak,
      'loadKg': load,
    };

    ProgressionResult result(
      RecommendationStatus status,
      String reason,
      String explanation,
      double nextLoad,
    ) => ProgressionResult(
      status: status,
      reasonCode: reason,
      explanation: explanation + qualityNote,
      met: met,
      unmet: unmet,
      currentWeightKg: load,
      analyzedSessionIds: analyzed,
      nextTargets: targetsAt(nextLoad),
      state: state,
    );

    if (!enoughSets) {
      return result(
        RecommendationStatus.maintain,
        'incompleteSession',
        'Foram registradas ${considered.length} de ${c.sets} séries de '
            'trabalho. A sessão não conta como sucesso nem como falha; '
            'mantenha $loadText.',
        load,
      );
    }
    if (latest == _Outcome.inconclusive && rirMissing) {
      return result(
        RecommendationStatus.maintain,
        'rirMissing',
        'Você completou $repsText com $loadText, mas o RIR não foi '
            'registrado. Registre o RIR para a sessão contar como sucesso.',
        load,
      );
    }

    if (latest == _Outcome.success) {
      if (successStreak >= c.successesRequired) {
        final next = ProgressionRules.roundToIncrement(
          load + ex.incrementKg,
          ex.incrementKg,
          mode: c.rounding,
        );
        final streakText = c.successesRequired > 1
            ? ' em $successStreak sessões seguidas'
            : '';
        return result(
          RecommendationStatus.increaseWeight,
          'successStreakReached',
          'Você completou ${c.sets} × ${c.targetReps} com $loadText'
              '$streakText, dentro dos critérios configurados. Suba para '
              '${SessionChecks.describeLoad(next, ex)}.',
          next,
        );
      }
      return result(
        RecommendationStatus.maintain,
        'needMoreSuccesses',
        'Sessão bem-sucedida com $loadText ($successStreak de '
            '${c.successesRequired}). Repita a carga para confirmar antes '
            'de subir.',
        load,
      );
    }

    // Tentativa malsucedida.
    final why = invalid.isNotEmpty
        ? '${invalid.length} série(s) com execução comprometida'
        : !repsMet
        ? 'você fez $repsText e a meta é ${c.targetReps}'
        : 'o esforço ficou acima do RIR-alvo';
    if (failStreak < c.failureTolerance) {
      return result(
        RecommendationStatus.maintain,
        'failedAttempt',
        'Tentativa não concluída com $loadText ($why). Falha $failStreak de '
            '${c.failureTolerance} toleradas: mantenha a carga e tente de novo.',
        load,
      );
    }

    final stalled =
        '$failStreak tentativas seguidas sem completar ${c.sets} × '
        '${c.targetReps} com $loadText';
    switch (c.stallPolicy) {
      case StallPolicy.maintain:
        return result(
          RecommendationStatus.maintain,
          'stalledMaintain',
          '$stalled. Pela sua configuração, a sugestão é manter a carga.',
          load,
        );
      case StallPolicy.review:
        return result(
          RecommendationStatus.manualReview,
          'stalledReview',
          '$stalled. Revise a carga, a técnica ou a recuperação antes da '
              'próxima sessão.',
          load,
        );
      case StallPolicy.reduce:
        final next = ProgressionRules.roundToIncrement(
          load * (1 - c.deloadPercent / 100),
          ex.incrementKg,
          mode: LoadRounding.down,
        );
        if (next <= 0 || next >= load) {
          return result(
            RecommendationStatus.manualReview,
            'stalledCannotReduce',
            '$stalled. Não há como reduzir a carga pelo incremento '
                'configurado; revise o exercício.',
            load,
          );
        }
        return result(
          RecommendationStatus.decreaseWeight,
          'stalledReduce',
          '$stalled. Sugestão: reduzir ${c.deloadPercent}% para '
              '${SessionChecks.describeLoad(next, ex)} e progredir de novo. '
              'Só vale se você aceitar.',
          next,
        );
    }
  }

  static _SessionResult _classify(
    SessionRecord session,
    LinearProgressionConfig c,
  ) {
    final considered = ProgressionRules.workingSets(session).take(c.sets);
    final loads = {for (final s in considered) s.weightKg ?? 0.0};
    if (loads.length != 1) {
      return _SessionResult(_Outcome.inconclusive, null, session.sessionId);
    }
    final load = loads.single;
    if (considered.length < c.sets) {
      return _SessionResult(_Outcome.inconclusive, load, session.sessionId);
    }

    final valid = SessionChecks.invalidSets(
      considered,
      requireMarkedValid: c.requireMarkedValid,
    ).isEmpty;
    final repsMet = considered.every((s) => (s.reps ?? 0) >= c.targetReps);
    if (!valid || !repsMet) {
      return _SessionResult(_Outcome.failure, load, session.sessionId);
    }
    if (c.targetRir != null) {
      final rir = SessionChecks.checkRir(considered, c.targetRir!);
      if (!rir.ok) {
        return _SessionResult(_Outcome.failure, load, session.sessionId);
      }
      if (rir.missing) {
        return _SessionResult(_Outcome.inconclusive, load, session.sessionId);
      }
    }
    return _SessionResult(_Outcome.success, load, session.sessionId);
  }
}
