import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/linear_progression.dart';

const _strategy = LinearProgressionStrategy();
final _now = DateTime(2026, 5, 20, 18);

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Agachamento',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

SetRecord _set(
  int reps, {
  double? kg = 60,
  int? rir,
  bool toFailure = false,
  ExecutionQuality? quality,
}) => SetRecord(
  weightKg: kg,
  reps: reps,
  rir: rir,
  toFailure: toFailure,
  quality: quality,
);

/// Sessão com [reps] por série (padrão 3 × 5) em [kg], [daysAgo] dias atrás.
SessionRecord _s(
  int id, {
  List<int> reps = const [5, 5, 5],
  double kg = 60,
  int? daysAgo,
  ExecutionQuality? quality,
  int? rir,
}) => SessionRecord(
  sessionId: id,
  date: _now.subtract(Duration(days: daysAgo ?? id)),
  sets: [for (final r in reps) _set(r, kg: kg, quality: quality, rir: rir)],
);

/// Histórico mais recente primeiro: `ids` crescentes = mais antigas.
List<SessionRecord> _history(List<SessionRecord> newestFirst) => newestFirst;

ProgressionResult _eval(
  List<SessionRecord> history, {
  LinearProgressionConfig config = const LinearProgressionConfig(),
  ExerciseContext ctx = _ctx,
}) => _strategy.evaluate(
  ProgressionInput(config: config, exercise: ctx, history: history, now: _now),
);

