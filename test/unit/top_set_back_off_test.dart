import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';
import 'package:overload/core/progression/progression_strategy.dart';
import 'package:overload/core/progression/strategies/top_set_back_off.dart';

const _strategy = TopSetBackOffStrategy();
final _now = DateTime(2026, 8, 1, 18);

const _ctx = ExerciseContext(
  exerciseId: 1,
  name: 'Remada',
  loadType: ExerciseLoadType.weighted,
  incrementKg: 2.5,
);

/// Top 1 × 4–6, back-off 3 × 8–10 com −15%.
const _config = TopSetBackOffConfig(
  topRepsMin: 4,
  topRepsMax: 6,
  backOffSets: 3,
  backOffPercent: 15,
  backOffRepsMin: 8,
  backOffRepsMax: 10,
);

SetRecord _top(
  int reps, {
  double kg = 70,
  int? rir,
  double? rpe,
  ExecutionQuality? quality,
  bool marked = true,
}) => SetRecord(
  weightKg: kg,
  reps: reps,
  rir: rir,
  rpe: rpe,
  quality: quality,
  role: marked ? SetRole.topSet : null,
);

SetRecord _bo(
  int reps, {
  double kg = 60,
  ExecutionQuality? quality,
  bool marked = true,
}) => SetRecord(
  weightKg: kg,
  reps: reps,
  quality: quality,
  role: marked ? SetRole.backOff : null,
);

SessionRecord _session(List<SetRecord> sets, {int daysAgo = 2}) =>
    SessionRecord(
      sessionId: 1,
      date: _now.subtract(Duration(days: daysAgo)),
      sets: sets,
    );

ProgressionResult _eval(
  List<SetRecord> sets, {
  TopSetBackOffConfig config = _config,
  ExerciseContext ctx = _ctx,
  int daysAgo = 2,
}) => _strategy.evaluate(
  ProgressionInput(
    config: config,
    exercise: ctx,
    history: [_session(sets, daysAgo: daysAgo)],
    now: _now,
  ),
);

/// (carga da principal, carga do back-off, nº de back-offs) das metas.
(double?, double?, int) _loads(ProgressionResult r) {
  final top = r.nextTargets.where((t) => t.role == SetRole.topSet);
  final bo = r.nextTargets.where((t) => t.role == SetRole.backOff);
  return (top.single.weightKg, bo.first.weightKg, bo.length);
}

