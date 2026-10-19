import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/unit_converter.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/session_providers.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final int sessionId;
  final String templateName;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.templateName,
  });

  Future<({Session session, ({int totalSets, double totalVolume}) summary})>
      _load(WidgetRef ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    return (
      session: await repo.getSession(sessionId),
      summary: await repo.getSessionSummary(sessionId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _load(ref),
          builder: (context, snapshot) {
            final data = snapshot.data?.summary;
            final session = snapshot.data?.session;
            final duration = session?.finishedAt
                ?.difference(session.startedAt)
                .inSeconds;
            final unit = ref.read(settingsProvider).unit;
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
                          value: duration != null
                              ? _formatDuration(duration)
                              : '—',
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
                              ? UnitConverter.format(data.totalVolume, unit,
                                  decimals: 0)
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
