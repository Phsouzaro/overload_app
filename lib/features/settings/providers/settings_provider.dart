import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/unit_converter.dart';

// Provider preenchido no main.dart antes do runApp
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

class SettingsState {
  final WeightUnit unit;
  final int defaultRestSeconds;

  const SettingsState({
    this.unit = WeightUnit.kg,
    this.defaultRestSeconds = 90,
  });

  SettingsState copyWith({WeightUnit? unit, int? defaultRestSeconds}) {
    return SettingsState(
      unit: unit ?? this.unit,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _unitKey = 'weight_unit';
  static const _restKey = 'default_rest_seconds';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final unitStr = prefs.getString(_unitKey);
    final restSecs = prefs.getInt(_restKey) ?? 90;
    return SettingsState(
      unit: unitStr == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
      defaultRestSeconds: restSecs,
    );
  }

  Future<void> setUnit(WeightUnit unit) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_unitKey, unit.name);
    state = state.copyWith(unit: unit);
  }

  Future<void> setDefaultRest(int seconds) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_restKey, seconds);
    state = state.copyWith(defaultRestSeconds: seconds);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
