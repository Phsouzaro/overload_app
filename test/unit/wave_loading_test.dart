import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/wave_loading.dart';

const _strategy = WaveLoadingStrategy();
final _now = DateTime(2026, 8, 1, 18);

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Agachamento',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

/// Três ondas diferentes entre si. Com referência de 100 kg:
/// onda 1 = 75/75/75 × 8, onda 2 = 80/80/85 × 6, onda 3 = 85×5, 90×3, 95×1.
const _config = WaveLoadingConfig(
  waves: [
    [
      WaveStep(reps: 8, percent: 75),
      WaveStep(reps: 8, percent: 75),
      WaveStep(reps: 8, percent: 75),
    ],
    [
      WaveStep(reps: 6, percent: 80),
      WaveStep(reps: 6, percent: 80),
      WaveStep(reps: 6, percent: 85),
    ],
    [
      WaveStep(reps: 5, percent: 85),
      WaveStep(reps: 3, percent: 90),
      WaveStep(reps: 1, percent: 95),
    ],
  ],
);

const _wave1 = [(75.0, 8), (75.0, 8), (75.0, 8)];
const _wave2 = [(80.0, 6), (80.0, 6), (85.0, 6)];
const _wave3 = [(85.0, 5), (90.0, 3), (95.0, 1)];

Map<String, Object?> _state({
  int cycle = 1,
  int wave = 0,
  double base = 100,
  int failStreak = 0,
  List<Map<String, Object?>> results = const [],
}) => WaveState(
  cycle: cycle,
  wave: wave,
  baseKg: base,
  failStreak: failStreak,
  results: results,
).toJson();

List<SetRecord> _sets(
  List<(double, int)> done, {
  Map<int, ExecutionQuality> quality = const {},
  SetRole? role = SetRole.wave,
}) => [
  for (var i = 0; i < done.length; i++)
    SetRecord(
      weightKg: done[i].$1,
      reps: done[i].$2,
      quality: quality[i],
      role: role,
    ),
];

ProgressionResult _eval(
  List<SetRecord> sets, {
  Map<String, Object?> state = const {},
  WaveLoadingConfig config = _config,
  ExerciseContext ctx = _ctx,
  int daysAgo = 2,
}) => _strategy.evaluate(
  ProgressionInput(
    config: config,
    exercise: ctx,
    history: [
      SessionRecord(
        sessionId: 7,
        date: _now.subtract(Duration(days: daysAgo)),
        sets: sets,
      ),
    ],
    now: _now,
    previousState: state,
  ),
);

List<(double?, int?)> _plan(ProgressionResult r) => [
  for (final t in r.nextTargets) (t.weightKg, t.repsMin),
];

WaveState _next(ProgressionResult r) => WaveState.fromJson(r.state)!;

