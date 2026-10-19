import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';
import '../screens/active_session_screen.dart';

/// Abre a tela da sessão em andamento.
void resumeSession(BuildContext context, ActiveSessionSummary active) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ActiveSessionScreen(
        sessionId: active.session.id,
        templateId: active.session.templateId,
        templateName: active.templateName,
      ),
    ),
  );
}

Future<bool> _confirmDiscard(BuildContext context, String templateName) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar treino?'),
      content: Text(
          'As séries registradas em "$templateName" serão apagadas.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return confirm == true;
}

/// Antes de iniciar um treino novo: se já existe um em andamento, pergunta se
/// o usuário quer retomá-lo ou descartá-lo. Retorna `true` quando pode seguir
/// com o novo treino.
Future<bool> ensureNoActiveSession(BuildContext context, WidgetRef ref) async {
  final active = await ref.read(sessionRepositoryProvider).getActiveSession();
  if (active == null || !context.mounted) return active == null;

  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Treino em andamento'),
      content: Text(
          '"${active.templateName}" ainda não foi encerrado. '
          'Iniciar um novo treino descarta o que foi registrado nele.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'discard'),
          child: const Text('Descartar e iniciar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'resume'),
          child: const Text('Retomar'),
        ),
      ],
    ),
  );

  if (!context.mounted) return false;
  if (choice == 'resume') {
    resumeSession(context, active);
    return false;
  }
  if (choice == 'discard') {
    await ref.read(sessionRepositoryProvider).discardSession(active.session.id);
    return true;
  }
  return false;
}

/// Card exibido na tela inicial enquanto há um treino não encerrado.
class ActiveSessionBanner extends ConsumerWidget {
  const ActiveSessionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionProvider).valueOrNull;
    if (active == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final minutes =
        DateTime.now().difference(active.session.startedAt).inMinutes;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_outline, color: cs.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Treino em andamento: ${active.templateName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2),
              child: Text(
                minutes < 1 ? 'Iniciado agora' : 'Iniciado há $minutes min',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onPrimaryContainer),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    if (await _confirmDiscard(context, active.templateName)) {
                      await ref
                          .read(sessionRepositoryProvider)
                          .discardSession(active.session.id);
                    }
                  },
                  child: const Text('Descartar'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => resumeSession(context, active),
                  child: const Text('Retomar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
