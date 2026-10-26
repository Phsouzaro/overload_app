import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';

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
    final fmt = ex.formatLoad;

    if (ex.incrementKg <= 0) {
      return const ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'noIncrement',
        explanation:
            'Defina o incremento de carga disponível para este '
            'exercício para receber sugestões.',
        unmet: [
          Criterion('incrementAvailable', 'Incremento de carga definido'),
        ],
      );
    }
    if (input.history.isEmpty) {
      return const ProgressionResult(
        status: RecommendationStatus.insufficientData,
        reasonCode: 'noHistory',
        explanation: 'Ainda não há sessões registradas deste exercício.',
      );
    }

    final latest = input.history.first;
    final analyzed = [latest.sessionId];
    final working = ProgressionRules.workingSets(latest);
    if (working.isEmpty) {
      return ProgressionResult(
        status: RecommendationStatus.insufficientData,
        reasonCode: 'noWorkingSets',
        explanation:
            'A última sessão não tem séries de trabalho registradas '
            '(só aquecimento ou séries vazias).',
        analyzedSessionIds: analyzed,
      );
    }

    final considered = working.take(c.sets).toList();
    final loads = {for (final s in considered) s.weightKg ?? 0.0};

    List<SetTarget> targetsAt(double weightKg) => [
      for (var i = 0; i < c.sets; i++)
        SetTarget(
          weightKg: _loadOrNull(weightKg, ex),
          repsMin: c.repsMin,
          repsMax: c.repsMax,
          rir: c.targetRir,
        ),
    ];

    if (loads.length > 1) {
      final described = [for (final s in considered) fmt(s.weightKg ?? 0)];
      return ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'mixedLoads',
        explanation:
            'As séries usaram cargas diferentes '
            '(${described.join(' / ')}). Escolha a carga de trabalho para a '
            'próxima sessão.',
        unmet: const [
          Criterion('sameLoad', 'Mesma carga em todas as séries de trabalho'),
        ],
        analyzedSessionIds: analyzed,
        nextTargets: [
          for (final s in considered)
            SetTarget(
              weightKg: s.weightKg,
              repsMin: c.repsMin,
              repsMax: c.repsMax,
              rir: c.targetRir,
            ),
        ],
      );
    }

    final load = loads.single;
    final repsText = considered.map((s) => s.reps ?? 0).join('/');
    final loadText = _describeLoad(load, ex);

    if (ProgressionRules.isLongBreak(input.history, input.now)) {
      final days = ProgressionRules.daysSinceLastSession(
        input.history,
        input.now,
      );
      return ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'longBreak',
        explanation:
            'Faz $days dias desde a última sessão deste exercício. '
            'Retome com a carga anterior ($loadText) ou menor, conforme se '
            'sentir, antes de voltar a progredir.',
        unmet: const [
          Criterion(
            'recentHistory',
            'Sessão recente (até ${ProgressionRules.longBreakDays} dias)',
          ),
        ],
        currentWeightKg: load,
        analyzedSessionIds: analyzed,
        nextTargets: targetsAt(load),
      );
    }

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

    final invalid = [
      for (final s in considered)
        if (!ProgressionRules.countsTowardGoal(
          s,
          requireMarkedValid: c.requireMarkedValid,
        ))
          s,
    ];
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
      for (final s in goalSets) {
        final rir = s.toFailure ? 0 : s.rir;
        if (rir == null) {
          rirMissing = true;
        } else if (rir < c.targetRir!) {
          rirOk = false;
        }
      }
      check(
        !rirMissing && rirOk,
        Criterion('targetRir', 'Esforço dentro do RIR-alvo (≥ ${c.targetRir})'),
      );
    }

    final qualityNote =
        !c.requireMarkedValid &&
            ProgressionRules.hasUnrecordedQuality(considered)
        ? ' A qualidade da execução não foi marcada, então as séries foram '
              'consideradas válidas.'
        : '';

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
            '${_describeLoad(next, ex)} e recomece em ${c.repsMin} reps.',
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

  /// Em peso corporal, carga 0 é "sem carga extra" (`null`).
  static double? _loadOrNull(double kg, ExerciseContext ex) =>
      ex.loadType == ExerciseLoadType.bodyweight && kg == 0 ? null : kg;

  static String _describeLoad(double kg, ExerciseContext ex) {
    if (ex.loadType == ExerciseLoadType.bodyweight) {
      return kg == 0 ? 'peso corporal' : 'peso corporal + ${ex.formatLoad(kg)}';
    }
    return ex.formatLoad(kg);
  }
}
