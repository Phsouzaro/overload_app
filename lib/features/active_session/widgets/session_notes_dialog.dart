import 'package:flutter/material.dart';

/// Diálogo para escrever as anotações de uma sessão. Retorna o texto digitado,
/// ou `null` se o usuário cancelar.
Future<String?> showSessionNotesDialog(
  BuildContext context, {
  String? initial,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Anotações do treino'),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        maxLength: 1000,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Como foi o treino? Dores, ajustes, observações...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Salvar'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
