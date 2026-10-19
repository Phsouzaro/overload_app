import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/features/active_session/widgets/session_notes_dialog.dart';

void main() {
  Future<String?> openAndClose(
    WidgetTester tester, {
    required String buttonText,
    String? type,
  }) async {
    String? result = 'não retornou';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showSessionNotesDialog(context, initial: 'Antiga');
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    if (type != null) await tester.enterText(find.byType(TextField), type);
    await tester.tap(find.text(buttonText));
    // Roda a animação de fechamento inteira: era aqui que o app quebrava.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    return result;
  }

  testWidgets('Salvar fecha o diálogo e devolve o texto', (tester) async {
    final result = await openAndClose(
      tester,
      buttonText: 'Salvar',
      type: 'Ombro incomodou',
    );
    expect(result, 'Ombro incomodou');
  });

  testWidgets('Cancelar fecha o diálogo e devolve null', (tester) async {
    final result = await openAndClose(
      tester,
      buttonText: 'Cancelar',
      type: 'descartar',
    );
    expect(result, isNull);
  });
}
