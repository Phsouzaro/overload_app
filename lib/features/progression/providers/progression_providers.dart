import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/progression_repository.dart';
import '../../../core/progression/progression_registry.dart';
import '../../../core/progression/progression_strategy.dart';
import '../../../core/services/progression_service.dart';
import '../../../core/utils/unit_converter.dart';
import '../../settings/providers/settings_provider.dart';

final progressionRegistryProvider = Provider<ProgressionRegistry>(
  (_) => ProgressionRegistry.standard,
);

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  return ProgressionRepository(ref.watch(databaseProvider));
});

final progressionServiceProvider = Provider<ProgressionService>((ref) {
  final unit = ref.watch(settingsProvider).unit;
  return ProgressionService(
    ref.watch(databaseProvider),
    registry: ref.watch(progressionRegistryProvider),
    formatLoad: (kg) => UnitConverter.format(kg, unit),
  );
});

/// Estratégia e parâmetros já interpretados de uma config salva.
class ProgressionSetup {
  final ProgressionConfigEntry entry;
  final ProgressionStrategy strategy;
  final ProgressionConfig config;

  const ProgressionSetup(this.entry, this.strategy, this.config);

  /// Interpreta [entry]; `null` se a estratégia não existir mais ou os
  /// parâmetros forem ilegíveis.
  static ProgressionSetup? parse(
    ProgressionConfigEntry entry,
    ProgressionRegistry registry,
  ) {
    final strategy = registry.strategyFor(entry.strategy);
    if (strategy == null) return null;
    try {
      final params = (jsonDecode(entry.paramsJson) as Map)
          .cast<String, Object?>();
      return ProgressionSetup(entry, strategy, strategy.configFromJson(params));
    } on Object {
      return null;
    }
  }
}

/// Config gravada no início da sessão (por id), já interpretada.
final progressionSetupByIdProvider =
    FutureProvider.family<ProgressionSetup?, int>((ref, configId) async {
      final entry = await ref
          .watch(progressionRepositoryProvider)
          .configById(configId);
      if (entry == null) return null;
      return ProgressionSetup.parse(
        entry,
        ref.watch(progressionRegistryProvider),
      );
    });

/// Config de progressão em vigor do exercício (`null` = registro manual).
final activeProgressionConfigProvider =
    StreamProvider.family<ProgressionConfigEntry?, int>((ref, exerciseId) {
      return ref
          .watch(progressionRepositoryProvider)
          .watchActiveConfig(exerciseId);
    });

/// Recomendações geradas ao encerrar a sessão (para o resumo).
final sessionRecommendationsProvider =
    StreamProvider.family<List<RecommendationWithExercise>, int>((
      ref,
      sessionId,
    ) {
      return ref
          .watch(progressionRepositoryProvider)
          .watchSessionRecommendations(sessionId);
    });

/// Recomendações do exercício, mais recentes primeiro.
final exerciseRecommendationsProvider =
    StreamProvider.family<List<ProgressionRecommendationEntry>, int>((
      ref,
      exerciseId,
    ) {
      return ref
          .watch(progressionRepositoryProvider)
          .watchRecommendations(exerciseId);
    });
