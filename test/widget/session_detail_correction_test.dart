import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/strategies/rir_based_progression.dart';
import 'package:overload/features/session_history/screens/session_detail_screen.dart';

import '../helpers/progression_fixtures.dart';
import '../helpers/widget_harness.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late int exId;
  late int sessionId;
  final started = DateTime.now().subtract(const Duration(hours: 3));

  setUp(() async {
    db = await openTestDb();
    exId = await insertExercise(db, name: 'Rosca Teste');
    final tplId = await insertTemplate(db);
    sessionId = await insertWorkout(
      db,
      templateId: tplId,
      exerciseId: exId,
      date: started,
      weightKg: 30,
      reps: const [10, 10, 10],
    );
  });

  tearDown(() => db.close());

  Widget screen() => SessionDetailScreen(
    sessionId: sessionId,
    templateName: 'Treino A',
    startedAt: started,
    finishedAt: started.add(const Duration(hours: 1)),
  );

  Future<List<SessionSet>> sets() => db.select(db.sessionSets).get();

  Future<void> correctFirstSet(WidgetTester tester, {required int rir}) async {
    await tester.tap(find.textContaining('30.0 kg × 10').first);
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da série'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '$rir'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Válida'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }

  testWidgets('tocar numa série corrige RIR e qualidade no banco', (
    tester,
  ) async {
    await pumpWithDb(tester, db, screen());
    await correctFirstSet(tester, rir: 2);

    final first = (await sets()).first;
    expect((first.rir, first.executionQuality), (2, ExecutionQuality.valid));
    expect(find.text('RIR 2'), findsOneWidget);
    expect(find.text('Série corrigida'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('correção não reavalia sozinha; "Reavaliar" gera sugestão', (
    tester,
  ) async {
    await ProgressionRepository(db).saveConfig(
      exerciseId: exId,
      strategy: StrategyId.rirBased,
      params: const RirBasedConfig(repsMin: 8, repsMax: 10).toJson(),
      incrementKg: 2.5,
      now: started.subtract(const Duration(days: 1)),
    );
    await pumpWithDb(tester, db, screen());
    await correctFirstSet(tester, rir: 2);

    expect(await db.select(db.progressionRecommendations).get(), isEmpty);

    await tester.tap(find.text('Reavaliar'));
    await tester.pumpAndSettle();

    final recs = await db.select(db.progressionRecommendations).get();
    expect(recs, hasLength(1));
    expect(recs.single.decision, RecommendationDecision.pending);
    expect(find.textContaining('Nova sugestão gerada'), findsOneWidget);
    await unmount(tester);
  });
}
