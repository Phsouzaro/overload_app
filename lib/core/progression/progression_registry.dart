import 'progression_enums.dart';
import 'progression_strategy.dart';

/// Estratégias disponíveis, por identificador.
class ProgressionRegistry {
  final Map<StrategyId, ProgressionStrategy> _strategies;

  ProgressionRegistry(Iterable<ProgressionStrategy> strategies)
    : _strategies = {for (final s in strategies) s.id: s};

  /// Estratégias do app. Cada etapa do plano registra a sua aqui.
  static final standard = ProgressionRegistry(const []);

  ProgressionStrategy? strategyFor(StrategyId id) => _strategies[id];

  Iterable<ProgressionStrategy> get all => _strategies.values;
}
