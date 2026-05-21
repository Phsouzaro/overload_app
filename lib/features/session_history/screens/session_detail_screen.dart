import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/unit_converter.dart';
import '../../active_session/providers/session_providers.dart';
import '../../settings/providers/settings_provider.dart';

class SessionDetailScreen extends ConsumerWidget {
  final int sessionId;
  final String templateName;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.templateName,
    required this.startedAt,
    this.finishedAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;

    return Scaffold(
      appBar: AppBar(
        title: Text(templateName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(startedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ),
      ),
      body: FutureBuilder(
        future: ref
            .read(sessionRepositoryProvider)
            .getSessionDetail(sessionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data!;
          if (details.isEmpty) {
            return Center(
              child: Text(
                'Nenhum dado registrado',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline),
              ),
            );
          }

          // Header stats
          final allSets = details
              .expand((d) => d.sets)
              .where((s) => !s.isWarmup)
              .toList();
          final totalSets = allSets.length;
          final totalVolume = allSets.fold<double>(0, (sum, s) {
            if (s.weightKg != null && s.reps != null) {
              return sum + s.weightKg! * s.reps!;
            }
            return sum;
          });
          final duration = finishedAt != null
              ? finishedAt!.difference(startedAt).inSeconds
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumo
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (duration != null)
                        _StatItem(
                          icon: Icons.timer_outlined,
                          label: 'Duração',
                          value: _formatDuration(duration),
                        ),
                      _StatItem(
                        icon: Icons.fitness_center,
                        label: 'Séries',
                        value: '$totalSets',
                      ),
                      _StatItem(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Volume',
                        value: UnitConverter.format(totalVolume, unit,
                            decimals: 0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Exercícios
              ...details.map((d) => _ExerciseDetailCard(
                    detail: d,
                    unit: unit,
                  )),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min ${s}s';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final SessionSetDetail detail;
  final WeightUnit unit;

  const _ExerciseDetailCard({required this.detail, required this.unit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.exercise.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              detail.exercise.muscleGroup,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 8),
            ...detail.sets.asMap().entries.map((e) {
              final s = e.value;
              final label = _formatSet(s);
              final isWarmup = s.isWarmup;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isWarmup ? cs.tertiary : cs.onSurface,
                        ),
                      ),
                    ),
                    if (isWarmup) ...[
                      Icon(Icons.whatshot,
                          size: 12, color: cs.tertiary),
                      const SizedBox(width: 4),
                    ],
                    Text(label,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (s.toFailure) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.bolt, size: 12, color: cs.error),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatSet(SessionSet s) {
    return switch (s.setType) {
      SetType.weight => s.weightKg != null && s.reps != null
          ? '${UnitConverter.toDisplay(s.weightKg!, unit).toStringAsFixed(1)} ${UnitConverter.label(unit)} × ${s.reps}'
          : '—',
      SetType.time =>
        s.durationSeconds != null ? '${s.durationSeconds}s' : '—',
      SetType.bodyweight => s.reps != null ? '× ${s.reps} reps' : '—',
    };
  }
}
