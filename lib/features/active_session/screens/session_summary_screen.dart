import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_providers.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final int sessionId;
  final String templateName;
  final int elapsedSeconds;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.templateName,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: ref
              .read(sessionRepositoryProvider)
              .getSessionSummary(sessionId),
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Treino concluído!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                          icon: Icons.timer_outlined,
                          label: 'Duração',
                          value: _formatDuration(elapsedSeconds),
                        ),
                        _StatCard(
                          icon: Icons.fitness_center,
                          label: 'Séries',
                          value: data != null ? '${data.totalSets}' : '—',
                        ),
                        _StatCard(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Volume',
                          value: data != null
                              ? '${data.totalVolume.toStringAsFixed(0)}kg'
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    FilledButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Voltar ao Início'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
