import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/rest_formatter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/session_repository.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/one_rm_calculator.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/progression/strategies/double_progression.dart';
import '../../progression/providers/progression_providers.dart';
import '../../reports/providers/report_providers.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/session_providers.dart';
import 'set_details_sheet.dart';
import 'set_row_widget.dart';

class ExerciseSessionCard extends ConsumerWidget {
  final SessionExerciseWithExercise item;
  final int templateId;
  final void Function(int restSeconds, String exerciseName) onSetConfirmed;

  const ExerciseSessionCard({
    super.key,
    required this.item,
    required this.templateId,
    required this.onSetConfirmed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = item.exercise;
    final restSeconds =
        item.sessionExercise.restSeconds ?? exercise.restSeconds;
    final setsAsync = ref.watch(sessionSetsProvider(item.sessionExercise.id));
    final prevAsync = ref.watch(
      previousSetsProvider(
          (templateId: templateId, exerciseId: exercise.id)),
    );
    final prWeight = ref
        .watch(exercisePrWeightProvider(exercise.id))
        .valueOrNull;
    final settings = ref.watch(settingsProvider);
    final unit = settings.unit;
    final repo = ref.read(sessionRepositoryProvider);
    final configId = item.sessionExercise.progressionConfigId;
    final setup = configId == null
        ? null
        : ref.watch(progressionSetupByIdProvider(configId)).valueOrNull;
    final askRir = (setup?.config.usesRir ?? false) || settings.alwaysRecordRir;
    final showDetails = setup != null || settings.alwaysRecordRir;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _iconForType(exercise.setType),
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          Flexible(
                            child: Text(exercise.muscleGroup,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          if (item.sessionExercise.isExtra) ...[
                            const SizedBox(width: 6),
                            const _ExtraBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (item.sessionExercise.isExtra)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        size: 20, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Remover desta sessão',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _confirmRemove(context, ref),
                  ),
                // ── Botão de histórico ──────────────────────────────────
                IconButton(
                  icon: Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Histórico do exercício',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showHistorySheet(context, ref, unit),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.timer_outlined, size: 14),
                const SizedBox(width: 4),
                Text(formatRest(restSeconds),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),

            // ── Sessão anterior ──────────────────────────────────────────
            prevAsync.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (prev) {
                if (prev.isEmpty) return const SizedBox();

                double? maxWeight;
                for (final s in prev) {
                  if (s.weightKg != null && !s.isWarmup) {
                    if (maxWeight == null || s.weightKg! > maxWeight) {
                      maxWeight = s.weightKg!;
                    }
                  }
                }

                final summary =
                    prev.map((s) => _formatSet(s, unit)).join('  ·  ');
                final cs = Theme.of(context).colorScheme;

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Anterior: $summary',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ),
                      if (maxWeight != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '↑ ${UnitConverter.format(maxWeight, unit)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // ── Progressão (meta da sessão) ──────────────────────────────
            if (setup != null)
              _ProgressionLine(
                setup: setup,
                sets: setsAsync.valueOrNull ?? const [],
                unit: unit,
              ),

            const Divider(height: 20),

            // ── Cabeçalho das colunas ─────────────────────────────────────
            if (exercise.setType == SetType.weight)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 30),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(UnitConverter.label(unit),
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center)),
                    const SizedBox(width: 24),
                    Expanded(
                        child: Text('reps',
                            style: Theme.of(context).textTheme.labelSmall,
                            textAlign: TextAlign.center)),
                    const SizedBox(width: 96),
                  ],
                ),
              ),

            // ── Séries ───────────────────────────────────────────────────
            setsAsync.when(
              loading: () => const SizedBox(),
              error: (e, _) => Text('Erro: $e'),
              data: (sets) {
                final oneRm = _computeOneRm(sets, exercise.setType);
                final prevSets = prevAsync.valueOrNull ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...sets.asMap().entries.map(
                          (e) {
                            final s = e.value;
                            // Meta aceita tem prioridade sobre a sessão
                            // anterior; reps começam na base da faixa.
                            final planned = s.targetWeightKg != null ||
                                s.targetRepsMin != null;
                            final prev = e.key < prevSets.length
                                ? prevSets[e.key]
                                : null;
                            return SetRowWidget(
                            key: ValueKey(s.id),
                            set: s,
                            index: e.key + 1,
                            prWeight: prWeight,
                            unit: unit,
                            hintWeight:
                                planned ? s.targetWeightKg : prev?.weightKg,
                            hintReps: planned ? s.targetRepsMin : prev?.reps,
                            hintDuration: prev?.durationSeconds,
                            onDetails: showDetails
                                ? () => _editDetails(context, ref, s, askRir)
                                : null,
                            onConfirm: (weight, reps, duration,
                                isWarmup, toFailure) async {
                              await repo.updateSet(
                                e.value.id,
                                weightKg: weight,
                                reps: reps,
                                durationSeconds: duration,
                                isWarmup: isWarmup,
                                toFailure: toFailure,
                              );
                              onSetConfirmed(
                                  restSeconds, exercise.name);
                            },
                            onDelete: () => repo.deleteSet(e.value.id),
                          );
                          },
                        ),
                    if (oneRm != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.insights,
                                size: 14,
                                color:
                                    Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '1RM estimado: ~${UnitConverter.format(oneRm, unit)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            // ── Adicionar série ──────────────────────────────────────────
            TextButton.icon(
              onPressed: () =>
                  repo.addSet(item.sessionExercise.id, exercise.setType),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar Série'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDetails(
    BuildContext context,
    WidgetRef ref,
    SessionSet set,
    bool askRir,
  ) async {
    final details = await showSetDetailsSheet(
      context,
      rir: set.rir,
      quality: set.executionQuality,
      askRir: askRir,
    );
    if (details == null) return;
    await ref.read(sessionRepositoryProvider).updateSetDetails(
          set.id,
          rir: details.rir,
          quality: details.quality,
        );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover ${item.exercise.name}?'),
        content: const Text(
            'O exercício sai desta sessão junto com as séries registradas '
            'nele. O treino salvo não muda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(sessionRepositoryProvider)
          .removeSessionExercise(item.sessionExercise.id);
    }
  }

  double? _computeOneRm(List<SessionSet> sets, SetType type) {
    if (type != SetType.weight) return null;
    for (var i = sets.length - 1; i >= 0; i--) {
      final s = sets[i];
      if (s.weightKg != null &&
          s.reps != null &&
          s.reps! >= 3 &&
          !s.isWarmup) {
        return OneRmCalculator.estimate(s.weightKg!, s.reps!);
      }
    }
    return null;
  }

  IconData _iconForType(SetType type) => switch (type) {
        SetType.weight => Icons.fitness_center,
        SetType.time => Icons.timer_outlined,
        SetType.bodyweight => Icons.accessibility_new,
      };


  String _formatSet(SessionSet s, WeightUnit unit) => switch (s.setType) {
        SetType.weight => s.weightKg != null
            ? '${UnitConverter.toDisplay(s.weightKg!, unit).toStringAsFixed(1)}×${s.reps ?? '?'}'
            : '?×${s.reps ?? '?'}',
        SetType.time => '${s.durationSeconds ?? '?'}s',
        SetType.bodyweight =>
          '${UnitConverter.extraLoad(s.weightKg, unit)}×${s.reps ?? '?'}',
      };

  void _showHistorySheet(
      BuildContext context, WidgetRef ref, WeightUnit unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExerciseHistorySheet(
        exercise: item.exercise,
        unit: unit,
      ),
    );
  }
}

/// Linha compacta com a estratégia, a meta aceita e o avanço na faixa.
class _ProgressionLine extends StatelessWidget {
  final ProgressionSetup setup;
  final List<SessionSet> sets;
  final WeightUnit unit;

  const _ProgressionLine({
    required this.setup,
    required this.sets,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = setup.config;

    final planned = sets.where((s) => s.targetWeightKg != null).firstOrNull;
    final parts = <String>[
      setup.strategy.displayName,
      if (config.summary.isNotEmpty) config.summary,
      if (planned != null)
        'Meta ${UnitConverter.format(planned.targetWeightKg!, unit)}',
    ];

    // Avanço na faixa: séries de trabalho já confirmadas no topo.
    String? progress;
    if (config is DoubleProgressionConfig) {
      final atTop = sets
          .where((s) => !s.isWarmup && (s.reps ?? 0) >= config.repsMax)
          .length;
      if (sets.any((s) => s.reps != null)) {
        progress = 'Topo da faixa: ${atTop.clamp(0, config.sets)}/${config.sets}';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
          if (progress != null)
            Text(progress, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Marca de exercício adicionado só nesta sessão.
class _ExtraBadge extends StatelessWidget {
  const _ExtraBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Extra',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onTertiaryContainer,
        ),
      ),
    );
  }
}

// ── Bottom sheet: histórico completo do exercício ─────────────────────────────

class _ExerciseHistorySheet extends ConsumerWidget {
  final Exercise exercise;
  final WeightUnit unit;

  const _ExerciseHistorySheet({
    required this.exercise,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exercise.id));
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        exercise.muscleGroup,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.history_rounded, color: cs.primary),
              ],
            ),
          ),

          const Divider(height: 16),

          // Lista de sessões
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: cs.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum histórico ainda.\nConclua um treino para ver as cargas aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final workingSets = entry.sets
                        .where((s) => !s.isWarmup)
                        .toList();
                    final warmupSets = entry.sets
                        .where((s) => s.isWarmup)
                        .toList();

                    // Maior carga da sessão (não-aquecimento)
                    double? maxWeight;
                    for (final s in workingSets) {
                      if (s.weightKg != null) {
                        if (maxWeight == null || s.weightKg! > maxWeight) {
                          maxWeight = s.weightKg!;
                        }
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Data + treino + PR chip
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(entry.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      entry.templateName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: cs.outline),
                                    ),
                                  ],
                                ),
                              ),
                              if (maxWeight != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '↑ ${UnitConverter.format(maxWeight, unit)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Séries de trabalho
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...workingSets.map((s) => _SetChip(
                                    set: s,
                                    unit: unit,
                                    isWarmup: false,
                                    cs: cs,
                                  )),
                              if (warmupSets.isNotEmpty)
                                ...warmupSets.map((s) => _SetChip(
                                      set: s,
                                      unit: unit,
                                      isWarmup: true,
                                      cs: cs,
                                    )),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    if (diff < 7) return 'há $diff dias';
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

class _SetChip extends StatelessWidget {
  final SessionSet set;
  final WeightUnit unit;
  final bool isWarmup;
  final ColorScheme cs;

  const _SetChip({
    required this.set,
    required this.unit,
    required this.isWarmup,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label();
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWarmup
            ? cs.tertiaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarmup
              ? cs.tertiary.withValues(alpha: 0.4)
              : cs.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWarmup) ...[
            Icon(Icons.whatshot, size: 11, color: cs.tertiary),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isWarmup ? cs.tertiary : cs.onSurface,
            ),
          ),
          if (set.toFailure) ...[
            const SizedBox(width: 3),
            Icon(Icons.bolt, size: 11, color: cs.error),
          ],
        ],
      ),
    );
  }

  String? _label() => switch (set.setType) {
        SetType.weight => set.weightKg != null && set.reps != null
            ? '${UnitConverter.toDisplay(set.weightKg!, unit).toStringAsFixed(1)} ${UnitConverter.label(unit)} × ${set.reps}'
            : null,
        SetType.time =>
          set.durationSeconds != null ? '${set.durationSeconds}s' : null,
        SetType.bodyweight =>
          set.reps != null
              ? '${UnitConverter.extraLoad(set.weightKg, unit)}× ${set.reps} reps'
              : null,
      };
}
