import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/unit_converter.dart';

// Provider preenchido no main.dart antes do runApp
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

class SettingsState {
  final WeightUnit unit;
  final int defaultRestSeconds;

  /// Mostrar o registro de RIR em todos os exercícios, mesmo sem estratégia
  /// que use RIR.
  final bool alwaysRecordRir;

  /// Mostrar o registro de RPE em todos os exercícios.
  final bool alwaysRecordRpe;

  const SettingsState({
    this.unit = WeightUnit.kg,
    this.defaultRestSeconds = 90,
    this.alwaysRecordRir = false,
    this.alwaysRecordRpe = false,
  });

  SettingsState copyWith({
    WeightUnit? unit,
    int? defaultRestSeconds,
    bool? alwaysRecordRir,
    bool? alwaysRecordRpe,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      alwaysRecordRir: alwaysRecordRir ?? this.alwaysRecordRir,
      alwaysRecordRpe: alwaysRecordRpe ?? this.alwaysRecordRpe,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _unitKey = 'weight_unit';
  static const _restKey = 'default_rest_seconds';
  static const _alwaysRirKey = 'always_record_rir';
  static const _alwaysRpeKey = 'always_record_rpe';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final unitStr = prefs.getString(_unitKey);
    final restSecs = prefs.getInt(_restKey) ?? 90;
    return SettingsState(
      unit: unitStr == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
      defaultRestSeconds: restSecs,
      alwaysRecordRir: prefs.getBool(_alwaysRirKey) ?? false,
      alwaysRecordRpe: prefs.getBool(_alwaysRpeKey) ?? false,
    );
  }

  Future<void> setAlwaysRecordRir(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_alwaysRirKey, value);
    state = state.copyWith(alwaysRecordRir: value);
  }

  Future<void> setAlwaysRecordRpe(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_alwaysRpeKey, value);
    state = state.copyWith(alwaysRecordRpe: value);
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

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
