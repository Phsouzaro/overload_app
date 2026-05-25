import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    // ── toDisplay ─────────────────────────────────────────────────────────────
    group('toDisplay', () {
      test('retorna o mesmo valor em kg', () {
        expect(UnitConverter.toDisplay(100.0, WeightUnit.kg), 100.0);
        expect(UnitConverter.toDisplay(0.0, WeightUnit.kg), 0.0);
        expect(UnitConverter.toDisplay(57.5, WeightUnit.kg), 57.5);
      });

      test('converte kg → lbs com fator 2.20462', () {
        expect(
          UnitConverter.toDisplay(100.0, WeightUnit.lbs),
          closeTo(220.462, 0.001),
        );
      });

      test('converte 0 kg → 0 lbs', () {
        expect(UnitConverter.toDisplay(0.0, WeightUnit.lbs), 0.0);
      });

      test('converte valores fracionários corretamente', () {
        // 22.5 kg × 2.20462 ≈ 49.604 lbs
        expect(
          UnitConverter.toDisplay(22.5, WeightUnit.lbs),
          closeTo(49.604, 0.001),
        );
      });
    });

    // ── fromDisplay ───────────────────────────────────────────────────────────
    group('fromDisplay', () {
      test('retorna o mesmo valor em kg (sem conversão)', () {
        expect(UnitConverter.fromDisplay(100.0, WeightUnit.kg), 100.0);
      });

      test('converte lbs → kg corretamente', () {
        expect(
          UnitConverter.fromDisplay(220.462, WeightUnit.lbs),
          closeTo(100.0, 0.001),
        );
      });

      test('toDisplay e fromDisplay são operações inversas', () {
        const originalKg = 75.5;
        final lbs = UnitConverter.toDisplay(originalKg, WeightUnit.lbs);
        final backToKg = UnitConverter.fromDisplay(lbs, WeightUnit.lbs);
        expect(backToKg, closeTo(originalKg, 0.0001));
      });

      test('inversão também funciona para valores pequenos', () {
        const originalKg = 2.5;
        final lbs = UnitConverter.toDisplay(originalKg, WeightUnit.lbs);
        final backToKg = UnitConverter.fromDisplay(lbs, WeightUnit.lbs);
        expect(backToKg, closeTo(originalKg, 0.0001));
      });
    });

    // ── label ─────────────────────────────────────────────────────────────────
    group('label', () {
      test('retorna "kg" para WeightUnit.kg', () {
        expect(UnitConverter.label(WeightUnit.kg), 'kg');
      });

      test('retorna "lbs" para WeightUnit.lbs', () {
        expect(UnitConverter.label(WeightUnit.lbs), 'lbs');
      });
    });

    // ── format ────────────────────────────────────────────────────────────────
    group('format', () {
      test('formata peso em kg com 1 decimal por padrão', () {
        expect(UnitConverter.format(80.0, WeightUnit.kg), '80.0 kg');
      });

      test('formata peso em lbs e inclui a unidade no texto', () {
        final result = UnitConverter.format(100.0, WeightUnit.lbs);
        expect(result, contains('lbs'));
        expect(result, contains('220.5')); // 100 * 2.20462 ≈ 220.5 com 1 decimal
      });

      test('respeita o parâmetro decimals: 0 decimais', () {
        expect(UnitConverter.format(80.0, WeightUnit.kg, decimals: 0), '80 kg');
      });

      test('respeita o parâmetro decimals: 2 decimais', () {
        expect(UnitConverter.format(80.0, WeightUnit.kg, decimals: 2), '80.00 kg');
      });

      test('formato sempre termina com a unidade correta', () {
        expect(UnitConverter.format(50.0, WeightUnit.kg), endsWith('kg'));
        expect(UnitConverter.format(50.0, WeightUnit.lbs), endsWith('lbs'));
      });
    });
  });
}
