import 'package:flutter/material.dart';

/// Diálogo para escrever as anotações de uma sessão. Retorna o texto digitado,
/// ou `null` se o usuário cancelar.
Future<String?> showSessionNotesDialog(
  BuildContext context, {
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SessionNotesDialog(initial: initial),
  );
}

// O controller pertence ao State do diálogo: assim só é descartado quando o
// diálogo sai da árvore, depois da animação de fechamento. Descartá-lo logo
// após o pop quebra o TextField que ainda está sendo animado.
class _SessionNotesDialog extends StatefulWidget {
  final String? initial;

  const _SessionNotesDialog({this.initial});

  @override
  State<_SessionNotesDialog> createState() => _SessionNotesDialogState();
}

class _SessionNotesDialogState extends State<_SessionNotesDialog> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anotações do treino'),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
