import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

/// Critério para considerar a meta de repetições atingida.
enum DoubleProgressionCriterion {
  /// Todas as séries de trabalho chegam ao topo da faixa (padrão).
  allSets,

  /// Só a série principal (identificada pelo número) precisa chegar ao topo;
  /// as demais precisam ao menos do mínimo da faixa.
  mainSet,
}

class DoubleProgressionConfig extends ProgressionConfig {
  final int sets;
  final int repsMin;
  final int repsMax;

  /// RIR-alvo opcional: para subir a carga, as séries que contam para o
  /// critério precisam ter terminado com pelo menos esse RIR.
  final int? targetRir;
  final DoubleProgressionCriterion criterion;

  /// Número (1 = primeira série de trabalho) da série principal, usado com
  /// [DoubleProgressionCriterion.mainSet].
  final int mainSetNumber;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  const DoubleProgressionConfig({
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 12,
    this.targetRir,
    this.criterion = DoubleProgressionCriterion.allSets,
    this.mainSetNumber = 1,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.doubleProgression;

  @override
  bool get usesRir => targetRir != null;

  @override
  Map<String, Object?> toJson() => {
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    if (targetRir != null) 'targetRir': targetRir,
    'criterion': criterion.name,
    'mainSetNumber': mainSetNumber,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory DoubleProgressionConfig.fromJson(Map<String, Object?> json) =>
      DoubleProgressionConfig(
        sets: json['sets'] as int,
        repsMin: json['repsMin'] as int,
        repsMax: json['repsMax'] as int,
        targetRir: json['targetRir'] as int?,
        criterion: DoubleProgressionCriterion.values.byName(
          json['criterion'] as String? ?? 'allSets',
        ),
        mainSetNumber: json['mainSetNumber'] as int? ?? 1,
        rounding: LoadRounding.values.byName(
          json['rounding'] as String? ?? 'nearest',
        ),
        requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
      );

  DoubleProgressionConfig copyWith({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? Function()? targetRir,
    DoubleProgressionCriterion? criterion,
    int? mainSetNumber,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return DoubleProgressionConfig(
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      targetRir: targetRir != null ? targetRir() : this.targetRir,
      criterion: criterion ?? this.criterion,
      mainSetNumber: mainSetNumber ?? this.mainSetNumber,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }

  @override
  String get summary =>
      '$sets × $repsMin–$repsMax${targetRir != null ? ' · RIR $targetRir' : ''}';
}

/// Progressão Dupla: aumenta as repetições dentro da faixa e só então a carga.
///
/// Regras (docs/PROGRESSAO.md, Modo 1):
/// - a carga só sobe quando o critério de topo da faixa é atingido com
///   séries válidas, todas acima do mínimo e, se houver, com o RIR-alvo;
/// - ao subir, a meta recomeça na parte de baixo da faixa;
/// - abaixo do mínimo, a carga é mantida (nunca reduzida automaticamente);
/// - cargas diferentes entre as séries pedem revisão manual, sem presumir
///   qual é a carga de trabalho.
class DoubleProgressionStrategy
    extends ProgressionStrategy<DoubleProgressionConfig> {
  const DoubleProgressionStrategy();

  @override
  StrategyId get id => StrategyId.doubleProgression;

  @override
  String get displayName => 'Progressão Dupla';

  @override
  DoubleProgressionConfig configFromJson(Map<String, Object?> json) =>
      DoubleProgressionConfig.fromJson(json);

  @override
  List<ConfigIssue> validate(DoubleProgressionConfig config) => [
    if (config.sets < 1 || config.sets > 10)
      const ConfigIssue('sets', 'use de 1 a 10 séries'),
    if (config.repsMin < 1)
      const ConfigIssue('repsMin', 'o mínimo precisa ser pelo menos 1'),
    if (config.repsMax > 50)
      const ConfigIssue('repsMax', 'o máximo vai até 50 repetições'),
    if (config.repsMin > config.repsMax)
      const ConfigIssue('repsMax', 'o máximo não pode ser menor que o mínimo'),
    if (config.targetRir != null &&
        (config.targetRir! < 0 || config.targetRir! > 5))
      const ConfigIssue('targetRir', 'RIR-alvo vai de 0 a 5'),
    if (config.criterion == DoubleProgressionCriterion.mainSet &&
        (config.mainSetNumber < 1 || config.mainSetNumber > config.sets))
      ConfigIssue(
        'mainSetNumber',
        'a série principal precisa estar entre 1 e ${config.sets}',
      ),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<DoubleProgressionConfig> input) {
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
    final analyzed = [checked.session.sessionId];
    final repsText = checked.repsText;
    final loadText = SessionChecks.describeLoad(load, ex);

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

    final goalSets = switch (c.criterion) {
      DoubleProgressionCriterion.allSets => considered,
      DoubleProgressionCriterion.mainSet =>
        considered.length >= c.mainSetNumber
            ? [considered[c.mainSetNumber - 1]]
            : const <SetRecord>[],
    };
    final topReached =
        enoughSets &&
        goalSets.isNotEmpty &&
        goalSets.every((s) => (s.reps ?? 0) >= c.repsMax);
    check(
      topReached,
      Criterion(
        'topOfRange',
        c.criterion == DoubleProgressionCriterion.allSets
            ? 'Todas as séries com ${c.repsMax} reps'
            : 'Série principal (${c.mainSetNumber}ª) com ${c.repsMax} reps',
      ),
    );

    var rirMissing = false;
    var rirOk = true;
    if (c.targetRir != null) {
      (missing: rirMissing, ok: rirOk) = SessionChecks.checkRir(
        goalSets,
        c.targetRir!,
      );
      check(
        !rirMissing && rirOk,
        Criterion('targetRir', 'Esforço dentro do RIR-alvo (≥ ${c.targetRir})'),
      );
    }

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
        '${invalid.length} série(s) não comprovam a meta por falha técnica, '
            'execução inválida ou qualidade não marcada. Mantenha $loadText.',
        load,
      );
    }
    if (belowMin.isNotEmpty) {
      return result(
        RecommendationStatus.maintain,
        'belowMinimum',
        'Você fez $repsText com $loadText; ${belowMin.length} série(s) '
            'ficaram abaixo de ${c.repsMin} reps. Mantenha a carga até '
            'firmar a faixa ${c.repsMin}–${c.repsMax}.',
        load,
      );
    }
    if (topReached && rirMissing) {
      return result(
        RecommendationStatus.maintain,
        'rirMissing',
        'Você chegou ao topo da faixa ($repsText com $loadText), mas o RIR '
            'não foi registrado. Registre o RIR para confirmar a progressão.',
        load,
      );
    }
    if (topReached && !rirOk) {
      return result(
        RecommendationStatus.maintain,
        'effortAboveTarget',
        'Você chegou ao topo da faixa ($repsText com $loadText), mas com '
            'esforço acima do planejado (RIR abaixo de ${c.targetRir}). '
            'Mantenha a carga mais uma sessão.',
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
        'topOfRange',
        'Você concluiu ${c.sets} séries de ${c.repsMax} repetições com '
            '$loadText, dentro dos critérios configurados. Suba para '
            '${SessionChecks.describeLoad(next, ex)} e recomece em '
            '${c.repsMin} reps.',
        next,
      );
    }
    return result(
      RecommendationStatus.increaseReps,
      'withinRange',
      'Você fez $repsText com $loadText, dentro da faixa '
          '${c.repsMin}–${c.repsMax}. Mantenha a carga e busque mais '
          'repetições até ${c.repsMax} em todas as séries.',
      load,
    );
  }
}
