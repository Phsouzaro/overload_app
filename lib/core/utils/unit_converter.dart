enum WeightUnit { kg, lbs }

class UnitConverter {
  static const double _kgToLbs = 2.20462;

  static double toDisplay(double kg, WeightUnit unit) =>
      unit == WeightUnit.lbs ? kg * _kgToLbs : kg;

  static double fromDisplay(double value, WeightUnit unit) =>
      unit == WeightUnit.lbs ? value / _kgToLbs : value;

  static String label(WeightUnit unit) =>
      unit == WeightUnit.lbs ? 'lbs' : 'kg';

  static String format(double kg, WeightUnit unit, {int decimals = 1}) =>
      '${toDisplay(kg, unit).toStringAsFixed(decimals)} ${label(unit)}';
}
