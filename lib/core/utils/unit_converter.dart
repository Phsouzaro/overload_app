enum WeightUnit { kg, lbs }

class UnitConverter {
  static const double _kgToLbs = 2.20462;

  static double toDisplay(double kg, WeightUnit unit) =>
      unit == WeightUnit.lbs ? kg * _kgToLbs : kg;

  static double fromDisplay(double value, WeightUnit unit) =>
      unit == WeightUnit.lbs ? value / _kgToLbs : value;

  static String label(WeightUnit unit) =>
      unit == WeightUnit.lbs ? 'lbs' : 'kg';

  /// Carga adicional de uma série de peso corporal, ex: "+10 kg " (vazio
  /// quando não há carga extra).
  static String extraLoad(double? kg, WeightUnit unit) {
    if (kg == null || kg <= 0) return '';
    final value = toDisplay(kg, unit);
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '+$text ${label(unit)} ';
  }

  static String format(double kg, WeightUnit unit, {int decimals = 1}) =>
      '${toDisplay(kg, unit).toStringAsFixed(decimals)} ${label(unit)}';
}
