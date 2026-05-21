import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/session_repository.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/one_rm_calculator.dart';
import '../providers/session_providers.dart';
import 'set_row_widget.dart';

class ExerciseSessionCard extends ConsumerWidget {
  final SessionExerciseWithExercise item;
  final int templateId;
  final void Function(int restSeconds) onSetConfirmed;

  const ExerciseSessionCard({
    super.key,
    required this.item,
    required this.templateId,
    required this.onSetConfirmed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = item.exercise;
    final setsAsync = ref.watch(sessionSetsProvider(item.sessionExercise.id));
    final prevAsync = ref.watch(
      previousSetsProvider(
          (templateId: templateId, exerciseId: exercise.id)),
    );
    final prWeight = ref
        .watch(exercisePrWeightProvider(exercise.id))
        .valueOrNull;
    final repo = ref.read(sessionRepositoryProvider);

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
                      Text(exercise.muscleGroup,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.timer_outlined, size: 14),
                const SizedBox(width: 4),
                Text(_formatRest(exercise.restSeconds),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),

            // ── Sessão anterior ──────────────────────────────────────────
            prevAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
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

                final summary = prev.map(_formatSet).join('  ·  ');
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
                            '↑ ${maxWeight.toStringAsFixed(1)} kg',
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

            const Divider(height: 20),

            // ── Cabeçalho das colunas ─────────────────────────────────────
            if (exercise.setType == SetType.weight)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 30),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text('kg',
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
                          (e) => SetRowWidget(
                            key: ValueKey(e.value.id),
                            set: e.value,
                            index: e.key + 1,
                            prWeight: prWeight,
                            hintWeight: e.key < prevSets.length
                                ? prevSets[e.key].weightKg
                                : null,
                            hintReps: e.key < prevSets.length
                                ? prevSets[e.key].reps
                                : null,
                            hintDuration: e.key < prevSets.length
                                ? prevSets[e.key].durationSeconds
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
                              onSetConfirmed(exercise.restSeconds);
                            },
                            onDelete: () => repo.deleteSet(e.value.id),
                          ),
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
                              '1RM estimado: ~${oneRm.toStringAsFixed(1)}kg',
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

  String _formatRest(int s) {
    if (s == 0) return 'Sem descanso';
    if (s < 60) return '${s}s';
    return '${s ~/ 60}min${s % 60 > 0 ? ' ${s % 60}s' : ''}';
  }

  String _formatSet(SessionSet s) => switch (s.setType) {
        SetType.weight =>
          '${s.weightKg?.toStringAsFixed(1) ?? '?'}×${s.reps ?? '?'}',
        SetType.time => '${s.durationSeconds ?? '?'}s',
        SetType.bodyweight => '×${s.reps ?? '?'}',
      };
}
