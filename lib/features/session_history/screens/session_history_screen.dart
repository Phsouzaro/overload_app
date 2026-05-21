import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../active_session/providers/session_providers.dart';
import 'session_detail_screen.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(finishedSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (sessions) => sessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum treino concluído ainda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final duration = s.session.finishedAt != null
                      ? s.session.finishedAt!
                          .difference(s.session.startedAt)
                      : null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.fitness_center,
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(s.templateName),
                    subtitle: Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'pt_BR')
                          .format(s.session.startedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: duration != null
                        ? Text(
                            _formatDuration(duration.inSeconds),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline,
                                ),
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(
                          sessionId: s.session.id,
                          templateName: s.templateName,
                          startedAt: s.session.startedAt,
                          finishedAt: s.session.finishedAt,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
