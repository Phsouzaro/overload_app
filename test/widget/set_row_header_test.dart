import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/utils/unit_converter.dart';
import 'package:overload/features/active_session/widgets/set_row_widget.dart';

void main() {
  SessionSet set(SetType type) => SessionSet(
    id: 1,
    sessionExerciseId: 1,
    setType: type,
    isWarmup: false,
    toFailure: false,
    position: 0,
  );

  Future<void> pump(
    WidgetTester tester,
    SetType type, {
    bool details = false,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SetRowHeader(
                type: type,
                unit: WeightUnit.kg,
                showDetails: details,
              ),
              SetRowWidget(
                set: set(type),
                index: 1,
                unit: WeightUnit.kg,
                onConfirm: (_, _, _, _, _) async {},
                onDelete: () {},
                onDetails: details ? () {} : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// O rótulo [label] está centralizado acima do botão com [icon].
  void expectAbove(WidgetTester tester, String label, IconData icon) {
    final text = tester.getCenter(find.text(label)).dx;
    final button = tester.getCenter(find.byIcon(icon)).dx;
    expect(text, closeTo(button, 0.5), reason: label);
  }

  testWidgets('carga: cada botão tem o nome logo acima', (tester) async {
    await pump(tester, SetType.weight);

    expectAbove(tester, 'Aquec.', Icons.whatshot);
    expectAbove(tester, 'Falha', Icons.bolt);
    expectAbove(tester, 'Feita', Icons.check_circle_outline);
    expect(find.text('Detal.'), findsNothing);
    // Campos também alinhados.
    expect(
      tester.getCenter(find.text('kg').first).dx,
      closeTo(tester.getCenter(find.byType(TextField).first).dx, 0.5),
    );
    expect(
      tester.getCenter(find.text('reps').first).dx,
      closeTo(tester.getCenter(find.byType(TextField).last).dx, 0.5),
    );
  });

  testWidgets('com estratégia: rótulo do botão de detalhes', (tester) async {
    await pump(tester, SetType.weight, details: true);

    expectAbove(tester, 'Detal.', Icons.tune);
    expectAbove(tester, 'Feita', Icons.check_circle_outline);
  });

  testWidgets('tempo: sem "Falha", campo em segundos', (tester) async {
    await pump(tester, SetType.time);

    expect(find.text('Falha'), findsNothing);
    expect(find.text('seg'), findsWidgets);
    expectAbove(tester, 'Aquec.', Icons.whatshot);
    expectAbove(tester, 'Feita', Icons.check_circle_outline);
  });

  testWidgets('peso corporal: carga adicional e reps', (tester) async {
    await pump(tester, SetType.bodyweight);

    expect(find.text('+kg'), findsWidgets);
    expectAbove(tester, 'Falha', Icons.bolt);
  });
}
