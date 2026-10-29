import '../progression_enums.dart';
import '../progression_models.dart';
import '../progression_rules.dart';
import '../progression_strategy.dart';
import '../session_checks.dart';

/// Uma série planejada dentro de uma onda: repetições e percentual da carga
/// de referência (100%).
class WaveStep {
  final int reps;
  final double percent;

  const WaveStep({required this.reps, required this.percent});

  Map<String, Object?> toJson() => {'reps': reps, 'percent': percent};

  factory WaveStep.fromJson(Map<String, Object?> json) => WaveStep(
    reps: json['reps'] as int,
    percent: (json['percent'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is WaveStep && other.reps == reps && other.percent == percent;

  @override
  int get hashCode => Object.hash(reps, percent);
}

/// O que fazer quando uma série da onda tem falha técnica. Gravado pelo nome
/// no JSON da config.
enum TechnicalFailurePolicy {
  /// A onda é interrompida e repetida na próxima sessão.
  repeatWave,

  /// A sequência é interrompida e o ciclo recomeça pela primeira onda, com a
  /// mesma referência.
  restartCycle,
}

class WaveLoadingConfig extends ProgressionConfig {
  /// Ondas na ordem do ciclo. Cada onda é uma sessão, com as séries na ordem
  /// planejada; as ondas não precisam ser iguais entre si.
  final List<List<WaveStep>> waves;

  /// Carga de referência (100%) do primeiro ciclo, em kg. `null` = deduzir
  /// da última sessão, para a primeira onda começar na carga já usada.
  final double? baseKg;

  /// Quantos incrementos a referência sobe a cada ciclo concluído.
  final int cycleIncrements;

  /// Tentativas seguidas sem concluir a mesma onda antes de pedir revisão.
  final int failureTolerance;
  final TechnicalFailurePolicy onTechnicalFailure;
  final LoadRounding rounding;
  @override
  final bool requireMarkedValid;

  static const defaultWaves = [
    [
      WaveStep(reps: 8, percent: 75),
      WaveStep(reps: 8, percent: 75),
      WaveStep(reps: 8, percent: 75),
    ],
    [
      WaveStep(reps: 6, percent: 80),
      WaveStep(reps: 6, percent: 80),
      WaveStep(reps: 6, percent: 80),
    ],
    [
      WaveStep(reps: 4, percent: 85),
      WaveStep(reps: 4, percent: 85),
      WaveStep(reps: 4, percent: 85),
    ],
  ];

  const WaveLoadingConfig({
    this.waves = defaultWaves,
    this.baseKg,
    this.cycleIncrements = 1,
    this.failureTolerance = 2,
    this.onTechnicalFailure = TechnicalFailurePolicy.repeatWave,
    this.rounding = LoadRounding.nearest,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.waveLoading;

  /// Ex: "3×8 → 3×6 → 3×4" ou "8/6/4" para uma onda com reps diferentes.
  @override
  String get summary => waves.map(describeWave).join(' → ');

  static String describeWave(List<WaveStep> wave) {
    if (wave.isEmpty) return '—';
    final reps = wave.first.reps;
    return wave.every((s) => s.reps == reps)
        ? '${wave.length}×$reps'
        : wave.map((s) => s.reps).join('/');
  }

  @override
  Map<String, Object?> toJson() => {
    'waves': [
      for (final w in waves) [for (final s in w) s.toJson()],
    ],
    if (baseKg != null) 'baseKg': baseKg,
    'cycleIncrements': cycleIncrements,
    'failureTolerance': failureTolerance,
    'onTechnicalFailure': onTechnicalFailure.name,
    'rounding': rounding.name,
    'requireMarkedValid': requireMarkedValid,
  };

  factory WaveLoadingConfig.fromJson(Map<String, Object?> json) =>
      WaveLoadingConfig(
        waves: [
          for (final w in json['waves'] as List)
            [
              for (final s in w as List)
                WaveStep.fromJson((s as Map).cast<String, Object?>()),
            ],
        ],
        baseKg: (json['baseKg'] as num?)?.toDouble(),
        cycleIncrements: json['cycleIncrements'] as int? ?? 1,
        failureTolerance: json['failureTolerance'] as int? ?? 2,
        onTechnicalFailure: TechnicalFailurePolicy.values.byName(
          json['onTechnicalFailure'] as String? ?? 'repeatWave',
        ),
        rounding: LoadRounding.values.byName(
          json['rounding'] as String? ?? 'nearest',
        ),
        requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
      );

  WaveLoadingConfig copyWith({
    List<List<WaveStep>>? waves,
    double? Function()? baseKg,
    int? cycleIncrements,
    int? failureTolerance,
    TechnicalFailurePolicy? onTechnicalFailure,
    LoadRounding? rounding,
    bool? requireMarkedValid,
  }) {
    return WaveLoadingConfig(
      waves: waves ?? this.waves,
      baseKg: baseKg != null ? baseKg() : this.baseKg,
      cycleIncrements: cycleIncrements ?? this.cycleIncrements,
      failureTolerance: failureTolerance ?? this.failureTolerance,
      onTechnicalFailure: onTechnicalFailure ?? this.onTechnicalFailure,
      rounding: rounding ?? this.rounding,
      requireMarkedValid: requireMarkedValid ?? this.requireMarkedValid,
    );
  }
}

/// Resultado de uma tentativa de onda.
enum WaveOutcome { completed, failed, incomplete, interrupted }

/// Posição no ciclo, persistida em `ProgressionResult.state`.
class WaveState {
  final int cycle;

  /// Índice (0-based) da onda planejada para a próxima sessão.
  final int wave;
  final double baseKg;

  /// Tentativas seguidas sem concluir a onda atual.
  final int failStreak;

  /// Resultados por onda, mais antigo primeiro (limitado a [historyLimit]).
  final List<Map<String, Object?>> results;

  static const historyLimit = 12;

  const WaveState({
    required this.cycle,
    required this.wave,
    required this.baseKg,
    this.failStreak = 0,
    this.results = const [],
  });

  /// `null` quando não há ciclo em andamento (primeira avaliação da config).
  static WaveState? fromJson(Map<String, Object?> json) {
    final base = (json['baseKg'] as num?)?.toDouble();
    if (base == null) return null;
    return WaveState(
      cycle: json['cycle'] as int? ?? 1,
      wave: json['wave'] as int? ?? 0,
      baseKg: base,
      failStreak: json['failStreak'] as int? ?? 0,
      results: [
        for (final r in json['results'] as List? ?? const [])
          (r as Map).cast<String, Object?>(),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'cycle': cycle,
    'wave': wave,
    'baseKg': baseKg,
    'failStreak': failStreak,
    'results': results,
  };
}

/// Progressão em ondas (docs/PROGRESSAO.md, Modo 6).
///
/// O ciclo é uma sequência de ondas configuráveis, uma por sessão, cada uma
/// com séries, repetições e percentuais próprios sobre a carga de referência.
/// A posição no ciclo fica no estado da recomendação:
/// - onda concluída (todas as séries com a carga e as reps planejadas, com
///   execução válida) avança para a próxima;
/// - onda malsucedida é repetida: a intensidade nunca sobe depois dela;
/// - falha técnica interrompe a onda (repete) ou o ciclo (recomeça), conforme
///   a config;
/// - a última onda concluída fecha o ciclo e sobe a referência.
class WaveLoadingStrategy extends ProgressionStrategy<WaveLoadingConfig> {
  const WaveLoadingStrategy();

  @override
  StrategyId get id => StrategyId.waveLoading;

  @override
  String get displayName => 'Progressão em Ondas';

  @override
  bool supportsLoadType(ExerciseLoadType type) =>
      type == ExerciseLoadType.weighted;

  @override
  WaveLoadingConfig configFromJson(Map<String, Object?> json) =>
      WaveLoadingConfig.fromJson(json);

  @override
  List<ConfigIssue> validate(WaveLoadingConfig c) => [
    if (c.waves.isEmpty || c.waves.length > 6)
      const ConfigIssue('waves', 'use de 1 a 6 ondas'),
    for (var w = 0; w < c.waves.length; w++) ...[
      if (c.waves[w].isEmpty || c.waves[w].length > 8)
        ConfigIssue('waves', 'onda ${w + 1}: use de 1 a 8 séries'),
      for (var s = 0; s < c.waves[w].length; s++) ...[
        if (c.waves[w][s].reps < 1 || c.waves[w][s].reps > 30)
          ConfigIssue(
            'waves',
            'onda ${w + 1}, série ${s + 1}: repetições de 1 a 30',
          ),
        if (c.waves[w][s].percent < 30 ||
            c.waves[w][s].percent > 120 ||
            c.waves[w][s].percent * 2 !=
                (c.waves[w][s].percent * 2).roundToDouble())
          ConfigIssue(
            'waves',
            'onda ${w + 1}, série ${s + 1}: percentual de 30% a 120%, '
                'em passos de 0,5',
          ),
      ],
    ],
    if (c.baseKg != null && c.baseKg! <= 0)
      const ConfigIssue('baseKg', 'a carga de referência deve ser maior que 0'),
    if (c.cycleIncrements < 1 || c.cycleIncrements > 5)
      const ConfigIssue('cycleIncrements', 'suba de 1 a 5 incrementos por ciclo'),
    if (c.failureTolerance < 1 || c.failureTolerance > 5)
      const ConfigIssue('failureTolerance', 'tolere de 1 a 5 tentativas'),
  ];

  /// Metas da onda [wave] com a referência [baseKg], na ordem planejada.
  static List<SetTarget> planFor(
    WaveLoadingConfig c,
    int wave,
    double baseKg,
    double incrementKg,
  ) => [
    for (final s in c.waves[wave])
      SetTarget(
        role: SetRole.wave,
        weightKg: ProgressionRules.roundToIncrement(
          baseKg * s.percent / 100,
          incrementKg,
          mode: c.rounding,
        ),
        repsMin: s.reps,
        repsMax: s.reps,
      ),
  ];

  /// Referência que faz a primeira onda começar em [loadKg]: a carga mais
  /// pesada dela corresponde a [loadKg].
  static double inferBase(WaveLoadingConfig c, double loadKg, double inc) {
    final top = c.waves.first
        .map((s) => s.percent)
        .reduce((a, b) => a > b ? a : b);
    return ProgressionRules.roundToIncrement(loadKg * 100 / top, inc);
  }

  @override
  ProgressionResult evaluate(ProgressionInput<WaveLoadingConfig> input) {
    final c = input.config;
    final ex = input.exercise;
    final fmt = ex.formatLoad;
    final inc = ex.incrementKg;
    final n = c.waves.length;

    if (ex.loadType != ExerciseLoadType.weighted) {
      return const ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'unsupportedLoadType',
        explanation:
            'A progressão em ondas precisa de carga externa: as cargas são '
            'percentuais da carga de referência.',
      );
    }

    final prev = WaveState.fromJson(input.previousState);
    final basic = SessionChecks.basics(input);
    if (basic != null) return _keep(basic, prev);

    final latest = input.history.first;
    final analyzed = [latest.sessionId];
    final working = ProgressionRules.workingSets(latest);
    final heaviest = working
        .map((s) => s.weightKg ?? 0)
        .reduce((a, b) => a > b ? a : b);

    String describePlan(List<SetTarget> plan) => plan
        .map((t) => '${fmt(t.weightKg!)} × ${t.repsMin}')
        .join(', ');
    String waveName(int w, int cycle) => 'onda ${w + 1} de $n (ciclo $cycle)';

    /// Valida as cargas planejadas: arredondadas ao incremento, nenhuma pode
    /// ficar zerada.
    ProgressionResult? invalidLoads(int w, double base, WaveState? state) {
      final plan = planFor(c, w, base, inc);
      if (plan.every((t) => t.weightKg! > 0)) return null;
      return ProgressionResult(
        status: RecommendationStatus.manualReview,
        reasonCode: 'invalidLoads',
        explanation:
            'Com a referência de ${fmt(base)} e o incremento de ${fmt(inc)}, '
            'a onda ${w + 1} teria séries sem carga. Revise os percentuais ou '
            'a carga de referência.',
        unmet: const [
          Criterion('validLoads', 'Cargas planejadas maiores que zero'),
        ],
        analyzedSessionIds: analyzed,
        state: state?.toJson() ?? const {},
      );
    }

    // 1. Sem ciclo em andamento: começa pela primeira onda.
    if (prev == null) {
      if (c.baseKg == null && heaviest <= 0) {
        return ProgressionResult(
          status: RecommendationStatus.insufficientData,
          reasonCode: 'noLoad',
          explanation:
              'A última sessão não tem carga registrada. Registre a carga ou '
              'defina a carga de referência para começar o ciclo.',
          analyzedSessionIds: analyzed,
        );
      }
      final base = c.baseKg ?? inferBase(c, heaviest, inc);
      final state = WaveState(cycle: 1, wave: 0, baseKg: base);
      final bad = invalidLoads(0, base, null);
      if (bad != null) return bad;
      final plan = planFor(c, 0, base, inc);
      final origin = c.baseKg != null
          ? 'definida na configuração'
          : 'calculada a partir de ${fmt(heaviest)} da última sessão';
      return ProgressionResult(
        status: RecommendationStatus.maintain,
        reasonCode: 'cycleStart',
        explanation:
            'Início do ciclo de ondas, pela ${waveName(0, 1)}. Referência '
            '(100%): ${fmt(base)}, $origin. Planejado: ${describePlan(plan)}.',
        currentWeightKg: heaviest,
        analyzedSessionIds: analyzed,
        nextTargets: plan,
        state: state.toJson(),
      );
    }

    final w = prev.wave.clamp(0, n - 1);
    final base = prev.baseKg;
    final bad = invalidLoads(w, base, prev);
    if (bad != null) return bad;
    final plan = planFor(c, w, base, inc);
    final planMax = plan.map((t) => t.weightKg!).reduce((a, b) => a > b ? a : b);

    final pause = SessionChecks.longBreak(
      input,
      loadText: fmt(planMax),
      currentWeightKg: heaviest,
      targets: plan,
    );
    if (pause != null) return _keep(pause, prev);

    // 2. Resultado da onda, série por série, na ordem planejada.
    final waveSets = working.any((s) => s.role == SetRole.wave)
        ? working.where((s) => s.role == SetRole.wave).toList()
        : working;
    final done = waveSets.take(plan.length).toList();

    final met = <Criterion>[];
    final unmet = <Criterion>[];
    final problems = <String>[];
    int? interruptedAt;
    for (var i = 0; i < plan.length; i++) {
      final t = plan[i];
      final planned = '${fmt(t.weightKg!)} × ${t.repsMin}';
      if (i >= done.length) {
        unmet.add(
          Criterion('step${i + 1}', 'Série ${i + 1}: $planned (não feita)'),
        );
        continue;
      }
      final s = done[i];
      final load = s.weightKg ?? 0;
      final reps = s.reps ?? 0;
      final loadOk = load >= t.weightKg! - 1e-6;
      final repsOk = reps >= t.repsMin!;
      final valid = ProgressionRules.countsTowardGoal(
        s,
        requireMarkedValid: c.requireMarkedValid,
      );
      final ok = loadOk && repsOk && valid;
      (ok ? met : unmet).add(
        Criterion(
          'step${i + 1}',
          'Série ${i + 1}: ${fmt(load)} × $reps (planejado: $planned)',
        ),
      );
      if (s.quality == ExecutionQuality.technicalFailure) {
        interruptedAt ??= i;
      } else if (!valid) {
        problems.add('série ${i + 1} sem execução válida');
      } else if (!loadOk) {
        problems.add(
          'série ${i + 1} com ${fmt(load)} (planejado ${fmt(t.weightKg!)})',
        );
      } else if (!repsOk) {
        problems.add('série ${i + 1} com $reps reps (meta ${t.repsMin})');
      }
    }

    final outcome = interruptedAt != null
        ? WaveOutcome.interrupted
        : done.length < plan.length
        ? WaveOutcome.incomplete
        : unmet.isEmpty
        ? WaveOutcome.completed
        : WaveOutcome.failed;

    final results = [
      ...prev.results,
      {
        'cycle': prev.cycle,
        'wave': w,
        'outcome': outcome.name,
        'sessionId': latest.sessionId,
      },
    ];
    final trimmed = results.length > WaveState.historyLimit
        ? results.sublist(results.length - WaveState.historyLimit)
        : results;
    final quality = SessionChecks.qualityNote(
      done,
      requireMarkedValid: c.requireMarkedValid,
    );
    final current = waveName(w, prev.cycle);

    ProgressionResult result(
      RecommendationStatus status,
      String reason,
      String explanation,
      WaveState next,
    ) => ProgressionResult(
      status: status,
      reasonCode: reason,
      explanation: explanation + quality,
      met: met,
      unmet: unmet,
      currentWeightKg: heaviest,
      analyzedSessionIds: analyzed,
      nextTargets: planFor(c, next.wave, next.baseKg, inc),
      state: WaveState(
        cycle: next.cycle,
        wave: next.wave,
        baseKg: next.baseKg,
        failStreak: next.failStreak,
        results: trimmed,
      ).toJson(),
    );

    // 3. Transições do ciclo.
    if (outcome == WaveOutcome.completed) {
      if (w < n - 1) {
        final next = WaveState(cycle: prev.cycle, wave: w + 1, baseKg: base);
        final nextMax = planFor(
          c,
          w + 1,
          base,
          inc,
        ).map((t) => t.weightKg!).reduce((a, b) => a > b ? a : b);
        return result(
          nextMax > planMax
              ? RecommendationStatus.increaseWeight
              : RecommendationStatus.maintain,
          'waveCompleted',
          'Você concluiu a $current: ${describePlan(plan)}. Avance para a '
              '${waveName(w + 1, prev.cycle)}.',
          next,
        );
      }
      final nextBase = ProgressionRules.roundToIncrement(
        base + inc * c.cycleIncrements,
        inc,
        mode: c.rounding,
      );
      return result(
        RecommendationStatus.increaseWeight,
        'cycleCompleted',
        'Ciclo ${prev.cycle} concluído: as $n ondas foram completas. A '
            'referência sobe de ${fmt(base)} para ${fmt(nextBase)} e o ciclo '
            '${prev.cycle + 1} recomeça pela onda 1.',
        WaveState(cycle: prev.cycle + 1, wave: 0, baseKg: nextBase),
      );
    }

    if (outcome == WaveOutcome.incomplete) {
      return result(
        RecommendationStatus.maintain,
        'waveIncomplete',
        'Foram registradas ${done.length} de ${plan.length} séries da '
            '$current. A tentativa não conta como sucesso nem como falha; '
            'repita a onda.',
        WaveState(
          cycle: prev.cycle,
          wave: w,
          baseKg: base,
          failStreak: prev.failStreak,
        ),
      );
    }

    // Onda malsucedida ou interrompida: a intensidade não sobe.
    final failStreak = prev.failStreak + 1;
    final restart =
        outcome == WaveOutcome.interrupted &&
        c.onTechnicalFailure == TechnicalFailurePolicy.restartCycle;
    final next = WaveState(
      cycle: prev.cycle,
      wave: restart ? 0 : w,
      baseKg: base,
      failStreak: restart ? 0 : failStreak,
    );
    final why = outcome == WaveOutcome.interrupted
        ? 'Falha técnica na série ${interruptedAt! + 1} da $current: a '
              'sequência foi interrompida.'
        : 'A $current não foi concluída (${problems.join('; ')}).';

    if (!restart && failStreak >= c.failureTolerance) {
      return result(
        RecommendationStatus.manualReview,
        'waveStalled',
        '$why São $failStreak tentativas seguidas sem concluir esta onda. '
            'Revise a carga de referência (${fmt(base)}), a técnica ou a '
            'recuperação.',
        next,
      );
    }
    return result(
      RecommendationStatus.maintain,
      restart
          ? 'cycleRestarted'
          : outcome == WaveOutcome.interrupted
          ? 'waveInterrupted'
          : 'waveFailed',
      restart
          ? '$why Pela sua configuração, o ciclo recomeça pela onda 1 com a '
                'mesma referência (${fmt(base)}).'
          : '$why A intensidade não sobe depois de uma onda malsucedida: '
                'repita a onda ${w + 1}.',
      next,
    );
  }

  /// Resultados das verificações comuns não mexem na posição do ciclo.
  static ProgressionResult _keep(ProgressionResult r, WaveState? state) =>
      state == null
      ? r
      : ProgressionResult(
          status: r.status,
          reasonCode: r.reasonCode,
          explanation: r.explanation,
          nextTargets: r.nextTargets,
          met: r.met,
          unmet: r.unmet,
          currentWeightKg: r.currentWeightKg,
          analyzedSessionIds: r.analyzedSessionIds,
          state: state.toJson(),
        );
}
