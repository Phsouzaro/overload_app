import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/rir_based_progression.dart';

const _strategy = RirBasedStrategy();
final _now = DateTime(2026, 6, 10, 18);

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Rosca Scott',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

/// Série com [reps] e [rir] em 30 kg.
SetRecord _set(
  int reps,
  int? rir, {
  double kg = 30,
  bool toFailure = false,
  ExecutionQuality? quality,
}) => SetRecord(
  weightKg: kg,
  reps: reps,
  rir: rir,
  toFailure: toFailure,
  quality: quality,
);

SessionRecord _session(List<SetRecord> sets, {int daysAgo = 2}) =>
    SessionRecord(
      sessionId: 1,
      date: _now.subtract(Duration(days: daysAgo)),
      sets: sets,
    );

/// Atalho: 3 séries com as mesmas [reps] e [rir].
SessionRecord _same(int reps, int? rir, {double kg = 30}) =>
    _session([for (var i = 0; i < 3; i++) _set(reps, rir, kg: kg)]);

ProgressionResult _eval(
  List<SessionRecord> history, {
  RirBasedConfig config = const RirBasedConfig(repsMin: 8, repsMax: 10),
  ExerciseContext ctx = _ctx,
}) => _strategy.evaluate(
  ProgressionInput(config: config, exercise: ctx, history: history, now: _now),
);

