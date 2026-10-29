import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

/// "8", "8,5".
String _num(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(1).replaceAll('.', ',');

class TopSetBackOffConfig extends ProgressionConfig {
  /// Faixa de repetições da série principal (top set).
  final int topRepsMin;
  final int topRepsMax;

  /// Esforço opcional exigido na série principal para subir a carga dela.
  final int? topTargetRir;
  final double? topTargetRpe;

  final int backOffSets;

  /// Redução das séries de back-off em relação à série principal (%).
  final int backOffPercent;
  final int backOffRepsMin;
  final int backOffRepsMax;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  const TopSetBackOffConfig({
    this.topRepsMin = 4,
    this.topRepsMax = 6,
    this.topTargetRir,
    this.topTargetRpe,
    this.backOffSets = 3,
    this.backOffPercent = 15,
    this.backOffRepsMin = 6,
    this.backOffRepsMax = 8,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.topSetBackOff;

  @override
  bool get usesRir => topTargetRir != null;

  @override
  bool get usesRpe => topTargetRpe != null;

  @override
  String get summary =>
      '1 × $topRepsMin–$topRepsMax + $backOffSets × '
      '$backOffRepsMin–$backOffRepsMax (−$backOffPercent%)';

  @override
  Map<String, Object?> toJson() => {
    'topRepsMin': topRepsMin,
    'topRepsMax': topRepsMax,
    if (topTargetRir != null) 'topTargetRir': topTargetRir,
    if (topTargetRpe != null) 'topTargetRpe': topTargetRpe,
    'backOffSets': backOffSets,
    'backOffPercent': backOffPercent,
    'backOffRepsMin': backOffRepsMin,
    'backOffRepsMax': backOffRepsMax,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory TopSetBackOffConfig.fromJson(Map<String, Object?> json) =>
      TopSetBackOffConfig(
        topRepsMin: json['topRepsMin'] as int,
        topRepsMax: json['topRepsMax'] as int,
        topTargetRir: json['topTargetRir'] as int?,
        topTargetRpe: (json['topTargetRpe'] as num?)?.toDouble(),
        backOffSets: json['backOffSets'] as int,
        backOffPercent: json['backOffPercent'] as int,
        backOffRepsMin: json['backOffRepsMin'] as int,
        backOffRepsMax: json['backOffRepsMax'] as int,
        rounding: LoadRounding.values.byName(
          json['rounding'] as String? ?? 'nearest',
        ),
        requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
      );

  TopSetBackOffConfig copyWith({
    int? topRepsMin,
    int? topRepsMax,
    int? Function()? topTargetRir,
    double? Function()? topTargetRpe,
    int? backOffSets,
    int? backOffPercent,
    int? backOffRepsMin,
    int? backOffRepsMax,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return TopSetBackOffConfig(
      topRepsMin: topRepsMin ?? this.topRepsMin,
      topRepsMax: topRepsMax ?? this.topRepsMax,
      topTargetRir: topTargetRir != null ? topTargetRir() : this.topTargetRir,
      topTargetRpe: topTargetRpe != null ? topTargetRpe() : this.topTargetRpe,
      backOffSets: backOffSets ?? this.backOffSets,
      backOffPercent: backOffPercent ?? this.backOffPercent,
      backOffRepsMin: backOffRepsMin ?? this.backOffRepsMin,
      backOffRepsMax: backOffRepsMax ?? this.backOffRepsMax,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }
}

/// Série principal + séries de redução.
///
/// É uma **estrutura** de treino com duas políticas de progressão
/// independentes, ambas no formato da Progressão Dupla (docs/PROGRESSAO.md,
/// Modo 5):
/// - série principal: sobe quando chega ao topo da sua faixa (com o esforço
///   opcional atendido);
/// - back-off: calculado como percentual da série principal e arredondado ao
///   incremento do equipamento; acompanha a série principal quando ela sobe,
///   sobe sozinho quando todas as séries de back-off chegam ao topo da faixa
///   delas, e nunca sobe se alguma ficar abaixo do mínimo.
///
/// A redução planejada do back-off não é tratada como regressão: a regra de
/// "cargas diferentes" das outras estratégias não se aplica aqui.
class TopSetBackOffStrategy extends ProgressionStrategy<TopSetBackOffConfig> {
  const TopSetBackOffStrategy();

  @override
  StrategyId get id => StrategyId.topSetBackOff;

  @override
  String get displayName => 'Série Principal + Back-off';

  @override
  bool supportsLoadType(ExerciseLoadType type) =>
      type == ExerciseLoadType.weighted;

  @override
  TopSetBackOffConfig configFromJson(Map<String, Object?> json) =>
      TopSetBackOffConfig.fromJson(json);

  @override
  List<ConfigIssue> validate(TopSetBackOffConfig c) => [
    if (c.topRepsMin < 1) const ConfigIssue('topRepsMin', 'mínimo de 1 rep'),
    if (c.topRepsMax > 20)
      const ConfigIssue('topRepsMax', 'a série principal vai até 20 reps'),
    if (c.topRepsMin > c.topRepsMax)
      const ConfigIssue(
        'topRepsMax',
        'o máximo não pode ser menor que o mínimo',
      ),
    if (c.backOffSets < 1 || c.backOffSets > 6)
      const ConfigIssue('backOffSets', 'use de 1 a 6 séries de back-off'),
    if (c.backOffPercent < 5 || c.backOffPercent > 40)
      const ConfigIssue('backOffPercent', 'a redução vai de 5% a 40%'),
    if (c.backOffRepsMin < 1)
      const ConfigIssue('backOffRepsMin', 'mínimo de 1 rep'),
    if (c.backOffRepsMax > 30)
      const ConfigIssue('backOffRepsMax', 'o back-off vai até 30 reps'),
    if (c.backOffRepsMin > c.backOffRepsMax)
      const ConfigIssue(
        'backOffRepsMax',
        'o máximo não pode ser menor que o mínimo',
      ),
    if (c.topTargetRir != null && (c.topTargetRir! < 0 || c.topTargetRir! > 5))
      const ConfigIssue('topTargetRir', 'RIR-alvo vai de 0 a 5'),
    if (c.topTargetRpe != null &&
        (c.topTargetRpe! < 6 ||
            c.topTargetRpe! > 10 ||
            c.topTargetRpe! * 2 != (c.topTargetRpe! * 2).roundToDouble()))
      const ConfigIssue(
        'topTargetRpe',
        'RPE-alvo vai de 6 a 10, passos de 0,5',
      ),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<TopSetBackOffConfig> input) {
    final c = input.config;
    final ex = input.exercise;
    final fmt = ex.formatLoad;

    if (ex.loadType != ExerciseLoadType.weighted) {
      return const ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'unsupportedLoadType',
        explanation:
            'Série principal + back-off precisa de carga externa: o back-off '
            'é um percentual da carga da série principal.',
      );
    }
    final basic = SessionChecks.basics(input);
    if (basic != null) return basic;

    final latest = input.history.first;
    final analyzed = [latest.sessionId];
    final working = ProgressionRules.workingSets(latest);

    // 1. Identificar a série principal explicitamente.
    final split = _split(working);
    if (split == null) {
      return ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'topSetNotIdentified',
        explanation:
            'Não foi possível identificar a série principal: todas as séries '
            'usaram a mesma carga e nenhuma foi marcada como principal. Aceite '
            'ou ajuste uma sugestão para o app montar a estrutura.',
        unmet: const [
          Criterion('topSetIdentified', 'Série principal identificada'),
        ],
        analyzedSessionIds: analyzed,
      );
    }
    final (top: topSet, backOffs: backOffSets) = split;
    final topLoad = topSet.weightKg ?? 0;
    final backOffLoad = backOffSets.isEmpty
        ? null
        : backOffSets
              .map((s) => s.weightKg ?? 0)
              .reduce((a, b) => a < b ? a : b);

    double backOffFor(double top) => ProgressionRules.roundToIncrement(
      top * (1 - c.backOffPercent / 100),
      ex.incrementKg,
      mode: c.rounding,
    );
    List<SetTarget> targets(double top, double backOff) => [
      SetTarget(
        role: SetRole.topSet,
        weightKg: top,
        repsMin: c.topRepsMin,
        repsMax: c.topRepsMax,
        rir: c.topTargetRir,
        rpe: c.topTargetRpe,
      ),
      for (var i = 0; i < c.backOffSets; i++)
        SetTarget(
          role: SetRole.backOff,
          weightKg: backOff,
          repsMin: c.backOffRepsMin,
          repsMax: c.backOffRepsMax,
        ),
    ];

    final pause = SessionChecks.longBreak(
      input,
      loadText: fmt(topLoad),
      currentWeightKg: topLoad,
      targets: targets(topLoad, backOffLoad ?? backOffFor(topLoad)),
    );
    if (pause != null) return pause;

    final met = <Criterion>[];
    final unmet = <Criterion>[];
    void check(bool ok, Criterion criterion) =>
        (ok ? met : unmet).add(criterion);

    // 2. Série principal: Progressão Dupla na faixa dela.
    final topReps = topSet.reps ?? 0;
    final topValid = ProgressionRules.countsTowardGoal(
      topSet,
      requireMarkedValid: c.requireMarkedValid,
    );
    check(
      topValid,
      const Criterion('topSetValid', 'Série principal com execução válida'),
    );
    final topAtTop = topReps >= c.topRepsMax;
    check(
      topAtTop,
      Criterion(
        'topSetAtTop',
        'Série principal com ${c.topRepsMax} reps (feitas: $topReps)',
      ),
    );
    var effortMissing = false;
    var effortOk = true;
    if (c.topTargetRir != null) {
      final rir = SessionChecks.checkRir([topSet], c.topTargetRir!);
      effortMissing |= rir.missing;
      effortOk &= rir.ok;
    }
    if (c.topTargetRpe != null) {
      final rpe = topSet.toFailure ? 10.0 : topSet.rpe;
      if (rpe == null) {
        effortMissing = true;
      } else if (rpe > c.topTargetRpe!) {
        effortOk = false;
      }
    }
    if (c.topTargetRir != null || c.topTargetRpe != null) {
      check(
        !effortMissing && effortOk,
        Criterion(
          'topSetEffort',
          'Esforço da série principal dentro do alvo'
              '${c.topTargetRir != null ? ' (RIR ≥ ${c.topTargetRir})' : ''}'
              '${c.topTargetRpe != null ? ' (RPE ≤ ${_num(c.topTargetRpe!)})' : ''}',
        ),
      );
    }
    final topUp = topValid && topAtTop && !effortMissing && effortOk;
    final nextTop = topUp
        ? ProgressionRules.roundToIncrement(
            topLoad + ex.incrementKg,
            ex.incrementKg,
            mode: c.rounding,
          )
        : topLoad;

    // 3. Back-off: política própria, ligada ao percentual da principal.
    final follow = backOffFor(nextTop);
    final hold = backOffLoad ?? follow;
    final backOffDone = backOffSets.length >= c.backOffSets;
    final backOffInvalid = SessionChecks.invalidSets(
      backOffSets,
      requireMarkedValid: c.requireMarkedValid,
    );
    final backOffBelowMin = backOffSets.any(
      (s) => (s.reps ?? 0) < c.backOffRepsMin,
    );
    final backOffAtTop =
        backOffDone &&
        backOffSets.every((s) => (s.reps ?? 0) >= c.backOffRepsMax);
    check(
      backOffDone,
      Criterion(
        'backOffCompleted',
        '${c.backOffSets} séries de back-off (${backOffSets.length} feitas)',
      ),
    );
    check(
      backOffInvalid.isEmpty,
      const Criterion('backOffValid', 'Back-off com execução válida'),
    );
    check(
      !backOffBelowMin,
      Criterion(
        'backOffMinimum',
        'Back-off com ao menos ${c.backOffRepsMin} reps',
      ),
    );
    check(
      backOffAtTop,
      Criterion('backOffAtTop', 'Todo o back-off com ${c.backOffRepsMax} reps'),
    );

    final double nextBackOff;
    if (!backOffDone || backOffInvalid.isNotEmpty || backOffBelowMin) {
      nextBackOff = follow < hold ? follow : hold; // nunca sobe
    } else if (backOffAtTop) {
      final up = ProgressionRules.roundToIncrement(
        hold + ex.incrementKg,
        ex.incrementKg,
        mode: c.rounding,
      );
      nextBackOff = follow > up ? follow : up;
    } else {
      nextBackOff = topUp && follow > hold ? follow : hold;
    }
    final backOffUp = nextBackOff > hold;
    // Subiu pela meta própria (topo da faixa do back-off), e não só por
    // acompanhar o percentual da principal.
    final backOffOwnUp =
        backOffUp && backOffAtTop && backOffInvalid.isEmpty && !backOffBelowMin;

    // 4. Resultado e justificativa, uma frase por trilha.
    final topText = !topValid
        ? 'Série principal: ${fmt(topLoad)} × $topReps não conta (falha '
              'técnica, execução inválida ou qualidade não marcada); mantenha.'
        : topUp
        ? 'Série principal: ${fmt(topLoad)} × $topReps, no topo da faixa '
              '${c.topRepsMin}–${c.topRepsMax}. Suba para ${fmt(nextTop)}.'
        : topAtTop && effortMissing
        ? 'Série principal: ${fmt(topLoad)} × $topReps no topo, mas falta '
              'registrar o esforço; mantenha.'
        : topAtTop
        ? 'Série principal: ${fmt(topLoad)} × $topReps no topo, com esforço '
              'acima do alvo; mantenha.'
        : 'Série principal: ${fmt(topLoad)} × $topReps; mantenha e busque '
              '${c.topRepsMax} reps.';
    final backOffReps = backOffSets.map((s) => s.reps ?? 0).join('/');
    final backOffText = backOffSets.isEmpty
        ? 'Back-off: nenhuma série registrada; sugestão de '
              '${fmt(nextBackOff)} (−${c.backOffPercent}%).'
        : backOffOwnUp
        ? 'Back-off: $backOffReps com ${fmt(hold)}, no topo da faixa. '
              'Próximo: ${fmt(nextBackOff)}.'
        : backOffUp
        ? 'Back-off: $backOffReps com ${fmt(hold)}; acompanha a principal '
              '(−${c.backOffPercent}%): ${fmt(nextBackOff)}.'
        : (!backOffDone || backOffInvalid.isNotEmpty || backOffBelowMin)
        ? 'Back-off: $backOffReps com ${fmt(hold)} ficou abaixo da meta; '
              'mantenha ${fmt(nextBackOff)}.'
        : 'Back-off: $backOffReps com ${fmt(hold)}; mantenha e busque '
              '${c.backOffRepsMax} reps.';

    final status = (topUp || backOffUp)
        ? RecommendationStatus.increaseWeight
        : (!topValid ||
              backOffInvalid.isNotEmpty ||
              backOffBelowMin ||
              !backOffDone ||
              topReps < c.topRepsMin)
        ? RecommendationStatus.maintain
        : RecommendationStatus.increaseReps;
    final reason = topUp && backOffOwnUp
        ? 'bothUp'
        : topUp
        ? 'topSetUp'
        : backOffOwnUp
        ? 'backOffUp'
        : status == RecommendationStatus.maintain
        ? 'hold'
        : 'withinRange';

    return ProgressionResult(
      status: status,
      reasonCode: reason,
      explanation:
          '$topText $backOffText'
          '${SessionChecks.qualityNote([topSet, ...backOffSets], requireMarkedValid: c.requireMarkedValid)}',
      met: met,
      unmet: unmet,
      currentWeightKg: topLoad,
      analyzedSessionIds: analyzed,
      nextTargets: targets(nextTop, nextBackOff),
      state: {'backOffKg': nextBackOff},
    );
  }

  /// Separa a série principal do back-off. Usa o papel marcado nas séries
  /// (metas aceitas); sem esses papéis (ou com papéis de outra estrutura,
  /// após trocar de estratégia), a principal é a primeira série com a maior
  /// carga e o back-off são as séries mais leves. Todas com a mesma carga e
  /// sem papel: não dá para identificar (`null`).
  static ({SetRecord top, List<SetRecord> backOffs})? _split(
    List<SetRecord> working,
  ) {
    if (working.any(
      (s) => s.role == SetRole.topSet || s.role == SetRole.backOff,
    )) {
      final top = working.where((s) => s.role == SetRole.topSet).firstOrNull;
      if (top == null) return null;
      return (
        top: top,
        backOffs: [
          for (final s in working)
            if (s.role == SetRole.backOff) s,
        ],
      );
    }
    final heaviest = working
        .map((s) => s.weightKg ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final lighter = [
      for (final s in working)
        if ((s.weightKg ?? 0) < heaviest) s,
    ];
    if (lighter.isEmpty) return null;
    return (
      top: working.firstWhere((s) => (s.weightKg ?? 0) == heaviest),
      backOffs: lighter,
    );
  }
}
