import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/progression_repository.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/features/progression/screens/progression_config_screen.dart';

import '../helpers/progression_fixtures.dart';
import '../helpers/widget_harness.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late ProgressionRepository repo;

  setUp(() async {
    db = await openTestDb();
    repo = ProgressionRepository(db);
  });

  tearDown(() => db.close());

  Future<Exercise> exercise({SetType type = SetType.weight}) async {
    final id = await insertExercise(db, name: 'Exercício Teste', setType: type);
    return (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingle();
  }

  /// Abre a tela a partir de um botão, para o "Salvar" poder voltar.
  Widget launcher(Exercise ex) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgressionConfigScreen(exercise: ex),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, Exercise ex) async {
    // Largura de celular (a padrão de teste é 800 × 600), alta o bastante
    // para a lista de métodos e o início dos parâmetros.
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpWithDb(tester, db, launcher(ex));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('padrão é "Sem progressão automática"', (tester) async {
    final ex = await exercise();
    await open(tester, ex);

    final manual = tester.widget<RadioListTile<StrategyId?>>(
      find.widgetWithText(
        RadioListTile<StrategyId?>,
        'Sem progressão automática',
      ),
    );
    expect(manual.value, isNull);
    expect(find.text('Parâmetros'), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    'escolher Progressão Dupla mostra parâmetros e exemplo calculado',
    (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão Dupla'));
      await tester.pumpAndSettle();

      expect(find.text('Parâmetros'), findsOneWidget);
      expect(find.text('Faixa de repetições: 8–12'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Topo da faixa: 12/12/12'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Próxima: 52.5 kg — 3 × 8–12'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('salvar grava a config com os parâmetros escolhidos', (
    tester,
  ) async {
    final ex = await exercise();
    await open(tester, ex);

    await tester.tap(find.text('Progressão Dupla'));
    await tester.pumpAndSettle();
    final addSet = find.byIcon(Icons.add_circle_outline).first; // 4 séries
    // Centraliza: no rodapé, o "Salvar" flutuante cobre o botão.
    await Scrollable.ensureVisible(tester.element(addSet), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(addSet);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final active = await repo.activeConfig(ex.id);
    expect(active!.strategy, StrategyId.doubleProgression);
    expect(active.incrementKg, 2.5);
    final params = jsonDecode(active.paramsJson) as Map;
    expect((params['sets'], params['repsMin'], params['repsMax']), (4, 8, 12));
    expect(find.text('abrir'), findsOneWidget); // voltou
    await unmount(tester);
  });

  testWidgets('voltar para "Sem progressão" desativa a config', (tester) async {
    final ex = await exercise();
    await repo.saveConfig(
      exerciseId: ex.id,
      strategy: StrategyId.doubleProgression,
      params: const {'sets': 3, 'repsMin': 8, 'repsMax': 12},
      incrementKg: 2.5,
      now: DateTime(2026, 3, 1),
    );
    await open(tester, ex);
    expect(find.text('Parâmetros'), findsOneWidget); // carregou a existente

    await tester.tap(find.text('Sem progressão automática'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(await repo.activeConfig(ex.id), isNull);
    await unmount(tester);
  });

  testWidgets('incremento inválido bloqueia o salvar', (tester) async {
    final ex = await exercise();
    await open(tester, ex);
    await tester.tap(find.text('Progressão Dupla'));
    await tester.pumpAndSettle();

    final increment = find.widgetWithText(TextField, 'Incremento de carga');
    await tester.scrollUntilVisible(
      increment,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(increment, '0');
    await tester.pumpAndSettle();

    expect(find.textContaining('incremento: informe'), findsOneWidget);
    final save = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(save.onPressed, isNull);
    await unmount(tester);
  });

  testWidgets('exercício por tempo não oferece progressão automática', (
    tester,
  ) async {
    final ex = await exercise(type: SetType.time);
    await open(tester, ex);

    expect(
      find.textContaining('não têm progressão automática'),
      findsOneWidget,
    );
    expect(find.text('Progressão Dupla'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });

  group('Progressão por RIR', () {
    testWidgets('mostra alvo, tolerância e exemplos com RIR', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão por RIR'));
      await tester.pumpAndSettle();

      expect(find.text('Tolerância de RIR'), findsOneWidget);
      expect(find.text('±1'), findsOneWidget);
      final noRir = find.textContaining('Topo sem RIR registrado');
      await tester.scrollUntilVisible(
        noRir,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Calculado pelo motor: sem RIR, pede o dado em vez de estimar.
      expect(find.textContaining('não estima o RIR'), findsOneWidget);
      expect(
        find.textContaining('Topo com RIR 0 (esforço alto)'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('salvar grava a estratégia por RIR', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão por RIR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final active = await repo.activeConfig(ex.id);
      expect(active!.strategy, StrategyId.rirBased);
      final params = jsonDecode(active.paramsJson) as Map;
      expect((params['targetRir'], params['rirTolerance']), (2, 1));
      await unmount(tester);
    });
  });

  group('Progressão por RPE', () {
    testWidgets('mostra alvo e exemplos calculados com RPE', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão por RPE'));
      await tester.pumpAndSettle();

      expect(find.text('Tolerância de RPE'), findsOneWidget);
      final noRpe = find.textContaining('Topo sem RPE registrado');
      await tester.scrollUntilVisible(
        noRpe,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('não é convertido em RPE'), findsWidgets);
      expect(
        find.textContaining('Topo com RPE 9 (esforço alto)'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('salvar grava a estratégia por RPE', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão por RPE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final active = await repo.activeConfig(ex.id);
      expect(active!.strategy, StrategyId.rpeBased);
      final params = jsonDecode(active.paramsJson) as Map;
      expect((params['targetRpe'], params['rpeTolerance']), (8.0, 0.5));
      await unmount(tester);
    });
  });

  group('Série Principal + Back-off', () {
    testWidgets('mostra a estrutura e o exemplo com papéis', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Série Principal + Back-off'));
      await tester.pumpAndSettle();

      expect(find.text('Séries de back-off'), findsOneWidget);
      expect(find.text('−15%'), findsOneWidget);
      final example = find.textContaining('Principal no topo');
      await tester.scrollUntilVisible(
        example,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // 50 kg × 6 → 52,5; back-off 52,5 × 0,85 = 44,6 → 45 (3 séries).
      expect(find.textContaining('Principal: 52.5 kg × 4–6'), findsWidgets);
      expect(find.textContaining('Back-off: 3 × 45.0 kg × 6–8'), findsWidgets);
      await unmount(tester);
    });

    testWidgets('não aparece para exercício de peso corporal', (tester) async {
      final ex = await exercise(type: SetType.bodyweight);
      await open(tester, ex);

      expect(find.text('Progressão Dupla'), findsOneWidget);
      expect(find.text('Série Principal + Back-off'), findsNothing);
      await unmount(tester);
    });

    testWidgets('salvar grava a estrutura', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Série Principal + Back-off'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final active = await repo.activeConfig(ex.id);
      expect(active!.strategy, StrategyId.topSetBackOff);
      final params = jsonDecode(active.paramsJson) as Map;
      expect((params['backOffSets'], params['backOffPercent']), (3, 15));
      await unmount(tester);
    });
  });

  group('Progressão em Ondas', () {
    /// Rola até [finder] e centraliza, longe do botão Salvar flutuante.
    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester) async {
      final option = find.text('Progressão em Ondas');
      await tester.scrollUntilVisible(
        option,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(option);
      await tester.pumpAndSettle();
    }

    testWidgets('mostra as ondas e o exemplo calculado', (tester) async {
      final ex = await exercise();
      await open(tester, ex);
      await choose(tester);

      expect(find.text('Onda 1 · 3×8'), findsOneWidget);
      expect(find.text('Onda 3 · 3×4'), findsOneWidget);
      final example = find.textContaining('Onda 1 completa');
      await tester.scrollUntilVisible(
        example,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Referência deduzida de 50 kg: 50 / 75% = 66,7 → 67,5. Onda 2 a 80%:
      // 54 → 55.
      expect(find.text('Próxima: 55.0 kg — 3 × 6'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('adicionar onda e mudar as reps de uma série', (tester) async {
      final ex = await exercise();
      await open(tester, ex);
      await choose(tester);

      final add = find.text('Adicionar onda');
      await reveal(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.text('Onda 4 · 3×4'), findsOneWidget);

      // Primeiro "−" de repetições da onda 4.
      await reveal(tester, find.text('Onda 4 · 3×4'));
      final wave4 = find.ancestor(
        of: find.text('Onda 4 · 3×4'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: wave4, matching: find.byIcon(Icons.remove)).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Onda 4 · 3/4/4'), findsOneWidget);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      final active = await repo.activeConfig(ex.id);
      expect(active!.strategy, StrategyId.waveLoading);
      final waves = (jsonDecode(active.paramsJson) as Map)['waves'] as List;
      expect(waves.length, 4);
      expect([for (final s in waves.last as List) (s as Map)['percent']], [
        90.0,
        90.0,
        90.0,
      ]);
      await unmount(tester);
    });

    testWidgets('carga de referência inválida bloqueia o salvar', (
      tester,
    ) async {
      final ex = await exercise();
      await open(tester, ex);
      await choose(tester);

      final field = find.widgetWithText(
        TextField,
        'Carga de referência (100%)',
      );
      await reveal(tester, field);
      await tester.enterText(field, 'abc');
      await tester.pumpAndSettle();
      final issue = find.textContaining(
        'a carga de referência deve ser maior que 0',
      );
      await reveal(tester, issue);
      expect(issue, findsOneWidget);
      // Sem exemplo e com o Salvar desabilitado enquanto houver problema.
      expect(find.text('Exemplo'), findsNothing);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
      await unmount(tester);
    });

    testWidgets('não aparece para exercício de peso corporal', (tester) async {
      final ex = await exercise(type: SetType.bodyweight);
      await open(tester, ex);

      expect(find.text('Progressão em Ondas'), findsNothing);
      await unmount(tester);
    });
  });

  group('Progressão Linear', () {
    testWidgets('mostra parâmetros e o exemplo de estagnação', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão Linear'));
      await tester.pumpAndSettle();

      expect(find.text('Repetições por série'), findsOneWidget);
      expect(find.text('Falhas seguidas toleradas'), findsOneWidget);
      final stalled = find.textContaining('3 falha(s) seguida(s)');
      await tester.scrollUntilVisible(
        stalled,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Padrão: reduzir 10% de 50 kg → 45 kg, calculado pelo motor.
      expect(find.text('Próxima: 45.0 kg — 3 × 5'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('salvar grava a Linear com os parâmetros', (tester) async {
      final ex = await exercise();
      await open(tester, ex);

      await tester.tap(find.text('Progressão Linear'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Revisar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Centraliza: no rodapé, o "Salvar" flutuante cobre o botão.
      await Scrollable.ensureVisible(
        tester.element(find.text('Revisar')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final active = await repo.activeConfig(ex.id);
      expect(active!.strategy, StrategyId.linear);
      final params = jsonDecode(active.paramsJson) as Map;
      expect(
        (params['sets'], params['targetReps'], params['stallPolicy']),
        (3, 5, 'review'),
      );
      await unmount(tester);
    });
  });
}
