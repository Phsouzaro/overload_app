import 'package:flutter/material.dart';

import '../../../core/database/repositories/progression_repository.dart';
import 'recommendation_card.dart';

/// Sugestões ainda não decididas, mostradas antes de iniciar um treino.
/// Retorna `true` para iniciar o treino e `false`/`null` se o usuário fechar.
/// Decidir é opcional: iniciar sem decidir mantém o comportamento padrão.
Future<bool?> showPendingRecommendationsSheet(
  BuildContext context,
  List<RecommendationWithExercise> pending,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Text(
                  'Sugestões pendentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Decida antes de começar, ou inicie assim mesmo: sem '
                  'decisão, o treino segue como sempre.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                for (final r in pending)
                  RecommendationCard(
                    key: ValueKey(r.recommendation.id),
                    recommendation: r.recommendation,
                    exercise: r.exercise,
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar treino'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
