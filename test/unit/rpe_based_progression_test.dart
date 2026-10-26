import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/rpe_based_progression.dart';

const _strategy = RpeBasedStrategy();
final _now = DateTime(2026, 7, 1, 18);

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Supino inclinado',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

/// 3 × 8–10 com RPE-alvo 8 ± 0,5.
const _config = RpeBasedConfig(repsMin: 8, repsMax: 10);

SetRecord _set(
  int reps,
  double? rpe, {
  int? rir,
  bool toFailure = false,
  ExecutionQuality? quality,
}) => SetRecord(
  weightKg: 40,
  reps: reps,
  rpe: rpe,
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

SessionRecord _same(int reps, double? rpe) =>
    _session([for (var i = 0; i < 3; i++) _set(reps, rpe)]);

ProgressionResult _eval(
  List<SessionRecord> history, {
  RpeBasedConfig config = _config,
}) => _strategy.evaluate(
  ProgressionInput(config: config, exercise: _ctx, history: history, now: _now),
);

void main() {
  group('configuração', () {
    test('padrão é válida; JSON vai e volta', () {
      const config = RpeBasedConfig(
        sets: 4,
        repsMin: 5,
        repsMax: 8,
        targetRpe: 8.5,
        rpeTolerance: 1,
        criterion: EffortCriterion.lastSet,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      expect(_strategy.validate(config), isEmpty);
      expect(
        _strategy.configFromJson(config.toJson()).toJson(),
        config.toJson(),
      );
    });

    test('pede RPE na sessão, não RIR', () {
      expect((_config.usesRpe, _config.usesRir), (true, false));
    });

    test('resumo usa vírgula decimal', () {
      expect(
        const RpeBasedConfig(targetRpe: 8.5).summary,
        '3 × 8–12 · RPE 8,5±0,5',
      );
      expect(const RpeBasedConfig(rpeTolerance: 0).summary, '3 × 8–12 · RPE 8');
    });

    for (final (label, config, field) in [
      ('RPE 5,5', const RpeBasedConfig(targetRpe: 5.5), 'targetRpe'),
      ('RPE 10,5', const RpeBasedConfig(targetRpe: 10.5), 'targetRpe'),
      (
        'RPE 8,3 (fora dos passos de 0,5)',
        const RpeBasedConfig(targetRpe: 8.3),
        'targetRpe',
      ),
      (
        'tolerância 0,3',
        const RpeBasedConfig(rpeTolerance: 0.3),
        'rpeTolerance',
      ),
      ('tolerância 2', const RpeBasedConfig(rpeTolerance: 2), 'rpeTolerance'),
      (
        'faixa invertida',
        const RpeBasedConfig(repsMin: 10, repsMax: 6),
        'repsMax',
      ),
    ]) {
      test('inválida: $label', () {
        expect(_strategy.validate(config).map((i) => i.field), contains(field));
      });
    }
  });

  group('regras do RPE', () {
    test('meta atingida com esforço no alvo: sobe a carga', () {
      final r = _eval([_same(10, 8)]);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.reasonCode, 'topOfRangeWithinRpe');
      expect(
        r.nextTargets,
        everyElement(
          const SetTarget(weightKg: 42.5, repsMin: 8, repsMax: 10, rpe: 8),
        ),
      );
    });

    test('meta atingida com esforço abaixo do planejado: sobe', () {
      expect(
        _eval([_same(10, 6.5)]).status,
        RecommendationStatus.increaseWeight,
      );
    });

    test('esforço acima do planejado: mantém (nunca reduz sozinho)', () {
      final r = _eval([_same(10, 9)]);
      expect(r.status, RecommendationStatus.maintain);
      expect(r.reasonCode, 'effortAboveTarget');
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(40.0));
    });

    test('esforço baixo sem a meta não sobe a carga', () {
      final r = _eval([_same(8, 6.5)]);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(r.reasonCode, 'easierThanTarget');
    });

    test('dentro do planejado e da faixa: busca mais repetições', () {
      expect(_eval([_same(9, 8)]).reasonCode, 'withinRange');
    });

    test('vale o maior RPE entre as séries avaliadas', () {
      final r = _eval([
        _session([_set(10, 7), _set(10, 8), _set(10, 9.5)]),
      ]);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('falha muscular (⚡) vale RPE 10', () {
      final r = _eval([
        _session([_set(10, 8), _set(10, 8), _set(10, null, toFailure: true)]),
      ]);
      expect(r.reasonCode, 'effortAboveTarget');
    });

    test('RIR não é convertido em RPE: sem RPE = dados insuficientes', () {
      final r = _eval([
        _session([for (var i = 0; i < 3; i++) _set(10, null, rir: 2)]),
      ]);
      expect(r.status, RecommendationStatus.insufficientData);
      expect(r.reasonCode, 'rpeMissing');
      expect(r.explanation, contains('não é convertido'));
      expect(r.nextTargets.map((t) => t.weightKg), everyElement(40.0));
    });

    test('falha técnica não comprova a meta', () {
      final r = _eval([
        _session([
          _set(10, 8),
          _set(10, 8),
          _set(10, 8, quality: ExecutionQuality.technicalFailure),
        ]),
      ]);
      expect(r.reasonCode, 'invalidExecution');
    });

    test('critério "última série": só ela tem o RPE avaliado', () {
      final r = _eval(
        [
          _session([_set(10, null), _set(10, 9.5), _set(10, 8)]),
        ],
        config: const RpeBasedConfig(
          repsMin: 8,
          repsMax: 10,
          criterion: EffortCriterion.lastSet,
        ),
      );
      expect(r.status, RecommendationStatus.increaseWeight);
    });

    test('abaixo do mínimo com esforço ok: mantém', () {
      final r = _eval([
        _session([_set(10, 8), _set(9, 8), _set(7, 8)]),
      ]);
      expect(r.reasonCode, 'belowMinimum');
    });
  });

  group('casos especiais', () {
    test('sem histórico', () {
      expect(_eval(const []).status, RecommendationStatus.insufficientData);
    });

    test('sessão interrompida', () {
      final r = _eval([
        _session([_set(10, 8), _set(10, 8)]),
      ]);
      expect(r.reasonCode, 'incompleteSession');
    });

    test('pausa longa', () {
      final r = _eval([
        _session([for (var i = 0; i < 3; i++) _set(10, 8)], daysAgo: 30),
      ]);
      expect(r.reasonCode, 'longBreak');
    });

    test('mudança de alvo: avalia pela config nova', () {
      final history = [_same(10, 8)];
      expect(_eval(history).status, RecommendationStatus.increaseWeight);
      expect(
        _eval(
          history,
          config: const RpeBasedConfig(
            repsMin: 8,
            repsMax: 10,
            targetRpe: 7,
            rpeTolerance: 0.5,
          ),
        ).reasonCode,
        'effortAboveTarget',
      );
    });

    test('mesma entrada, mesmo resultado', () {
      final a = _eval([_same(9, 8)]);
      final b = _eval([_same(9, 8)]);
      expect((a.status, a.explanation), (b.status, b.explanation));
      expect(a.nextTargets, b.nextTargets);
    });
  });

  group('parametrizado: RPE registrado × alvo 8 ± 0,5, no topo', () {
    for (final (rpe, status) in [
      (6.0, RecommendationStatus.increaseWeight),
      (7.5, RecommendationStatus.increaseWeight),
      (8.0, RecommendationStatus.increaseWeight),
      (8.5, RecommendationStatus.increaseWeight),
      (9.0, RecommendationStatus.maintain),
      (10.0, RecommendationStatus.maintain),
    ]) {
      test('RPE $rpe → $status', () {
        expect(_eval([_same(10, rpe)]).status, status);
      });
    }
  });

  group('parametrizado: tolerância muda o limite', () {
    for (final (tolerance, rpe, reason) in [
      (0.0, 8.5, 'effortAboveTarget'),
      (0.5, 8.5, 'topOfRangeWithinRpe'),
      (1.0, 9.0, 'topOfRangeWithinRpe'),
      (1.0, 9.5, 'effortAboveTarget'),
    ]) {
      test('±$tolerance com RPE $rpe → $reason', () {
        final r = _eval(
          [_same(10, rpe)],
          config: RpeBasedConfig(
            repsMin: 8,
            repsMax: 10,
            rpeTolerance: tolerance,
          ),
        );
        expect(r.reasonCode, reason);
      });
    }
  });
}
