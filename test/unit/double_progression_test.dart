import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/double_progression.dart';

const _strategy = DoubleProgressionStrategy();
final _now = DateTime(2026, 3, 10, 18);
const _lb = 0.45359237;

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Supino',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

SetRecord _set(
  int reps, {
  double? kg = 50,
  int? rir,
  bool toFailure = false,
  ExecutionQuality? quality,
  bool warmup = false,
}) => SetRecord(
  weightKg: kg,
  reps: reps,
  rir: rir,
  toFailure: toFailure,
  quality: quality,
  isWarmup: warmup,
);

SessionRecord _session(List<SetRecord> sets, {int id = 1, int daysAgo = 2}) =>
    SessionRecord(
      sessionId: id,
      date: _now.subtract(Duration(days: daysAgo)),
      sets: sets,
    );

ProgressionResult _eval(
  List<SessionRecord> history, {
  DoubleProgressionConfig config = const DoubleProgressionConfig(),
  ExerciseContext ctx = _ctx,
}) => _strategy.evaluate(
  ProgressionInput(config: config, exercise: ctx, history: history, now: _now),
);

void main() {
  group('configuração', () {
    test('padrão é válida e o JSON vai e volta', () {
      const config = DoubleProgressionConfig(
        sets: 4,
        repsMin: 6,
        repsMax: 10,
        targetRir: 2,
        criterion: DoubleProgressionCriterion.mainSet,
        mainSetNumber: 2,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      expect(_strategy.validate(config), isEmpty);
      final back = _strategy.configFromJson(config.toJson());
      expect(back.toJson(), config.toJson());
    });

    test('JSON antigo sem campos opcionais usa os padrões', () {
      final c = _strategy.configFromJson(const {
        'sets': 3,
        'repsMin': 8,
        'repsMax': 12,
      });
      expect(c.criterion, DoubleProgressionCriterion.allSets);
      expect(c.rounding, LoadRounding.nearest);
      expect(c.targetRir, isNull);
      expect(c.requireMarkedValid, isFalse);
    });

    for (final (label, config, field) in [
      ('0 séries', const DoubleProgressionConfig(sets: 0), 'sets'),
      ('11 séries', const DoubleProgressionConfig(sets: 11), 'sets'),
      ('mínimo 0', const DoubleProgressionConfig(repsMin: 0), 'repsMin'),
      ('máximo 60', const DoubleProgressionConfig(repsMax: 60), 'repsMax'),
      (
        'faixa invertida',
        const DoubleProgressionConfig(repsMin: 12, repsMax: 8),
        'repsMax',
      ),
      ('RIR 6', const DoubleProgressionConfig(targetRir: 6), 'targetRir'),
      ('RIR -1', const DoubleProgressionConfig(targetRir: -1), 'targetRir'),
      (
        'série principal fora do total',
        const DoubleProgressionConfig(
          sets: 3,
          criterion: DoubleProgressionCriterion.mainSet,
          mainSetNumber: 4,
        ),
        'mainSetNumber',
      ),
    ]) {
      test('inválida: $label', () {
        expect(_strategy.validate(config).map((i) => i.field), contains(field));
      });
    }
  });

  group('exemplo do planejamento (3 × 8–12, 50 kg, +2,5 kg)', () {
    // Sessão 1: 8/8/8 · 2: 10/9/8 · 3: 11/10/9 · 4: 12/12/12
    for (final (reps, status) in [
      ([8, 8, 8], RecommendationStatus.increaseReps),
      ([10, 9, 8], RecommendationStatus.increaseReps),
      ([11, 10, 9], RecommendationStatus.increaseReps),
      ([12, 12, 12], RecommendationStatus.increaseWeight),
    ]) {
      test('${reps.join('/')} → $status', () {
        final r = _eval([
          _session([for (final x in reps) _set(x)]),
        ]);
        expect(r.status, status);
      });
    }

    test('12/12/12 sugere 52,5 kg recomeçando na base da faixa', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12)]),
      ]);
      expect(r.reasonCode, 'topOfRange');
      expect(r.currentWeightKg, 50);
      expect(r.nextTargets, hasLength(3));
      expect(
        r.nextTargets,
        everyElement(const SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12)),
      );
      expect(r.explanation, contains('52,5 kg'));
      expect(r.unmet, isEmpty);
    });

    test('enquanto não atinge a meta, a carga fica estável', () {
      final r = _eval([
        _session([_set(11), _set(10), _set(9)]),
      ]);
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(50.0));
    });
  });

  group('regras', () {
    test('aquecimento não conta para a meta', () {
      final r = _eval([
        _session([_set(5, kg: 20, warmup: true), _set(12), _set(12), _set(12)]),
      ]);
      expect(r.status, RecommendationStatus.increaseWeight);
    });

    test('série abaixo do mínimo: mantém a carga (nunca reduz)', () {
      final r = _eval([
        _session([_set(9), _set(8), _set(6)]),
      ]);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'belowMinimum');
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(50.0));
    });

    for (final quality in [
      ExecutionQuality.technicalFailure,
      ExecutionQuality.invalid,
    ]) {
      test('$quality não justifica aumento, mesmo no topo da faixa', () {
        final r = _eval([
          _session([_set(12), _set(12), _set(12, quality: quality)]),
        ]);
        expect(r.status, RecommendationStatus.maintain);
        expect(r.reasonCode, 'invalidExecution');
        expect(r.unmet.map((c) => c.code), contains('validExecution'));
      });
    }

    test('qualidade não marcada conta como válida e é avisada', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12)]),
      ]);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.explanation, contains('não foi marcada'));
    });

    test('exigindo marcação, séries sem qualidade não sobem a carga', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12)]),
      ], config: const DoubleProgressionConfig(requireMarkedValid: true));
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'invalidExecution');
    });

    test('exigindo marcação, séries marcadas válidas sobem a carga', () {
      final v = ExecutionQuality.valid;
      final r = _eval([
        _session([
          _set(12, quality: v),
          _set(12, quality: v),
          _set(12, quality: v),
        ]),
      ], config: const DoubleProgressionConfig(requireMarkedValid: true));
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.explanation, isNot(contains('não foi marcada')));
    });

    test('sessão interrompida (séries a menos) mantém a carga', () {
      final r = _eval([
        _session([_set(12), _set(12)]),
      ]);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'incompleteSession');
      expect(r.nextTargets, hasLength(3)); // continua planejando 3 séries
    });

    test('séries extras além do configurado são ignoradas', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12), _set(6)]),
      ]);
      expect(r.status, RecommendationStatus.increaseWeight);
    });

    test('cargas diferentes entre as séries pedem revisão manual', () {
      final r = _eval([
        _session([_set(12, kg: 50), _set(12, kg: 50), _set(12, kg: 47.5)]),
      ]);
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'mixedLoads');
      expect(r.nextTargets.map((t) => t.weightKg), [50.0, 50.0, 47.5]);
    });

    test('usa só a sessão mais recente do histórico', () {
      final r = _eval([
        _session([_set(9), _set(9), _set(9)], id: 2, daysAgo: 1),
        _session([_set(12), _set(12), _set(12)], id: 1, daysAgo: 4),
      ]);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(r.analyzedSessionIds, [2]);
    });
  });

  group('RIR-alvo', () {
    const config = DoubleProgressionConfig(targetRir: 2);

    test('topo da faixa com RIR dentro do alvo: sobe a carga', () {
      final r = _eval([
        _session([_set(12, rir: 2), _set(12, rir: 3), _set(12, rir: 2)]),
      ], config: config);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.nextTargets.first.rir, 2);
    });

    test('topo da faixa com esforço acima do planejado: mantém', () {
      final r = _eval([
        _session([_set(12, rir: 2), _set(12, rir: 1), _set(12, rir: 2)]),
      ], config: config);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('falha muscular conta como RIR 0', () {
      final r = _eval([
        _session([
          _set(12, rir: 2),
          _set(12, rir: 2),
          _set(12, toFailure: true),
        ]),
      ], config: config);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('RIR não registrado: conservador, pede o dado', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12)]),
      ], config: config);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'rirMissing');
    });

    test('sem RIR-alvo, o RIR registrado não interfere', () {
      final r = _eval([
        _session([_set(12, rir: 0), _set(12, rir: 0), _set(12, rir: 0)]),
      ]);
      expect(r.status, RecommendationStatus.increaseWeight);
    });
  });

  group('critério pela série principal', () {
    const config = DoubleProgressionConfig(
      criterion: DoubleProgressionCriterion.mainSet,
      mainSetNumber: 1,
    );

    test('série principal no topo e demais acima do mínimo: sobe', () {
      final r = _eval([
        _session([_set(12), _set(10), _set(9)]),
      ], config: config);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.met.map((c) => c.code), contains('topOfRange'));
    });

    test('série principal fora do topo: busca mais reps', () {
      final r = _eval([
        _session([_set(11), _set(12), _set(12)]),
      ], config: config);
      expect(r.status, RecommendationStatus.increaseReps);
    });

    test('outra série abaixo do mínimo ainda impede o aumento', () {
      final r = _eval([
        _session([_set(12), _set(10), _set(7)]),
      ], config: config);
      expect(r.reasonCode, 'belowMinimum');
    });

    test('RIR-alvo só é cobrado da série principal', () {
      final r = _eval([
        _session([_set(12, rir: 2), _set(10, rir: 0), _set(9, rir: 0)]),
      ], config: config.copyWith(targetRir: () => 2));
      expect(r.status, RecommendationStatus.increaseWeight);
    });
  });

  group('dados insuficientes e casos especiais', () {
    test('sem histórico', () {
      final r = _eval(const []);
      expect(r.status, RecommendationStatus.insufficientData);
      expect(r.nextTargets, isEmpty);
    });

    test('só aquecimento na última sessão', () {
      final r = _eval([
        _session([_set(10, warmup: true)]),
      ]);
      expect(r.status, RecommendationStatus.insufficientData);
      expect(r.reasonCode, 'noWorkingSets');
    });

    test('pausa longa pede revisão em vez de progredir', () {
      final r = _eval([
        _session([_set(12), _set(12), _set(12)], daysAgo: 30),
      ]);
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'longBreak');
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(50.0));
    });

    test('sem incremento definido: revisão manual', () {
      final r = _eval(
        [
          _session([_set(12), _set(12), _set(12)]),
        ],
        ctx: const ExerciseContext(
          exerciseId: 1,
          name: 'Supino',
          loadType: ExerciseLoadType.weighted,
          incrementKg: 0,
        ),
      );
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'noIncrement');
    });

    test('mudança de faixa: avalia pela config nova', () {
      final history = [
        _session([_set(12), _set(12), _set(12)]),
      ];
      expect(_eval(history).status, RecommendationStatus.increaseWeight);
      expect(
        _eval(
          history,
          config: const DoubleProgressionConfig(repsMin: 10, repsMax: 15),
        ).status,
        RecommendationStatus.increaseReps,
      );
    });

    test('mesma entrada, mesmo resultado', () {
      final history = [
        _session([_set(12), _set(12), _set(12)]),
      ];
      final a = _eval(history);
      final b = _eval(history);
      expect(
        (a.status, a.reasonCode, a.explanation),
        (b.status, b.reasonCode, b.explanation),
      );
      expect(a.nextTargets, b.nextTargets);
    });
  });

  group('peso corporal com carga adicional', () {
    const ctx = ExerciseContext(
      exerciseId: 2,
      name: 'Barra fixa',
      loadType: ExerciseLoadType.bodyweight,
      incrementKg: 2.5,
    );

    test('sem carga extra, no topo da faixa: sugere começar a adicionar', () {
      final r = _eval([
        _session([_set(12, kg: null), _set(12, kg: null), _set(12, kg: null)]),
      ], ctx: ctx);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.nextTargets.first.weightKg, 2.5);
      expect(r.explanation, contains('peso corporal + 2,5 kg'));
    });

    test('dentro da faixa sem carga extra: meta continua sem carga', () {
      final r = _eval([
        _session([_set(9, kg: null), _set(9, kg: null), _set(8, kg: null)]),
      ], ctx: ctx);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(r.nextTargets.first.weightKg, isNull);
    });

    test('com carga extra, sobe a carga extra', () {
      final r = _eval([
        _session([_set(12, kg: 5), _set(12, kg: 5), _set(12, kg: 5)]),
      ], ctx: ctx);
      expect(r.nextTargets.first.weightKg, 7.5);
    });
  });

  group('incrementos e arredondamento (parametrizado)', () {
    for (final (load, increment, rounding, expected) in [
      (50.0, 2.5, LoadRounding.nearest, 52.5),
      (50.0, 1.25, LoadRounding.nearest, 51.25),
      (20.0, 1.0, LoadRounding.nearest, 21.0),
      (51.0, 2.5, LoadRounding.nearest, 52.5), // carga fora da grade
      (51.0, 2.5, LoadRounding.down, 52.5),
      (51.0, 2.5, LoadRounding.up, 55.0),
      (100.0, 5.0, LoadRounding.nearest, 105.0),
    ]) {
      test('$load kg +$increment ($rounding) → $expected', () {
        final r = _eval(
          [
            _session([
              _set(12, kg: load),
              _set(12, kg: load),
              _set(12, kg: load),
            ]),
          ],
          config: DoubleProgressionConfig(rounding: rounding),
          ctx: ExerciseContext(
            exerciseId: 1,
            name: 'X',
            loadType: ExerciseLoadType.weighted,
            incrementKg: increment,
          ),
        );
        expect(r.nextTargets.first.weightKg, expected);
      });
    }

    test('em lbs: 135 lb + 5 lb → 140 lb', () {
      final load = 135 * _lb;
      final r = _eval(
        [
          _session([
            _set(12, kg: load),
            _set(12, kg: load),
            _set(12, kg: load),
          ]),
        ],
        ctx: const ExerciseContext(
          exerciseId: 1,
          name: 'X',
          loadType: ExerciseLoadType.weighted,
          incrementKg: 5 * _lb,
        ),
      );
      expect(r.nextTargets.first.weightKg! / _lb, closeTo(140, 0.01));
    });

    for (final (sets, min, max) in [
      (3, 8, 12),
      (4, 6, 10),
      (5, 3, 5),
      (2, 12, 20),
    ]) {
      test('faixa $sets × $min–$max: topo sobe, mínimo mantém', () {
        final config = DoubleProgressionConfig(
          sets: sets,
          repsMin: min,
          repsMax: max,
        );
        final top = _eval([
          _session([for (var i = 0; i < sets; i++) _set(max)]),
        ], config: config);
        final mid = _eval([
          _session([for (var i = 0; i < sets; i++) _set(min)]),
        ], config: config);
        expect(top.status, RecommendationStatus.increaseWeight);
        expect(top.nextTargets, hasLength(sets));
        expect(
          mid.status,
          min == max
              ? RecommendationStatus.increaseWeight
              : RecommendationStatus.increaseReps,
        );
      });
    }
  });
}
