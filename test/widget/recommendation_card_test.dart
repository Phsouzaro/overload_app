import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/features/progression/widgets/recommendation_card.dart';

import '../helpers/progression_fixtures.dart';
import '../helpers/widget_harness.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late ProgressionRepository repo;
  late Exercise exercise;

  setUp(() async {
    db = await openTestDb();
    repo = ProgressionRepository(db);
    final exId = await insertExercise(db, name: 'Supino Teste');
    exercise = await (db.select(
      db.exercises,
    )..where((e) => e.id.equals(exId))).getSingle();
  });

  tearDown(() => db.close());

  Future<ProgressionRecommendationEntry> recommend({
    RecommendationStatus status = RecommendationStatus.increaseWeight,
    List<SetTarget> targets = const [
      SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12),
      SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12),
      SetTarget(weightKg: 52.5, repsMin: 8, repsMax: 12),
    ],
  }) async {
    final tplId = await insertTemplate(db);
    final sessionId = await insertWorkout(
      db,
      templateId: tplId,
      exerciseId: exercise.id,
      date: DateTime(2026, 4, 1),
    );
    final configId = await repo.saveConfig(
      exerciseId: exercise.id,
      strategy: StrategyId.doubleProgression,
      params: const {'sets': 3, 'repsMin': 8, 'repsMax': 12},
      incrementKg: 2.5,
      now: DateTime(2026, 3, 1),
    );
    final id = await repo.insertRecommendation(
      exerciseId: exercise.id,
      configId: configId,
      strategy: StrategyId.doubleProgression,
      sourceSessionId: sessionId,
      generatedAt: DateTime(2026, 4, 1),
      result: ProgressionResult(
        status: status,
        reasonCode: 'r',
        explanation: 'Você concluiu 3 séries de 12 repetições com 50 kg.',
        nextTargets: targets,
        met: const [Criterion('topOfRange', 'Todas as séries com 12 reps')],
      ),
    );
    return (db.select(
      db.progressionRecommendations,
    )..where((r) => r.id.equals(id))).getSingle();
  }

  Future<RecommendationDecision> decisionOf(int id) async => (await (db.select(
    db.progressionRecommendations,
  )..where((r) => r.id.equals(id))).getSingle()).decision;

  Widget card(ProgressionRecommendationEntry rec) => Scaffold(
    body: SingleChildScrollView(
      child: RecommendationCard(recommendation: rec, exercise: exercise),
    ),
  );

  testWidgets('mostra título, justificativa e a próxima sessão sugerida', (
    tester,
  ) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    expect(find.text('Progressão identificada!'), findsOneWidget);
    expect(find.textContaining('3 séries de 12'), findsOneWidget);
    // Mesmo formato de carga do resto do app (UnitConverter.format).
    expect(find.text('52.5 kg — 3 × 8–12'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('nada é decidido sem toque do usuário', (tester) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    expect(await decisionOf(rec.id), RecommendationDecision.pending);
    await unmount(tester);
  });

  testWidgets('Aceitar grava a decisão e mostra a confirmação', (tester) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    await tester.tap(find.text('Aceitar sugestão'));
    await tester.pumpAndSettle();

    expect(await decisionOf(rec.id), RecommendationDecision.accepted);
    expect(find.textContaining('Sugestão aceita'), findsOneWidget);
    expect(find.text('Aceitar sugestão'), findsNothing);
    await unmount(tester);
  });

  testWidgets('Manter carga atual grava "kept"', (tester) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    await tester.tap(find.text('Manter carga atual'));
    await tester.pumpAndSettle();

    expect(await decisionOf(rec.id), RecommendationDecision.kept);
    await unmount(tester);
  });

  testWidgets('Ajustar grava as metas escolhidas', (tester) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    await tester.tap(find.text('Ajustar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Carga'), '51,25');
    await tester.enterText(find.widgetWithText(TextField, 'Reps mín.'), '6');
    await tester.enterText(find.widgetWithText(TextField, 'Reps máx.'), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final saved = await (db.select(
      db.progressionRecommendations,
    )..where((r) => r.id.equals(rec.id))).getSingle();
    expect(saved.decision, RecommendationDecision.adjusted);
    final targets = ProgressionRepository.decodeTargets(
      saved.finalTargetsJson!,
    );
    expect(targets, hasLength(3));
    expect(
      targets,
      everyElement(const SetTarget(weightKg: 51.25, repsMin: 6, repsMax: 10)),
    );
    await unmount(tester);
  });

  testWidgets('Justificativa lista os critérios avaliados', (tester) async {
    final rec = await recommend();
    await pumpWithDb(tester, db, card(rec));

    await tester.tap(find.text('Justificativa'));
    await tester.pumpAndSettle();

    expect(find.text('Todas as séries com 12 reps'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('dados insuficientes: só "Entendi", sem metas', (tester) async {
    final rec = await recommend(
      status: RecommendationStatus.insufficientData,
      targets: const [],
    );
    await pumpWithDb(tester, db, card(rec));

    expect(find.text('Dados insuficientes'), findsOneWidget);
    expect(find.text('Aceitar sugestão'), findsNothing);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();

    expect(await decisionOf(rec.id), RecommendationDecision.dismissed);
    await unmount(tester);
  });

  testWidgets('principal + back-off: texto agrupa por papel', (tester) async {
    final rec = await recommend(
      targets: const [
        SetTarget(role: SetRole.topSet, weightKg: 72.5, repsMin: 4, repsMax: 6),
        SetTarget(
          role: SetRole.backOff,
          weightKg: 62.5,
          repsMin: 8,
          repsMax: 10,
        ),
        SetTarget(
          role: SetRole.backOff,
          weightKg: 62.5,
          repsMin: 8,
          repsMax: 10,
        ),
        SetTarget(
          role: SetRole.backOff,
          weightKg: 62.5,
          repsMin: 8,
          repsMax: 10,
        ),
      ],
    );
    await pumpWithDb(tester, db, card(rec));

    expect(
      find.text('Principal: 72.5 kg × 4–6  ·  Back-off: 3 × 62.5 kg × 8–10'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('Ajustar com papéis: campos separados, estrutura mantida', (
    tester,
  ) async {
    final rec = await recommend(
      targets: const [
        SetTarget(
          role: SetRole.topSet,
          weightKg: 72.5,
          repsMin: 4,
          repsMax: 6,
          rpe: 9,
        ),
        SetTarget(
          role: SetRole.backOff,
          weightKg: 62.5,
          repsMin: 8,
          repsMax: 10,
        ),
        SetTarget(
          role: SetRole.backOff,
          weightKg: 62.5,
          repsMin: 8,
          repsMax: 10,
        ),
      ],
    );
    await pumpWithDb(tester, db, card(rec));

    await tester.tap(find.text('Ajustar'));
    await tester.pumpAndSettle();
    expect(find.text('Série principal'), findsOneWidget);
    expect(find.text('Back-off'), findsOneWidget);

    // Muda só a carga da principal (primeiro campo "Carga").
    await tester.enterText(
      find.widgetWithText(TextField, 'Carga').first,
      '71,25',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final saved = await (db.select(
      db.progressionRecommendations,
    )..where((r) => r.id.equals(rec.id))).getSingle();
    final targets = ProgressionRepository.decodeTargets(
      saved.finalTargetsJson!,
    );
    expect(targets.map((t) => (t.role, t.weightKg)), [
      (SetRole.topSet, 71.25),
      (SetRole.backOff, 62.5),
      (SetRole.backOff, 62.5),
    ]);
    // O RPE-alvo da principal não se perde no ajuste.
    expect(targets.first.rpe, 9.0);
    await unmount(tester);
  });
}
