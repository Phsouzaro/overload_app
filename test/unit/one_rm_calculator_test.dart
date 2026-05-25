import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/utils/one_rm_calculator.dart';

// Fórmula de Epley: 1RM = weight × (1 + reps / 30), arredondado ao 0.25 mais próximo.
// Implementação: (raw * 4).round() / 4

void main() {
  group('OneRmCalculator.estimate', () {
    // ── Entradas inválidas → null ──────────────────────────────────────────────
    group('retorna null para entradas fora dos limites', () {
      test('reps == 0', () {
        expect(OneRmCalculator.estimate(100, 0), isNull);
      });

      test('reps == 1', () {
        expect(OneRmCalculator.estimate(100, 1), isNull);
      });

      test('reps == 2 (abaixo do mínimo de 3)', () {
        expect(OneRmCalculator.estimate(100, 2), isNull);
      });

      test('reps == 21 (acima do máximo de 20)', () {
        expect(OneRmCalculator.estimate(100, 21), isNull);
      });

      test('reps muito alto', () {
        expect(OneRmCalculator.estimate(100, 100), isNull);
      });

      test('weight == 0', () {
        expect(OneRmCalculator.estimate(0, 10), isNull);
      });

      test('weight negativo', () {
        expect(OneRmCalculator.estimate(-50, 10), isNull);
      });
    });

    // ── Limites válidos ───────────────────────────────────────────────────────
    group('aceita os limites exatos do intervalo válido', () {
      test('reps == 3 (mínimo) retorna valor', () {
        expect(OneRmCalculator.estimate(100, 3), isNotNull);
      });

      test('reps == 20 (máximo) retorna valor', () {
        expect(OneRmCalculator.estimate(100, 20), isNotNull);
      });
    });

    // ── Valores calculados ────────────────────────────────────────────────────
    group('cálculo pela fórmula de Epley com arredondamento 0.25', () {
      // 100 kg × 10 reps → raw = 100 × (1 + 10/30) = 133.333...
      // (133.333 × 4).round() / 4 = 533 / 4 = 133.25
      test('100 kg × 10 reps → 133.25 kg', () {
        expect(OneRmCalculator.estimate(100, 10), 133.25);
      });

      // 80 kg × 5 reps → raw = 80 × (1 + 5/30) = 93.333...
      // (93.333 × 4).round() / 4 = 373 / 4 = 93.25
      test('80 kg × 5 reps → 93.25 kg', () {
        expect(OneRmCalculator.estimate(80, 5), 93.25);
      });

      // 60 kg × 3 reps → raw = 60 × (1 + 3/30) = 66.0
      // (66.0 × 4).round() / 4 = 264 / 4 = 66.0
      test('60 kg × 3 reps → 66.0 kg (sem arredondamento necessário)', () {
        expect(OneRmCalculator.estimate(60, 3), 66.0);
      });

      // 120 kg × 8 reps → raw = 120 × (1 + 8/30) = 152.0
      // (152.0 × 4).round() / 4 = 608 / 4 = 152.0
      test('120 kg × 8 reps → 152.0 kg', () {
        expect(OneRmCalculator.estimate(120, 8), 152.0);
      });

      // 50 kg × 20 reps → raw = 50 × (1 + 20/30) = 83.333...
      // (83.333 × 4).round() / 4 = 333 / 4 = 83.25
      test('50 kg × 20 reps → 83.25 kg', () {
        expect(OneRmCalculator.estimate(50, 20), 83.25);
      });
    });

    // ── Propriedade de arredondamento ─────────────────────────────────────────
    group('resultado sempre é múltiplo de 0.25', () {
      final testCases = [
        (67.5, 7),
        (102.5, 12),
        (45.0, 15),
        (87.5, 6),
      ];

      for (final (weight, reps) in testCases) {
        test('${weight}kg × $reps reps', () {
          final result = OneRmCalculator.estimate(weight, reps);
          expect(result, isNotNull);
          // Múltiplo de 0.25: (result * 4) deve ser inteiro
          final times4 = (result! * 4).roundToDouble();
          expect(times4, result * 4,
              reason: '$result não é múltiplo de 0.25');
        });
      }
    });

    // ── Crescimento monotônico ────────────────────────────────────────────────
    test('mais repetições com mesmo peso → maior 1RM estimado', () {
      final rm5 = OneRmCalculator.estimate(100, 5)!;
      final rm10 = OneRmCalculator.estimate(100, 10)!;
      final rm15 = OneRmCalculator.estimate(100, 15)!;
      expect(rm10, greaterThan(rm5));
      expect(rm15, greaterThan(rm10));
    });

    test('maior peso com mesmo número de reps → maior 1RM estimado', () {
      final rm80 = OneRmCalculator.estimate(80, 8)!;
      final rm100 = OneRmCalculator.estimate(100, 8)!;
      final rm120 = OneRmCalculator.estimate(120, 8)!;
      expect(rm100, greaterThan(rm80));
      expect(rm120, greaterThan(rm100));
    });
  });
}