void main() {
  group('configuração', () {
    test('padrão é válida; JSON vai e volta', () {
      const config = TopSetBackOffConfig(
        topRepsMin: 3,
        topRepsMax: 5,
        topTargetRir: 1,
        topTargetRpe: 9,
        backOffSets: 2,
        backOffPercent: 20,
        backOffRepsMin: 6,
        backOffRepsMax: 8,
        rounding: LoadRounding.down,
        requireMarkedValid: true,
      );
      expect(_strategy.validate(config), isEmpty);
      expect(
        _strategy.configFromJson(config.toJson()).toJson(),
        config.toJson(),
      );
    });

    test('resumo descreve a estrutura', () {
      expect(_config.summary, '1 × 4–6 + 3 × 8–10 (−15%)');
    });

    test('só faz sentido com carga externa', () {
      expect(_strategy.supportsLoadType(ExerciseLoadType.weighted), isTrue);
      expect(_strategy.supportsLoadType(ExerciseLoadType.bodyweight), isFalse);
    });

    for (final (label, config, field) in [
      (
        'faixa da principal invertida',
        const TopSetBackOffConfig(topRepsMin: 8, topRepsMax: 5),
        'topRepsMax',
      ),
      ('0 back-offs', const TopSetBackOffConfig(backOffSets: 0), 'backOffSets'),
      (
        'redução de 50%',
        const TopSetBackOffConfig(backOffPercent: 50),
        'backOffPercent',
      ),
      (
        'redução de 2%',
        const TopSetBackOffConfig(backOffPercent: 2),
        'backOffPercent',
      ),
      (
        'faixa do back-off invertida',
        const TopSetBackOffConfig(backOffRepsMin: 12, backOffRepsMax: 8),
        'backOffRepsMax',
      ),
      ('RPE 8,3', const TopSetBackOffConfig(topTargetRpe: 8.3), 'topTargetRpe'),
    ]) {
      test('inválida: $label', () {
        expect(_strategy.validate(config).map((i) => i.field), contains(field));
      });
    }
  });

  group('exemplo do planejamento: 70 kg × 6, back-off −15%', () {
    test('back-off de 59,5 kg ajustado ao equipamento (2,5 kg → 60 kg)', () {
      final r = _eval([_top(5), _bo(8), _bo(8), _bo(8)]);
      expect(_loads(r), (70.0, 60.0, 3));
    });

    test('arredondando para baixo, o back-off fica em 57,5 kg', () {
      final r = _eval(
        [_top(5), _bo(8, kg: 57.5), _bo(8, kg: 57.5), _bo(8, kg: 57.5)],
        config: const TopSetBackOffConfig(
          backOffPercent: 15,
          backOffRepsMin: 8,
          backOffRepsMax: 10,
          rounding: LoadRounding.down,
        ),
      );
      expect(_loads(r).$2, 57.5);
    });

    test('back-off dentro da faixa segura a carga já feita (59 kg)', () {
      final r = _eval(
        [_top(5), _bo(8, kg: 59), _bo(8, kg: 59), _bo(8, kg: 59)],
        ctx: const ExerciseContext(
          exerciseId: 1,
          name: 'Remada',
          loadType: ExerciseLoadType.weighted,
          incrementKg: 1,
        ),
      );
      expect(_loads(r).$2, 59.0);
    });

    test('metas mantêm os papéis: 1 principal + 3 back-off', () {
      final r = _eval([_top(5), _bo(8), _bo(8), _bo(8)]);
      expect(r.nextTargets.map((t) => t.role), [
        SetRole.topSet,
        SetRole.backOff,
        SetRole.backOff,
        SetRole.backOff,
      ]);
      expect(
        (r.nextTargets.first.repsMin, r.nextTargets.first.repsMax),
        (4, 6),
      );
      expect((r.nextTargets[1].repsMin, r.nextTargets[1].repsMax), (8, 10));
    });
  });

  group('progressão independente das duas trilhas', () {
    test('principal no topo: sobe e o back-off acompanha o percentual', () {
      final r = _eval([_top(6), _bo(9), _bo(9), _bo(9)]);
      expect(r.status, RecommendationStatus.increaseWeight);
      expect(r.reasonCode, 'topSetUp');
      // 72,5 × 0,85 = 61,6 → 62,5
      expect(_loads(r), (72.5, 62.5, 3));
    });

    test('back-off no topo sozinho: sobe só o back-off', () {
      final r = _eval([_top(5), _bo(10), _bo(10), _bo(10)]);
      expect(r.reasonCode, 'backOffUp');
      expect(_loads(r), (70.0, 62.5, 3));
    });

    test('as duas no topo: sobem as duas', () {
      final r = _eval([_top(6), _bo(10), _bo(10), _bo(10)]);
      expect(r.reasonCode, 'bothUp');
      expect(_loads(r).$1, 72.5);
      expect(_loads(r).$2, greaterThanOrEqualTo(62.5));
    });

    test('principal sobe, mas back-off abaixo do mínimo não acompanha', () {
      final r = _eval([_top(6), _bo(8), _bo(7), _bo(6)]);
      expect(r.reasonCode, 'topSetUp');
      expect(_loads(r), (72.5, 60.0, 3));
    });

    test('dentro das duas faixas: mantém cargas e busca reps', () {
      final r = _eval([_top(5), _bo(9), _bo(9), _bo(8)]);
      expect(r.status, RecommendationStatus.increaseReps);
      expect(_loads(r), (70.0, 60.0, 3));
    });
  });

  group('regras de execução e esforço', () {
    test('falha técnica na principal: ela não sobe', () {
      final r = _eval([
        _top(6, quality: ExecutionQuality.technicalFailure),
        _bo(9),
        _bo(9),
        _bo(9),
      ]);
      expect(r.status, RecommendationStatus.maintain);
      expect(_loads(r).$1, 70.0);
      expect(r.unmet.map((c) => c.code), contains('topSetValid'));
    });

    test('back-off inválido não sobe, mesmo no topo', () {
      final r = _eval([
        _top(5),
        _bo(10),
        _bo(10),
        _bo(10, quality: ExecutionQuality.invalid),
      ]);
      expect(_loads(r).$2, 60.0);
    });

    test('principal no topo sem o RIR exigido: mantém', () {
      final r = _eval(
        [_top(6), _bo(9), _bo(9), _bo(9)],
        config: const TopSetBackOffConfig(
          backOffPercent: 15,
          backOffRepsMin: 8,
          backOffRepsMax: 10,
          topTargetRir: 1,
        ),
      );
      expect(_loads(r).$1, 70.0);
      expect(r.explanation, contains('falta registrar o esforço'));
    });

    test('principal no topo com RPE acima do alvo: mantém', () {
      final r = _eval(
        [_top(6, rpe: 9.5), _bo(9), _bo(9), _bo(9)],
        config: const TopSetBackOffConfig(
          backOffPercent: 15,
          backOffRepsMin: 8,
          backOffRepsMax: 10,
          topTargetRpe: 9,
        ),
      );
      expect(_loads(r).$1, 70.0);
    });

    test('principal no topo com RIR no alvo: sobe', () {
      final r = _eval(
        [_top(6, rir: 1), _bo(9), _bo(9), _bo(9)],
        config: const TopSetBackOffConfig(
          backOffPercent: 15,
          backOffRepsMin: 8,
          backOffRepsMax: 10,
          topTargetRir: 1,
        ),
      );
      expect(_loads(r).$1, 72.5);
    });
  });

  group('identificação da série principal', () {
    test('sem papéis: a principal é a série mais pesada', () {
      final r = _eval([
        _bo(9, marked: false),
        _top(6, marked: false),
        _bo(9, marked: false),
      ]);
      expect(_loads(r).$1, 72.5);
    });

    test('sem papéis e todas com a mesma carga: revisão manual', () {
      final r = _eval([
        _top(6, marked: false),
        _top(6, marked: false),
        _top(6, marked: false),
      ]);
      expect(r.status, RecommendationStatus.manualReview);
      expect(r.reasonCode, 'topSetNotIdentified');
    });

    test('redução planejada não é tratada como "cargas diferentes"', () {
      final r = _eval([_top(5), _bo(9), _bo(9), _bo(9)]);
      expect(r.reasonCode, isNot('mixedLoads'));
    });

    test('back-off a menos (sessão interrompida): back-off não sobe', () {
      final r = _eval([_top(5), _bo(10)]);
      expect(r.status, RecommendationStatus.maintain);
      expect(_loads(r), (70.0, 60.0, 3));
    });
  });

  group('casos especiais', () {
    test('sem histórico', () {
      final r = _strategy.evaluate(
        ProgressionInput(
          config: _config,
          exercise: _ctx,
          history: const [],
          now: _now,
        ),
      );
      expect(r.status, RecommendationStatus.insufficientData);
    });

    test('pausa longa: repete a estrutura e pede revisão', () {
      final r = _eval([_top(6), _bo(10), _bo(10), _bo(10)], daysAgo: 30);
      expect(r.reasonCode, 'longBreak');
      expect(_loads(r), (70.0, 60.0, 3));
    });

    test('peso corporal: não suportado', () {
      final r = _eval(
        [_top(6), _bo(9), _bo(9), _bo(9)],
        ctx: const ExerciseContext(
          exerciseId: 2,
          name: 'Barra',
          loadType: ExerciseLoadType.bodyweight,
          incrementKg: 2.5,
        ),
      );
      expect(r.reasonCode, 'unsupportedLoadType');
    });

    test('mudança de percentual: back-off recalculado ao subir', () {
      final r = _eval(
        [_top(6), _bo(9), _bo(9), _bo(9)],
        config: const TopSetBackOffConfig(
          backOffPercent: 20,
          backOffRepsMin: 8,
          backOffRepsMax: 10,
        ),
      );
      // 72,5 × 0,8 = 58 → 57,5; não acompanha para baixo do que já fez (60)
      expect(_loads(r), (72.5, 60.0, 3));
    });

    test('mesma entrada, mesmo resultado', () {
      final a = _eval([_top(6), _bo(9), _bo(9), _bo(9)]);
      final b = _eval([_top(6), _bo(9), _bo(9), _bo(9)]);
      expect((a.reasonCode, a.explanation), (b.reasonCode, b.explanation));
      expect(a.nextTargets, b.nextTargets);
    });
  });

  group('parametrizado: percentual × incremento', () {
    for (final (top, pct, increment, expected) in [
      (100.0, 10, 2.5, 90.0),
      (100.0, 15, 2.5, 85.0),
      (100.0, 12, 2.5, 87.5), // 88 → 87,5
      (80.0, 20, 5.0, 65.0), // 64 → 65
      (70.0, 15, 1.25, 60.0), // 59,5 → 60
    ]) {
      test('principal $top kg −$pct% (incremento $increment) → $expected', () {
        final r = _eval(
          [
            _top(6, kg: top - increment),
            _bo(8, kg: 1),
            _bo(8, kg: 1),
            _bo(8, kg: 1),
          ],
          config: TopSetBackOffConfig(
            backOffPercent: pct,
            backOffRepsMin: 8,
            backOffRepsMax: 10,
          ),
          ctx: ExerciseContext(
            exerciseId: 1,
            name: 'X',
            loadType: ExerciseLoadType.weighted,
            incrementKg: increment,
          ),
        );
        // Principal sobe para `top`; back-off dentro da faixa acompanha.
        expect(_loads(r).$1, top);
        expect(_loads(r).$2, expected);
      });
    }
  });
}