void main() {
  group('configuração', () {
    test('a config padrão é válida e as ondas não são iguais', () {
      const c = WaveLoadingConfig();
      expect(_strategy.validate(c), isEmpty);
      expect(c.waves.toSet().length, c.waves.length);
      expect(c.summary, '3×8 → 3×6 → 3×4');
    });

    test('resumo mostra ondas com reps diferentes', () {
      expect(_config.summary, '3×8 → 3×6 → 5/3/1');
    });

    test('toJson/fromJson preserva tudo', () {
      final c = _config.copyWith(
        baseKg: () => 102.5,
        cycleIncrements: 2,
        failureTolerance: 3,
        onTechnicalFailure: TechnicalFailurePolicy.restartCycle,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      final back = WaveLoadingConfig.fromJson(c.toJson());
      expect(back.waves, c.waves);
      expect(back.toJson(), c.toJson());
    });

    test('valida ondas, séries, repetições e percentuais', () {
      List<String> issues(WaveLoadingConfig c) =>
          [for (final i in _strategy.validate(c)) i.message];

      expect(issues(_config.copyWith(waves: [])), contains('use de 1 a 6 ondas'));
      expect(
        issues(_config.copyWith(waves: List.filled(7, _config.waves.first))),
        contains('use de 1 a 6 ondas'),
      );
      expect(
        issues(_config.copyWith(waves: [[]])),
        contains('onda 1: use de 1 a 8 séries'),
      );
      expect(
        issues(
          _config.copyWith(
            waves: [
              [const WaveStep(reps: 0, percent: 75)],
            ],
          ),
        ),
        contains('onda 1, série 1: repetições de 1 a 30'),
      );
      for (final pct in [25.0, 125.0, 77.3]) {
        expect(
          issues(
            _config.copyWith(
              waves: [
                [WaveStep(reps: 5, percent: pct)],
              ],
            ),
          ),
          contains('onda 1, série 1: percentual de 30% a 120%, em passos de 0,5'),
          reason: '$pct%',
        );
      }
    });

    test('valida referência, incremento por ciclo e tolerância', () {
      final issues = _strategy.validate(
        _config.copyWith(
          baseKg: () => 0,
          cycleIncrements: 6,
          failureTolerance: 0,
        ),
      );
      expect(issues.map((i) => i.field), [
        'baseKg',
        'cycleIncrements',
        'failureTolerance',
      ]);
    });
  });

  group('plano das ondas', () {
    test('cargas por percentual, arredondadas e na ordem planejada', () {
      final plan = WaveLoadingStrategy.planFor(_config, 2, 100, 2.5);
      expect([for (final t in plan) (t.weightKg, t.repsMin, t.repsMax)], [
        (85.0, 5, 5),
        (90.0, 3, 3),
        (95.0, 1, 1),
      ]);
      expect(plan.map((t) => t.role), everyElement(SetRole.wave));
    });

    test('arredonda ao incremento conforme a config', () {
      // 67,5 × 75% = 50,625.
      double first(LoadRounding mode) => WaveLoadingStrategy.planFor(
        _config.copyWith(rounding: mode),
        0,
        67.5,
        2.5,
      ).first.weightKg!;
      expect(first(LoadRounding.nearest), 50);
      expect(first(LoadRounding.down), 50);
      expect(first(LoadRounding.up), 52.5);
    });

    test('referência deduzida: a onda 1 começa na carga usada', () {
      expect(WaveLoadingStrategy.inferBase(_config, 60, 2.5), 80);
      expect(WaveLoadingStrategy.planFor(_config, 0, 80, 2.5).first.weightKg, 60);
    });
  });

  group('início do ciclo', () {
    test('sem estado: deduz a referência e planeja a onda 1', () {
      final r = _eval(_sets(const [(60, 10), (60, 10), (60, 9)], role: null));
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'cycleStart');
      expect(_plan(r), [(60.0, 8), (60.0, 8), (60.0, 8)]);
      final s = _next(r);
      expect((s.cycle, s.wave, s.baseKg, s.failStreak), (1, 0, 80.0, 0));
      expect(r.explanation, contains('calculada a partir de 60 kg'));
    });

    test('referência definida na config prevalece', () {
      final r = _eval(
        _sets(const [(60, 10)], role: null),
        config: _config.copyWith(baseKg: () => 100),
      );
      expect(_plan(r), [(75.0, 8), (75.0, 8), (75.0, 8)]);
      expect(r.explanation, contains('definida na configuração'));
    });

    test('sem carga registrada: dados insuficientes', () {
      final r = _eval(const [SetRecord(reps: 8)]);
      expect(r.status, RecommendationStatus.insufficientData);
      expect(r.reasonCode, 'noLoad');
      expect(r.state, isEmpty);
    });

    test('peso corporal não é suportado', () {
      final r = _eval(
        _sets(_wave1),
        ctx: const ExerciseContext(
          exerciseId: 1,
          name: 'Barra',
          loadType: ExerciseLoadType.bodyweight,
          incrementKg: 2.5,
        ),
      );
      expect(r.reasonCode, 'unsupportedLoadType');
      expect(_strategy.supportsLoadType(ExerciseLoadType.bodyweight), isFalse);
    });
  });

  group('onda concluída', () {
    test('avança para a próxima onda, que é diferente', () {
      final r = _eval(_sets(_wave1), state: _state());
      expect(r.reasonCode, 'waveCompleted');
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(_plan(r), [(80.0, 6), (80.0, 6), (85.0, 6)]);
      final s = _next(r);
      expect((s.cycle, s.wave, s.baseKg), (1, 1, 100.0));
      expect(r.explanation, contains('onda 1 de 3 (ciclo 1)'));
    });

    test('registra o resultado por onda', () {
      final r = _eval(_sets(_wave2), state: _state(wave: 1));
      expect(_next(r).results, [
        {'cycle': 1, 'wave': 1, 'outcome': 'completed', 'sessionId': 7},
      ]);
      expect(_plan(r), [(85.0, 5), (90.0, 3), (95.0, 1)]);
    });

    test('carga acima da planejada também conclui', () {
      final r = _eval(
        _sets(const [(77.5, 8), (77.5, 8), (77.5, 8)]),
        state: _state(),
      );
      expect(r.reasonCode, 'waveCompleted');
    });

    test('última onda fecha o ciclo e sobe a referência', () {
      final r = _eval(_sets(_wave3), state: _state(wave: 2));
      expect(r.reasonCode, 'cycleCompleted');
      expect(r.status, RecommendationStatus.increaseWeight);
      final s = _next(r);
      expect((s.cycle, s.wave, s.baseKg, s.failStreak), (2, 0, 102.5, 0));
      // 102,5 × 75% = 76,875 → 77,5.
      expect(_plan(r), [(77.5, 8), (77.5, 8), (77.5, 8)]);
    });

    test('incrementos por ciclo configuráveis', () {
      final r = _eval(
        _sets(_wave3),
        state: _state(wave: 2),
        config: _config.copyWith(cycleIncrements: 2),
      );
      expect(_next(r).baseKg, 105);
    });

    test('próxima onda mais leve não é anunciada como subida', () {
      final c = _config.copyWith(
        waves: [
          _config.waves[0],
          [const WaveStep(reps: 10, percent: 70)],
        ],
      );
      final r = _eval(_sets(_wave1), state: _state(), config: c);
      expect(r.reasonCode, 'waveCompleted');
      expect(r.status, RecommendationStatus.maintain);
    });
  });

  group('onda malsucedida não avança', () {
    test('rep a menos: repete a onda, sem subir a intensidade', () {
      final r = _eval(
        _sets(const [(75, 8), (75, 8), (75, 7)]),
        state: _state(),
      );
      expect(r.reasonCode, 'waveFailed');
      expect(r.status, RecommendationStatus.maintain);
      expect(_plan(r), [(75.0, 8), (75.0, 8), (75.0, 8)]);
      final s = _next(r);
      expect((s.wave, s.baseKg, s.failStreak), (0, 100.0, 1));
      expect(r.explanation, contains('série 3 com 7 reps (meta 8)'));
      expect(r.unmet.map((c) => c.code), ['step3']);
      expect(r.met.map((c) => c.code), ['step1', 'step2']);
    });

    test('carga abaixo da planejada não conclui a onda', () {
      final r = _eval(
        _sets(const [(72.5, 8), (75, 8), (75, 8)]),
        state: _state(),
      );
      expect(r.reasonCode, 'waveFailed');
      expect(r.explanation, contains('série 1 com 72,5 kg (planejado 75 kg)'));
    });

    test('execução inválida não comprova a onda', () {
      final r = _eval(
        _sets(_wave1, quality: {1: ExecutionQuality.invalid}),
        state: _state(),
      );
      expect(r.reasonCode, 'waveFailed');
      expect(r.explanation, contains('série 2 sem execução válida'));
    });

    test('exigindo qualidade marcada, série sem marcação não conta', () {
      final r = _eval(
        _sets(_wave1),
        state: _state(),
        config: _config.copyWith(requireMarkedValid: true),
      );
      expect(r.reasonCode, 'waveFailed');
    });

    test('sem marcação exigida, séries sem qualidade contam e há aviso', () {
      final r = _eval(_sets(_wave1), state: _state());
      expect(r.reasonCode, 'waveCompleted');
      expect(r.explanation, contains('qualidade da execução não foi marcada'));
    });

    test('falhas seguidas até a tolerância pedem revisão', () {
      final r = _eval(
        _sets(const [(75, 8), (75, 6), (75, 5)]),
        state: _state(failStreak: 1),
      );
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'waveStalled');
      expect(_plan(r), [(75.0, 8), (75.0, 8), (75.0, 8)]);
      expect(_next(r).failStreak, 2);
    });

    test('onda incompleta não conta como falha', () {
      final r = _eval(
        _sets(const [(75, 8), (75, 8)]),
        state: _state(failStreak: 1),
      );
      expect(r.reasonCode, 'waveIncomplete');
      expect(r.status, RecommendationStatus.maintain);
      expect(_next(r).failStreak, 1);
      expect(_next(r).results.single['outcome'], 'incomplete');
    });
  });

  group('falha técnica', () {
    test('interrompe e repete a onda (padrão)', () {
      final r = _eval(
        _sets(_wave2, quality: {0: ExecutionQuality.technicalFailure}),
        state: _state(wave: 1),
      );
      expect(r.reasonCode, 'waveInterrupted');
      expect(r.status, RecommendationStatus.maintain);
      expect(_plan(r), [(80.0, 6), (80.0, 6), (85.0, 6)]);
      expect(r.explanation, contains('Falha técnica na série 1'));
      expect(_next(r).results.single['outcome'], 'interrupted');
    });

    test('com "recomeçar o ciclo", volta à onda 1 com a mesma referência', () {
      final r = _eval(
        _sets(_wave2, quality: {2: ExecutionQuality.technicalFailure}),
        state: _state(wave: 1, failStreak: 1),
        config: _config.copyWith(
          onTechnicalFailure: TechnicalFailurePolicy.restartCycle,
        ),
      );
      expect(r.reasonCode, 'cycleRestarted');
      final s = _next(r);
      expect((s.cycle, s.wave, s.baseKg, s.failStreak), (1, 0, 100.0, 0));
      expect(_plan(r), [(75.0, 8), (75.0, 8), (75.0, 8)]);
    });

    test('falha muscular não é falha técnica', () {
      final r = _eval(
        [
          ..._sets(const [(75, 8), (75, 8)]),
          const SetRecord(
            weightKg: 75,
            reps: 8,
            toFailure: true,
            role: SetRole.wave,
          ),
        ],
        state: _state(),
      );
      expect(r.reasonCode, 'waveCompleted');
    });
  });

  group('ordem e seleção das séries', () {
    test('séries da onda são comparadas na ordem planejada', () {
      // Mesmas cargas da onda 3, mas fora de ordem: 95 kg na 1ª série.
      final r = _eval(
        _sets(const [(95, 5), (90, 3), (85, 1)]),
        state: _state(wave: 2),
      );
      expect(r.reasonCode, 'waveFailed');
      expect(r.explanation, contains('série 3 com 85 kg (planejado 95 kg)'));
    });

    test('com papéis gravados, só as séries de onda contam', () {
      final r = _eval(
        [
          const SetRecord(weightKg: 40, reps: 12, role: SetRole.work),
          ..._sets(_wave1),
        ],
        state: _state(),
      );
      expect(r.reasonCode, 'waveCompleted');
    });

    test('aquecimento e séries extras são ignorados', () {
      final r = _eval(
        [
          const SetRecord(weightKg: 40, reps: 10, isWarmup: true),
          ..._sets([..._wave1, (60, 12)]),
        ],
        state: _state(),
      );
      expect(r.reasonCode, 'waveCompleted');
      expect(r.met.length, 3);
    });
  });

  group('estado e verificações comuns', () {
    test('pausa longa pede revisão sem perder a posição no ciclo', () {
      final r = _eval(_sets(_wave2), state: _state(wave: 1), daysAgo: 30);
      expect(r.reasonCode, 'longBreak');
      expect(_plan(r), [(80.0, 6), (80.0, 6), (85.0, 6)]);
      expect(_next(r).wave, 1);
    });

    test('sessão sem séries de trabalho mantém o estado', () {
      final r = _eval(
        const [SetRecord(weightKg: 40, reps: 10, isWarmup: true)],
        state: _state(wave: 2, failStreak: 1),
      );
      expect(r.reasonCode, 'noWorkingSets');
      expect((_next(r).wave, _next(r).failStreak), (2, 1));
    });

    test('resultados por onda guardam só os mais recentes', () {
      final old = [
        for (var i = 0; i < WaveState.historyLimit; i++)
          <String, Object?>{
            'cycle': 1,
            'wave': 0,
            'outcome': 'failed',
            'sessionId': i,
          },
      ];
      final r = _eval(_sets(_wave1), state: _state(results: old));
      final results = _next(r).results;
      expect(results.length, WaveState.historyLimit);
      expect(results.first['sessionId'], 1);
      expect(results.last['sessionId'], 7);
    });

    test('referência pequena demais gera carga zero: revisão', () {
      final r = _eval(
        _sets(const [(2.5, 8)]),
        state: _state(base: 2.5),
        config: _config.copyWith(
          waves: [
            [const WaveStep(reps: 8, percent: 30)],
          ],
        ),
      );
      expect(r.reasonCode, 'invalidLoads');
      expect(r.status, RecommendationStatus.manualReview);
      expect(_next(r).baseKg, 2.5);
    });

    test('posição além do número de ondas usa a última', () {
      final r = _eval(_sets(_wave3), state: _state(wave: 5));
      expect(r.reasonCode, 'cycleCompleted');
    });

    test('mesma entrada, mesmo resultado', () {
      final a = _eval(_sets(_wave2), state: _state(wave: 1));
      final b = _eval(_sets(_wave2), state: _state(wave: 1));
      expect(a.explanation, b.explanation);
      expect(a.nextTargets, b.nextTargets);
      expect(a.state, b.state);
    });
  });

  group('ciclo completo (parametrizado)', () {
    for (final inc in [1.25, 2.5, 5.0]) {
      test('incremento $inc kg: três ondas e a referência sobe', () {
        final ctx = ExerciseContext(
          exerciseId: 1,
          name: 'Agachamento',
          loadType: ExerciseLoadType.weighted,
          incrementKg: inc,
        );
        var state = _state();
        for (var w = 0; w < 3; w++) {
          final plan = WaveLoadingStrategy.planFor(_config, w, 100, inc);
          final r = _eval(
            [
              for (final t in plan)
                SetRecord(
                  weightKg: t.weightKg,
                  reps: t.repsMin,
                  role: SetRole.wave,
                ),
            ],
            state: state,
            ctx: ctx,
          );
          expect(
            r.reasonCode,
            w < 2 ? 'waveCompleted' : 'cycleCompleted',
          );
          for (final t in r.nextTargets) {
            final steps = t.weightKg! / inc;
            expect(steps, closeTo(steps.roundToDouble(), 1e-9));
          }
          state = r.state;
        }
        expect(WaveState.fromJson(state)!.baseKg, 100 + inc);
        expect(WaveState.fromJson(state)!.results.length, 3);
      });
    }
  });

  test('registrada no ProgressionStrategy com o id certo', () {
    final ProgressionStrategy s = _strategy;
    expect(s.id, StrategyId.waveLoading);
    expect(s.displayName, 'Progressão em Ondas');
  });
}