void main() {
  group('configuração', () {
    test('padrão é válida e o JSON vai e volta', () {
      const config = LinearProgressionConfig(
        sets: 5,
        targetReps: 3,
        successesRequired: 2,
        failureTolerance: 2,
        stallPolicy: StallPolicy.review,
        deloadPercent: 15,
        targetRir: 1,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      expect(_strategy.validate(config), isEmpty);
      expect(
        _strategy.configFromJson(config.toJson()).toJson(),
        config.toJson(),
      );
    });

    test('JSON mínimo usa os padrões', () {
      final c = _strategy.configFromJson(const {'sets': 3, 'targetReps': 8});
      expect(
        (
          c.successesRequired,
          c.failureTolerance,
          c.stallPolicy,
          c.deloadPercent,
        ),
        (1, 3, StallPolicy.reduce, 10),
      );
    });

    for (final (label, config, field) in [
      ('0 séries', const LinearProgressionConfig(sets: 0), 'sets'),
      (
        'meta 0 reps',
        const LinearProgressionConfig(targetReps: 0),
        'targetReps',
      ),
      (
        'meta 51 reps',
        const LinearProgressionConfig(targetReps: 51),
        'targetReps',
      ),
      (
        '0 sessões bem-sucedidas',
        const LinearProgressionConfig(successesRequired: 0),
        'successesRequired',
      ),
      (
        '6 sessões bem-sucedidas',
        const LinearProgressionConfig(successesRequired: 6),
        'successesRequired',
      ),
      (
        'tolerância 0',
        const LinearProgressionConfig(failureTolerance: 0),
        'failureTolerance',
      ),
      (
        'redução de 40%',
        const LinearProgressionConfig(deloadPercent: 40),
        'deloadPercent',
      ),
      ('RIR 7', const LinearProgressionConfig(targetRir: 7), 'targetRir'),
    ]) {
      test('inválida: $label', () {
        expect(_strategy.validate(config).map((i) => i.field), contains(field));
      });
    }

    test('redução fora da faixa não importa se a política não reduz', () {
      const config = LinearProgressionConfig(
        stallPolicy: StallPolicy.maintain,
        deloadPercent: 90,
      );
      expect(_strategy.validate(config), isEmpty);
    });
  });

  group('exemplo do planejamento (3 × 8 com 60 kg, +2,5 kg)', () {
    const config = LinearProgressionConfig(targetReps: 8);

    test('todas as séries completas → 62,5 kg', () {
      final r = _eval([
        _s(1, reps: const [8, 8, 8]),
      ], config: config);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.reasonCode, 'successStreakReached');
      expect(
        r.nextTargets,
        everyElement(const SetTarget(weightKg: 62.5, repsMin: 8, repsMax: 8)),
      );
      expect(r.explanation, contains('62,5 kg'));
    });

    test('uma série abaixo da meta → mantém e registra a tentativa', () {
      final r = _eval([
        _s(1, reps: const [8, 8, 7]),
      ], config: config);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'failedAttempt');
      expect(r.explanation, contains('Falha 1 de 3'));
      expect(r.state['failStreak'], 1);
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(60.0));
    });
  });

  group('várias sessões bem-sucedidas necessárias', () {
    const config = LinearProgressionConfig(successesRequired: 2);

    test('1ª sessão bem-sucedida: confirma antes de subir', () {
      final r = _eval([_s(1)], config: config);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'needMoreSuccesses');
      expect(r.unmet.map((c) => c.code), contains('successStreak'));
    });

    test('2 sessões bem-sucedidas seguidas na mesma carga: sobe', () {
      final r = _eval(_history([_s(1), _s(2)]), config: config);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.analyzedSessionIds, [1, 2]);
    });

    test('sucesso em carga diferente não conta para a sequência', () {
      final r = _eval(_history([_s(1), _s(2, kg: 57.5)]), config: config);
      expect(r.reasonCode, 'needMoreSuccesses');
    });

    test('falha no meio quebra a sequência', () {
      final r = _eval(
        _history([
          _s(1),
          _s(2, reps: const [5, 5, 4]),
          _s(3),
        ]),
        config: config,
      );
      expect(r.reasonCode, 'needMoreSuccesses');
    });

    test('sessão interrompida no meio não quebra a sequência', () {
      final r = _eval(
        _history([
          _s(1),
          _s(2, reps: const [5]),
          _s(3),
        ]),
        config: config,
      );
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.analyzedSessionIds, [1, 3]);
    });
  });

  group('tolerância a falhas e estagnação', () {
    List<SessionRecord> fails(int n) => [
      for (var i = 1; i <= n; i++) _s(i, reps: const [5, 5, 3]),
    ];

    test('falhas abaixo da tolerância: mantém', () {
      final r = _eval(fails(2));
      expect(r.reasonCode, 'failedAttempt');
      expect(r.explanation, contains('Falha 2 de 3'));
    });

    test('sucesso anterior não entra na contagem de falhas', () {
      final r = _eval([
        ...fails(2),
        _s(3),
        ..._history([
          _s(4, reps: const [5, 5, 3]),
        ]),
      ]);
      expect(r.state['failStreak'], 2);
    });

    for (final (policy, status, reason) in [
      (StallPolicy.maintain, RecommendationStatus.maintain, 'stalledMaintain'),
      (StallPolicy.review, RecommendationStatus.manualReview, 'stalledReview'),
      (
        StallPolicy.reduce,
        RecommendationStatus.decreaseWeight,
        'stalledReduce',
      ),
    ]) {
      test('3 falhas seguidas com política $policy → $status', () {
        final r = _eval(
          fails(3),
          config: LinearProgressionConfig(stallPolicy: policy),
        );
        expect(r.status, status);
        expect(r.reasonCode, reason);
      });
    }

    test('redução de 10% sobre 60 kg arredonda para baixo: 52,5 kg', () {
      final r = _eval(fails(3));
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(52.5));
      expect(r.explanation, contains('Só vale se você aceitar'));
    });

    test('sem carga para reduzir (peso corporal sem extra): revisão', () {
      final r = _eval(
        [
          for (var i = 1; i <= 3; i++)
            SessionRecord(
              sessionId: i,
              date: _now.subtract(Duration(days: i)),
              sets: [
                for (final reps in [5, 5, 3]) _set(reps, kg: null),
              ],
            ),
        ],
        ctx: const ExerciseContext(
          exerciseId: 2,
          name: 'Barra',
          loadType: ExerciseLoadType.bodyweight,
          incrementKg: 2.5,
        ),
      );
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'stalledCannotReduce');
    });

    test('depois de reduzir, a sequência recomeça na carga nova', () {
      final r = _eval([
        _s(1, kg: 52.5),
        ...[
          for (var i = 2; i <= 4; i++) _s(i, reps: const [5, 5, 3]),
        ],
      ]);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.state['failStreak'], 0);
    });
  });

  group('execução e esforço', () {
    for (final quality in [
      ExecutionQuality.technicalFailure,
      ExecutionQuality.invalid,
    ]) {
      test('$quality conta como tentativa malsucedida', () {
        final r = _eval([_s(1, quality: quality)]);
        expect(r.status, RecommendationStatus.maintain);
        expect(r.reasonCode, 'failedAttempt');
        expect(r.explanation, contains('execução comprometida'));
      });
    }

    test('exigindo marcação, séries sem qualidade não sobem', () {
      final r = _eval([
        _s(1),
      ], config: const LinearProgressionConfig(requireMarkedValid: true));
      expect(r.reasonCode, 'failedAttempt');
    });

    test('RIR dentro do alvo: sucesso', () {
      final r = _eval([
        _s(1, rir: 2),
      ], config: const LinearProgressionConfig(targetRir: 2));
      expect(r.status, RecommendationStatus.increaseWeight);
    });

    test('RIR abaixo do alvo: tentativa malsucedida', () {
      final r = _eval([
        _s(1, rir: 0),
      ], config: const LinearProgressionConfig(targetRir: 2));
      expect(r.reasonCode, 'failedAttempt');
      expect(r.explanation, contains('RIR-alvo'));
    });

    test('RIR ausente: não conta como sucesso nem falha', () {
      final r = _eval([
        _s(1),
      ], config: const LinearProgressionConfig(targetRir: 2));
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'rirMissing');
      expect(r.state['failStreak'], 0);
    });
  });

  group('dados insuficientes e casos especiais', () {
    test('sem histórico', () {
      expect(_eval(const []).status, RecommendationStatus.insufficientData);
    });

    test('sessão interrompida: mantém, sem contar como falha', () {
      final r = _eval([
        _s(1, reps: const [5, 5]),
      ]);
      expect(r.reasonCode, 'incompleteSession');
      expect(r.state['failStreak'], 0);
    });

    test('sem incremento: revisão manual', () {
      final r = _eval(
        [_s(1)],
        ctx: const ExerciseContext(
          exerciseId: 1,
          name: 'X',
          loadType: ExerciseLoadType.weighted,
          incrementKg: 0,
        ),
      );
      expect(r.reasonCode, 'noIncrement');
    });

    test('cargas diferentes na sessão: revisão manual', () {
      final r = _eval([
        SessionRecord(
          sessionId: 1,
          date: _now.subtract(const Duration(days: 1)),
          sets: [_set(5, kg: 60), _set(5, kg: 60), _set(5, kg: 55)],
        ),
      ]);
      expect(r.reasonCode, 'mixedLoads');
    });

    test('pausa longa: revisão manual mesmo após sucesso', () {
      final r = _eval([_s(1, daysAgo: 40)]);
      expect(r.reasonCode, 'longBreak');
    });

    test('mudança de meta: avalia o histórico pela config nova', () {
      final history = [_s(1)]; // 3 × 5
      expect(_eval(history).status, RecommendationStatus.increaseWeight);
      expect(
        _eval(
          history,
          config: const LinearProgressionConfig(targetReps: 6),
        ).reasonCode,
        'failedAttempt',
      );
    });

    test('mesma entrada, mesmo resultado', () {
      final history = [
        _s(1),
        _s(2, reps: const [5, 5, 4]),
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

  group('incrementos (parametrizado)', () {
    for (final (kg, increment, rounding, expected) in [
      (60.0, 2.5, LoadRounding.nearest, 62.5),
      (60.0, 5.0, LoadRounding.nearest, 65.0),
      (100.0, 1.25, LoadRounding.nearest, 101.25),
      (61.0, 2.5, LoadRounding.down, 62.5),
      (61.0, 2.5, LoadRounding.up, 65.0),
    ]) {
      test('$kg kg +$increment ($rounding) → $expected', () {
        final r = _eval(
          [_s(1, kg: kg)],
          config: LinearProgressionConfig(rounding: rounding),
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

    for (final (sets, reps) in [(3, 5), (5, 5), (1, 3), (4, 10)]) {
      test('$sets × $reps: completa sobe, falta 1 rep mantém', () {
        final config = LinearProgressionConfig(sets: sets, targetReps: reps);
        final done = _eval([
          _s(1, reps: [for (var i = 0; i < sets; i++) reps]),
        ], config: config);
        final miss = _eval([
          _s(
            1,
            reps: [for (var i = 0; i < sets; i++) i == 0 ? reps - 1 : reps],
          ),
        ], config: config);
        expect(done.status, RecommendationStatus.increaseWeight);
        expect(done.nextTargets, hasLength(sets));
        expect(miss.reasonCode, 'failedAttempt');
      });
    }
  });
}
