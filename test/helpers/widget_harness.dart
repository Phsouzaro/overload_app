import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/database_provider.dart';
import 'package:overload/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta [child] com o banco de teste e preferências vazias (kg).
Future<void> pumpWithDb(
  WidgetTester tester,
  AppDatabase db,
  Widget child,
) async {
  // Como no main.dart: telas formatam datas em pt_BR.
  await initializeDateFormatting('pt_BR');
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta a árvore antes de fechar o banco (encerra streams do drift).
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}
