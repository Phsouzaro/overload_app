import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_rules.dart';

const _lb = 0.45359237; // kg

void main() {
  group('ProgressionRules.countsTowardGoal', () {
    for (final (quality, requireMarked, expected) in [
      (ExecutionQuality.valid, false, true),
      (ExecutionQuality.valid, true, true),
      (null, false, true), // não registrada conta, por padrão
      (null, true, false), // ...mas não quando a config exige marcação
      (ExecutionQuality.technicalFailure, false, false),
      (ExecutionQuality.technicalFailure, true, false),
      (ExecutionQuality.invalid, false, false),
      (ExecutionQuality.invalid, true, false),
    ]) {
      test(
        'qualidade=$quality, exigir marcação=$requireMarked → $expected',
        () {
          expect(
            ProgressionRules.countsTowardGoal(
              SetRecord(weightKg: 50, reps: 10, quality: quality),
              requireMarkedValid: requireMarked,
            ),
            expected,
          );
        },
      );
    }

    test('falha muscular (toFailure) não invalida a série', () {
      expect(
        ProgressionRules.countsTowardGoal(
          const SetRecord(weightKg: 50, reps: 12, toFailure: true),
          requireMarkedValid: false,
        ),
        isTrue,
      );
    });
  });

  group('ProgressionRules.workingSets', () {
    test('ignora aquecimento e séries vazias, mantém a ordem', () {
      final session = SessionRecord(
        sessionId: 1,
        date: DateTime(2026, 1, 1),
        sets: const [
          SetRecord(weightKg: 20, reps: 10, isWarmup: true),
          SetRecord(weightKg: 50, reps: 8),
          SetRecord(),
          SetRecord(weightKg: 50, reps: 7),
        ],
      );
      final working = ProgressionRules.workingSets(session);
      expect(working.map((s) => s.reps), [8, 7]);
    });

    test('peso corporal sem carga extra (só reps) conta como série', () {
      final session = SessionRecord(
        sessionId: 1,
        date: DateTime(2026, 1, 1),
        sets: const [SetRecord(reps: 12)],
      );
      expect(ProgressionRules.workingSets(session), hasLength(1));
    });
  });

  group('ProgressionRules.roundToIncrement', () {
    for (final (weight, increment, mode, expected) in [
      (52.5, 2.5, LoadRounding.nearest, 52.5),
      (51.0, 2.5, LoadRounding.nearest, 50.0),
      (51.3, 2.5, LoadRounding.nearest, 52.5),
      (59.5, 2.5, LoadRounding.nearest, 60.0), // 70 kg − 15%
      (59.5, 2.5, LoadRounding.down, 57.5),
      (59.5, 2.5, LoadRounding.up, 60.0),
      (60.0, 2.5, LoadRounding.down, 60.0), // já múltiplo: não desce
      (60.0, 2.5, LoadRounding.up, 60.0), // já múltiplo: não sobe
      (31.0, 1.25, LoadRounding.nearest, 31.25),
      (17.3, 1.0, LoadRounding.nearest, 17.0),
      (42.0, 0.0, LoadRounding.nearest, 42.0), // sem incremento: não mexe
    ]) {
      test('$weight kg, incremento $increment, $mode → $expected', () {
        expect(
          ProgressionRules.roundToIncrement(weight, increment, mode: mode),
          expected,
        );
      });
    }

    test('em lbs: arredonda para múltiplos de 5 lb', () {
      // 100 kg ≈ 220,46 lb → 220 lb
      final rounded = ProgressionRules.roundToIncrement(100, 5 * _lb);
      expect(rounded / _lb, closeTo(220, 0.01));
    });

    test('sem resíduo de ponto flutuante', () {
      expect(ProgressionRules.roundToIncrement(0.1 + 0.2, 0.1), 0.3);
    });
  });

  group('ProgressionRules — pausa longa', () {
    final now = DateTime(2026, 3, 1);
    SessionRecord at(DateTime d) =>
        SessionRecord(sessionId: 1, date: d, sets: const []);

    test('sem histórico: sem dias e sem pausa', () {
      expect(ProgressionRules.daysSinceLastSession(const [], now), isNull);
      expect(ProgressionRules.isLongBreak(const [], now), isFalse);
    });

    test('usa a sessão mais recente (primeira da lista)', () {
      final history = [at(DateTime(2026, 2, 20)), at(DateTime(2025, 12, 1))];
      expect(ProgressionRules.daysSinceLastSession(history, now), 9);
      expect(ProgressionRules.isLongBreak(history, now), isFalse);
    });

    test('mais de ${ProgressionRules.longBreakDays} dias é pausa longa', () {
      expect(
        ProgressionRules.isLongBreak([at(DateTime(2026, 2, 7))], now),
        isTrue,
      );
      expect(
        ProgressionRules.isLongBreak([at(DateTime(2026, 2, 8))], now),
        isFalse,
      );
    });
  });

  group('SetTarget JSON', () {
    test('ida e volta preserva todos os campos', () {
      const target = SetTarget(
        role: SetRole.backOff,
        weightKg: 59.5,
        repsMin: 8,
        repsMax: 10,
        rir: 2,
        rpe: 8.5,
      );
      expect(SetTarget.fromJson(target.toJson()), target);
    });

    test('campos opcionais ausentes ficam nulos; papel padrão é work', () {
      final target = SetTarget.fromJson(const {});
      expect(target, const SetTarget());
      expect(target.role, SetRole.work);
    });
  });
}
