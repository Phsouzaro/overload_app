import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/unit_converter.dart';
import '../../reports/providers/report_providers.dart';
import '../../settings/providers/settings_provider.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseHistoryScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exercise.id));
    final unit = ref.watch(settingsProvider).unit;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (entries) => entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum registro ainda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final workingSets =
                      entry.sets.where((s) => !s.isWarmup).toList();
                  final maxWeight = workingSets
                      .map((s) => s.weightKg ?? 0)
                      .fold<double>(0, (a, b) => a > b ? a : b);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, dd/MM/yyyy', 'pt_BR')
                                          .format(entry.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      entry.templateName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (maxWeight > 0 &&
                                  exercise.setType == SetType.weight)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '↑ ${UnitConverter.format(maxWeight, unit)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: entry.sets.map((s) {
                              final label = _formatSet(s, unit);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: s.isWarmup
                                      ? Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer
                                          .withOpacity(0.4)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: s.isWarmup
                                            ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                            : null,
                                      ),
                                ),
                              );
                            }).toList(),
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

  String _formatSet(SessionSet s, WeightUnit unit) {
    return switch (s.setType) {
      SetType.weight => s.weightKg != null && s.reps != null
          ? '${UnitConverter.toDisplay(s.weightKg!, unit).toStringAsFixed(1)}×${s.reps}'
          : '—',
      SetType.time =>
        s.durationSeconds != null ? '${s.durationSeconds}s' : '—',
      SetType.bodyweight => s.reps != null ? '×${s.reps}' : '—',
    };
  }
}