void main() {
  group('configuração', () {
    test('padrão é válida; JSON vai e volta', () {
      const config = RirBasedConfig(
        sets: 4,
        repsMin: 6,
        repsMax: 10,
        targetRir: 1,
        rirTolerance: 0,
        criterion: RirCriterion.lastSet,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      expect(_strategy.validate(config), isEmpty);
      expect(
        _strategy.configFromJson(config.toJson()).toJson(),
        config.toJson(),
      );
    });

    test('sempre pede o RIR na sessão', () {
      expect(const RirBasedConfig().usesRir, isTrue);
    });

    test('resumo mostra alvo e tolerância', () {
      expect(const RirBasedConfig().summary, '3 × 8–12 · RIR 2±1');
      expect(const RirBasedConfig(rirTolerance: 0).summary, '3 × 8–12 · RIR 2');
    });

    for (final (label, config, field) in [
      ('RIR-alvo 6', const RirBasedConfig(targetRir: 6), 'targetRir'),
      ('RIR-alvo -1', const RirBasedConfig(targetRir: -1), 'targetRir'),
      ('tolerância 3', const RirBasedConfig(rirTolerance: 3), 'rirTolerance'),
      (
        'faixa invertida',
        const RirBasedConfig(repsMin: 12, repsMax: 8),
        'repsMax',
      ),
      ('0 séries', const RirBasedConfig(sets: 0), 'sets'),
    ]) {
      test('inválida: $label', () {
        expect(_strategy.validate(config).map((i) => i.field), contains(field));
      });
    }
  });

  group('exemplo do planejamento (3 × 10 com RIR 2)', () {
    test('topo da faixa com RIR no alvo: sobe a carga', () {
      final r = _eval([_same(10, 2)]);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.reasonCode, 'topOfRangeWithinRir');
      expect(
        r.nextTargets,
        everyElement(
          const SetTarget(weightKg: 32.5, repsMin: 8, repsMax: 10, rir: 2),
        ),
      );
    });

    test('topo com RIR dentro da tolerância (1): sobe', () {
      expect(_eval([_same(10, 1)]).status, RecommendationStatus.increaseWeight);
    });

    test('topo com esforço acima do limite (RIR 0): mantém', () {
      final r = _eval([_same(10, 0)]);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'effortAboveTarget');
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(30.0));
    });
  });

  group('regras do RIR', () {
    test('RIR alto sem atingir o topo não sobe a carga', () {
      final r = _eval([_same(8, 5)]);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(r.reasonCode, 'easierThanTarget');
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(30.0));
    });

    test('dentro da faixa e do alvo: busca mais repetições', () {
      final r = _eval([_same(9, 2)]);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(r.reasonCode, 'withinRange');
    });

    test('falha muscular (⚡) conta como RIR 0', () {
      final r = _eval([
        _session([_set(10, 2), _set(10, 2), _set(10, null, toFailure: true)]),
      ]);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('falha técnica não é RIR 0: a série não conta', () {
      final r = _eval([
        _session([
          _set(10, 2),
          _set(10, 2),
          _set(10, 2, quality: ExecutionQuality.technicalFailure),
        ]),
      ]);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'invalidExecution');
      expect(r.explanation, contains('não é o mesmo que chegar ao limite'));
    });

    test('RIR ausente: conservador, pede o dado (nunca estima)', () {
      final r = _eval([_same(10, null)]);
      expect(r.status, RecommendationStatus.insufficientData);
      expect(r.reasonCode, 'rirMissing');
      expect(r.explanation, contains('não estima o RIR'));
      // Sugestão conservadora: mesma carga.
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(30.0));
    });

    test('RIR ausente em só uma série também é insuficiente', () {
      final r = _eval([
        _session([_set(10, 2), _set(10, null), _set(10, 2)]),
      ]);
      expect(r.reasonCode, 'rirMissing');
    });

    test('vale o menor RIR entre as séries avaliadas', () {
      final r = _eval([
        _session([_set(10, 4), _set(10, 3), _set(10, 0)]),
      ]);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('critério "última série": só ela tem o RIR avaliado', () {
      const config = RirBasedConfig(
        repsMin: 8,
        repsMax: 10,
        criterion: RirCriterion.lastSet,
      );
      final r = _eval([
        _session([_set(10, null), _set(10, 0), _set(10, 2)]),
      ], config: config);
      expect(r.status, RecommendationStatus.increaseWeight);
    });

    test('tolerância 0: RIR 1 com alvo 2 já é esforço alto', () {
      final r = _eval(
        [_same(10, 1)],
        config: const RirBasedConfig(repsMin: 8, repsMax: 10, rirTolerance: 0),
      );
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('abaixo do mínimo com esforço ok: mantém', () {
      final r = _eval([
        _session([_set(10, 2), _set(9, 2), _set(7, 2)]),
      ]);
      expect(r.reasonCode, 'belowMinimum');
    });
  });

  group('casos especiais', () {
    test('sem histórico', () {
      expect(_eval(const []).status, RecommendationStatus.insufficientData);
    });

    test('sessão interrompida: mantém', () {
      final r = _eval([
        _session([_set(10, 2), _set(10, 2)]),
      ]);
      expect(r.reasonCode, 'incompleteSession');
    });

    test('pausa longa: revisão manual', () {
      final r = _eval([
        _session([for (var i = 0; i < 3; i++) _set(10, 2)], daysAgo: 30),
      ]);
      expect(r.reasonCode, 'longBreak');
    });

    test('exigindo marcação, séries sem qualidade não sobem', () {
      final r = _eval(
        [_same(10, 2)],
        config: const RirBasedConfig(
          repsMin: 8,
          repsMax: 10,
          requireMarkedValid: true,
        ),
      );
      expect(r.reasonCode, 'invalidExecution');
    });

    test('mudança de alvo: avalia pela config nova', () {
      final history = [_same(10, 2)];
      expect(_eval(history).status, RecommendationStatus.increaseWeight);
      expect(
        _eval(
          history,
          config: const RirBasedConfig(
            repsMin: 8,
            repsMax: 10,
            targetRir: 4,
            rirTolerance: 0,
          ),
        ).reasonCode,
        'effortAboveTarget',
      );
    });

    test('mesma entrada, mesmo resultado', () {
      final a = _eval([_same(9, 2)]);
      final b = _eval([_same(9, 2)]);
      expect((a.status, a.explanation), (b.status, b.explanation));
      expect(a.nextTargets, b.nextTargets);
    });
  });

  group('parametrizado: RIR registrado × alvo 2 ± 1, no topo da faixa', () {
    for (final (rir, status) in [
      (0, RecommendationStatus.maintain),
      (1, RecommendationStatus.increaseWeight),
      (2, RecommendationStatus.increaseWeight),
      (3, RecommendationStatus.increaseWeight),
      (5, RecommendationStatus.increaseWeight),
    ]) {
      test('RIR $rir → $status', () {
        expect(_eval([_same(10, rir)]).status, status);
      });
    }
  });

  group('parametrizado: RIR registrado × alvo 2 ± 1, no meio da faixa', () {
    for (final (rir, reason) in [
      (0, 'effortAboveTarget'),
      (1, 'withinRange'),
      (3, 'withinRange'),
      (4, 'easierThanTarget'),
    ]) {
      test('RIR $rir → $reason', () {
        expect(_eval([_same(9, rir)]).reasonCode, reason);
      });
    }
  });
}
