import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

/// "8", "8,5".
String _rpeText(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(1).replaceAll('.', ',');

class RpeBasedConfig extends ProgressionConfig {
  final int sets;
  final int repsMin;
  final int repsMax;

  /// RPE planejado, na escala de força 6–10 (passos de 0,5).
  final double targetRpe;

  /// Variação aceita em torno do alvo: 0, 0,5 ou 1.
  final double rpeTolerance;
  final EffortCriterion criterion;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  const RpeBasedConfig({
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 12,
    this.targetRpe = 8,
    this.rpeTolerance = 0.5,
    this.criterion = EffortCriterion.allSets,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.rpeBased;

  @override
  bool get usesRpe => true;

  @override
  String get summary =>
      '$sets × $repsMin–$repsMax · RPE ${_rpeText(targetRpe)}'
      '${rpeTolerance > 0 ? '±${_rpeText(rpeTolerance)}' : ''}';

  @override
  Map<String, Object?> toJson() => {
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'targetRpe': targetRpe,
    'rpeTolerance': rpeTolerance,
    'criterion': criterion.name,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory RpeBasedConfig.fromJson(Map<String, Object?> json) => RpeBasedConfig(
    sets: json['sets'] as int,
    repsMin: json['repsMin'] as int,
    repsMax: json['repsMax'] as int,
    targetRpe: (json['targetRpe'] as num).toDouble(),
    rpeTolerance: (json['rpeTolerance'] as num?)?.toDouble() ?? 0.5,
    criterion: EffortCriterion.values.byName(
      json['criterion'] as String? ?? 'allSets',
    ),
    rounding: LoadRounding.values.byName(
      json['rounding'] as String? ?? 'nearest',
    ),
    requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
  );

  RpeBasedConfig copyWith({
    int? sets,
    int? repsMin,
    int? repsMax,
    double? targetRpe,
    double? rpeTolerance,
    EffortCriterion? criterion,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return RpeBasedConfig(
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      targetRpe: targetRpe ?? this.targetRpe,
      rpeTolerance: rpeTolerance ?? this.rpeTolerance,
      criterion: criterion ?? this.criterion,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }
}

/// Progressão por RPE (esforço percebido), na escala de força 6–10.
///
/// Regras (docs/PROGRESSAO.md, Modo 4):
/// - o RPE é a percepção do usuário, não uma medida objetiva: só ajusta a
///   decisão junto com as repetições e a execução válida;
/// - esforço acima do planejado (RPE > alvo + tolerância) mantém a carga;
/// - meta de repetições atingida com esforço dentro (ou abaixo) do
///   planejado sobe a carga;
/// - RPE e RIR são independentes: nenhum é convertido no outro. A única
///   regra explícita é que falha muscular (⚡) vale RPE 10, o topo da escala;
/// - sem RPE registrado, a resposta é conservadora e o histórico não muda.
class RpeBasedStrategy extends ProgressionStrategy<RpeBasedConfig> {
  const RpeBasedStrategy();

  @override
  StrategyId get id => StrategyId.rpeBased;

  @override
  String get displayName => 'Progressão por RPE';

  @override
  RpeBasedConfig configFromJson(Map<String, Object?> json) =>
      RpeBasedConfig.fromJson(json);

  static bool _onHalfStep(double v) => (v * 2) == (v * 2).roundToDouble();

  @override
  List<ConfigIssue> validate(RpeBasedConfig config) => [
    if (config.sets < 1 || config.sets > 10)
      const ConfigIssue('sets', 'use de 1 a 10 séries'),
    if (config.repsMin < 1)
      const ConfigIssue('repsMin', 'o mínimo precisa ser pelo menos 1'),
    if (config.repsMax > 50)
      const ConfigIssue('repsMax', 'o máximo vai até 50 repetições'),
    if (config.repsMin > config.repsMax)
      const ConfigIssue('repsMax', 'o máximo não pode ser menor que o mínimo'),
    if (config.targetRpe < 6 ||
        config.targetRpe > 10 ||
        !_onHalfStep(config.targetRpe))
      const ConfigIssue(
        'targetRpe',
        'RPE-alvo vai de 6 a 10, em passos de 0,5',
      ),
    if (![0.0, 0.5, 1.0].contains(config.rpeTolerance))
      const ConfigIssue('rpeTolerance', 'a tolerância é 0, 0,5 ou 1'),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<RpeBasedConfig> input) {
    final c = input.config;
    final ex = input.exercise;

    SetTarget targetFor(double? weightKg) => SetTarget(
      weightKg: weightKg,
      repsMin: c.repsMin,
      repsMax: c.repsMax,
      rpe: c.targetRpe,
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

    // RPE informado. Falha muscular = 10 (topo da escala). Sem conversão de
    // RIR: uma série com RIR mas sem RPE conta como RPE não registrado.
    final rpeSets = switch (c.criterion) {
      EffortCriterion.allSets => considered,
      EffortCriterion.lastSet => [considered.last],
    };
    final rpes = [for (final s in rpeSets) s.toFailure ? 10.0 : s.rpe];
    final rpeMissing = rpes.contains(null);
    final highestRpe = rpeMissing
        ? null
        : rpes.cast<double>().reduce((a, b) => a > b ? a : b);
    final floor = c.targetRpe - c.rpeTolerance;
    final ceiling = c.targetRpe + c.rpeTolerance;
    check(
      highestRpe != null && highestRpe <= ceiling,
      Criterion(
        'rpeWithinTarget',
        'RPE ${c.criterion == EffortCriterion.lastSet ? 'da última série ' : ''}'
            '≤ ${_rpeText(ceiling)} (alvo ${_rpeText(c.targetRpe)}'
            '${c.rpeTolerance > 0 ? ' ± ${_rpeText(c.rpeTolerance)}' : ''})'
            '${highestRpe != null ? ': registrado ${_rpeText(highestRpe)}' : ''}',
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
      analyzedSessionIds: [checked.session.sessionId],
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
            'qualidade não marcada não comprovam a meta. Mantenha $loadText.',
        load,
      );
    }
    if (rpeMissing) {
      return result(
        RecommendationStatus.insufficientData,
        'rpeMissing',
        'O RPE não foi registrado em todas as séries avaliadas (o RIR não é '
            'convertido em RPE). Registre-o, ou corrija no histórico, para '
            'receber a sugestão. Por ora, mantenha $loadText.',
        load,
      );
    }
    if (highestRpe! > ceiling) {
      return result(
        RecommendationStatus.maintain,
        'effortAboveTarget',
        'Você fez $repsText com $loadText, com esforço acima do planejado '
            '(RPE ${_rpeText(highestRpe)}; o limite é ${_rpeText(ceiling)}). '
            'Mantenha a carga até o esforço voltar ao alvo.',
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
        'topOfRangeWithinRpe',
        'Você concluiu ${c.sets} séries de ${c.repsMax} repetições com '
            '$loadText e RPE ${_rpeText(highestRpe)}, dentro do planejado. '
            'Suba para ${SessionChecks.describeLoad(next, ex)} e recomece em '
            '${c.repsMin} reps.',
        next,
      );
    }
    if (highestRpe < floor) {
      return result(
        RecommendationStatus.increaseReps,
        'easierThanTarget',
        'Você fez $repsText com $loadText e RPE ${_rpeText(highestRpe)}, '
            'abaixo do planejado. Esforço baixo sozinho não sobe a carga: '
            'busque mais repetições até ${c.repsMax}.',
        load,
      );
    }
    return result(
      RecommendationStatus.increaseReps,
      'withinRange',
      'Você fez $repsText com $loadText e RPE ${_rpeText(highestRpe)}, '
          'dentro do planejado. Mantenha a carga e busque mais repetições '
          'até ${c.repsMax}.',
      load,
    );
  }
}
