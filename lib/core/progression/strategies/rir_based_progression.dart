import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

class RirBasedConfig extends ProgressionConfig {
  final int sets;
  final int repsMin;
  final int repsMax;

  /// RIR planejado (0–5).
  final int targetRir;

  /// Variação aceita em torno do RIR-alvo (0–2): a percepção de esforço muda
  /// de uma sessão para outra.
  final int rirTolerance;
  final EffortCriterion criterion;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  const RirBasedConfig({
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 12,
    this.targetRir = 2,
    this.rirTolerance = 1,
    this.criterion = EffortCriterion.allSets,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.rirBased;

  @override
  bool get usesRir => true;

  @override
  String get summary =>
      '$sets × $repsMin–$repsMax · RIR $targetRir'
      '${rirTolerance > 0 ? '±$rirTolerance' : ''}';

  @override
  Map<String, Object?> toJson() => {
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'targetRir': targetRir,
    'rirTolerance': rirTolerance,
    'criterion': criterion.name,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory RirBasedConfig.fromJson(Map<String, Object?> json) => RirBasedConfig(
    sets: json['sets'] as int,
    repsMin: json['repsMin'] as int,
    repsMax: json['repsMax'] as int,
    targetRir: json['targetRir'] as int,
    rirTolerance: json['rirTolerance'] as int? ?? 1,
    criterion: EffortCriterion.values.byName(
      json['criterion'] as String? ?? 'allSets',
    ),
    rounding: LoadRounding.values.byName(
      json['rounding'] as String? ?? 'nearest',
    ),
    requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
  );

  RirBasedConfig copyWith({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? targetRir,
    int? rirTolerance,
    EffortCriterion? criterion,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return RirBasedConfig(
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      targetRir: targetRir ?? this.targetRir,
      rirTolerance: rirTolerance ?? this.rirTolerance,
      criterion: criterion ?? this.criterion,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }
}

/// Progressão por RIR: o esforço informado (repetições em reserva) decide,
/// junto com a faixa de repetições, quando subir a carga.
///
/// Regras (docs/PROGRESSAO.md, Modo 3):
/// - o RIR é a estimativa informada pelo usuário: nunca é deduzido de carga e
///   repetições;
/// - falha técnica não é RIR 0: a série não conta; falha muscular (⚡) conta
///   como RIR 0;
/// - esforço acima do limite (RIR < alvo − tolerância) nunca sobe a carga;
/// - RIR alto sozinho não sobe a carga: as repetições precisam chegar ao topo
///   da faixa;
/// - sem RIR registrado, a resposta é conservadora e pede o dado.
class RirBasedStrategy extends ProgressionStrategy<RirBasedConfig> {
  const RirBasedStrategy();

  @override
  StrategyId get id => StrategyId.rirBased;

  @override
  String get displayName => 'Progressão por RIR';

  @override
  RirBasedConfig configFromJson(Map<String, Object?> json) =>
      RirBasedConfig.fromJson(json);

  @override
  List<ConfigIssue> validate(RirBasedConfig config) => [
    if (config.sets < 1 || config.sets > 10)
      const ConfigIssue('sets', 'use de 1 a 10 séries'),
    if (config.repsMin < 1)
      const ConfigIssue('repsMin', 'o mínimo precisa ser pelo menos 1'),
    if (config.repsMax > 50)
      const ConfigIssue('repsMax', 'o máximo vai até 50 repetições'),
    if (config.repsMin > config.repsMax)
      const ConfigIssue('repsMax', 'o máximo não pode ser menor que o mínimo'),
    if (config.targetRir < 0 || config.targetRir > 5)
      const ConfigIssue('targetRir', 'RIR-alvo vai de 0 a 5'),
    if (config.rirTolerance < 0 || config.rirTolerance > 2)
      const ConfigIssue('rirTolerance', 'a tolerância vai de 0 a 2'),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<RirBasedConfig> input) {
    final c = input.config;
    final ex = input.exercise;

    SetTarget targetFor(double? weightKg) => SetTarget(
      weightKg: weightKg,
      repsMin: c.repsMin,
      repsMax: c.repsMax,
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
    final analyzed = [checked.session.sessionId];

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
    final belowMin = [
      for (final s in considered)
        if ((s.reps ?? 0) < c.repsMin) s,
    ];
    check(
      belowMin.isEmpty,
      Criterion(
        'minimumReached',
        'Todas as séries com ao menos ${c.repsMin} reps',
      ),
    );
    final topReached =
        enoughSets && considered.every((s) => (s.reps ?? 0) >= c.repsMax);
    check(
      topReached,
      Criterion('topOfRange', 'Todas as séries com ${c.repsMax} reps'),
    );

    // RIR informado (falha muscular = 0). Nunca estimado a partir da carga.
    final rirSets = switch (c.criterion) {
      EffortCriterion.allSets => considered,
      EffortCriterion.lastSet => [considered.last],
    };
    final rirs = [for (final s in rirSets) s.toFailure ? 0 : s.rir];
    final rirMissing = rirs.contains(null);
    final lowestRir = rirMissing
        ? null
        : rirs.cast<int>().reduce((a, b) => a < b ? a : b);
    final floor = c.targetRir - c.rirTolerance;
    final ceiling = c.targetRir + c.rirTolerance;
    final effortOk = lowestRir != null && lowestRir >= floor;
    check(
      effortOk,
      Criterion(
        'rirWithinTarget',
        'RIR ${c.criterion == EffortCriterion.lastSet ? 'da última série ' : ''}'
            '≥ $floor (alvo ${c.targetRir}'
            '${c.rirTolerance > 0 ? ' ± ${c.rirTolerance}' : ''})'
            '${lowestRir != null ? ': registrado $lowestRir' : ''}',
      ),
    );

    final qualityNote = SessionChecks.qualityNote(
      considered,
      requireMarkedValid: c.requireMarkedValid,
    );

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
    );

    if (!enoughSets) {
      return result(
        RecommendationStatus.maintain,
        'incompleteSession',
        'Foram registradas ${considered.length} de ${c.sets} séries de '
            'trabalho. Mantenha $loadText e complete as séries.',
        load,
      );
    }
    if (invalid.isNotEmpty) {
      return result(
        RecommendationStatus.maintain,
        'invalidExecution',
        '${invalid.length} série(s) com falha técnica, execução inválida ou '
            'qualidade não marcada. Falha técnica não é o mesmo que chegar '
            'ao limite (RIR 0): essas séries não contam. Mantenha $loadText.',
        load,
      );
    }
    if (rirMissing) {
      return result(
        RecommendationStatus.insufficientData,
        'rirMissing',
        'O RIR não foi registrado em todas as séries avaliadas. Esta '
            'estratégia não estima o RIR pela carga: registre-o (ou corrija '
            'no histórico) para receber a sugestão. Por ora, mantenha '
            '$loadText.',
        load,
      );
    }
    if (lowestRir! < floor) {
      return result(
        RecommendationStatus.maintain,
        'effortAboveTarget',
        'Você fez $repsText com $loadText, mas com esforço acima do '
            'planejado (RIR $lowestRir; o limite é $floor). Mantenha a carga '
            'até o esforço voltar ao alvo.',
        load,
      );
    }
    if (belowMin.isNotEmpty) {
      return result(
        RecommendationStatus.maintain,
        'belowMinimum',
        'Você fez $repsText com $loadText; ${belowMin.length} série(s) '
            'ficaram abaixo de ${c.repsMin} reps. Mantenha a carga.',
        load,
      );
    }
    if (topReached) {
      final next = ProgressionRules.roundToIncrement(
        load + ex.incrementKg,
        ex.incrementKg,
        mode: c.rounding,
      );
      return result(
        RecommendationStatus.increaseWeight,
        'topOfRangeWithinRir',
        'Você concluiu ${c.sets} séries de ${c.repsMax} repetições com '
            '$loadText e RIR $lowestRir, dentro do alvo. Suba para '
            '${SessionChecks.describeLoad(next, ex)} e recomece em '
            '${c.repsMin} reps.',
        next,
      );
    }
    if (lowestRir > ceiling) {
      return result(
        RecommendationStatus.increaseReps,
        'easierThanTarget',
        'Você fez $repsText com $loadText e ainda sobraram $lowestRir '
            'repetições em reserva. RIR alto sozinho não sobe a carga: '
            'busque mais repetições até ${c.repsMax}.',
        load,
      );
    }
    return result(
      RecommendationStatus.increaseReps,
      'withinRange',
      'Você fez $repsText com $loadText e RIR $lowestRir, dentro do alvo. '
          'Mantenha a carga e busque mais repetições até ${c.repsMax}.',
      load,
    );
  }
}
