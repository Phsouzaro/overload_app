import 'progression_enums.dart';
import 'progression_strategy.dart';
import 'strategies/double_progression.dart';
import 'strategies/linear_progression.dart';
import 'strategies/rir_based_progression.dart';
import 'strategies/rpe_based_progression.dart';

/// Estratégias disponíveis, por identificador.
class ProgressionRegistry {
  final Map<StrategyId, ProgressionStrategy> _strategies;

  ProgressionRegistry(Iterable<ProgressionStrategy> strategies)
    : _strategies = {for (final s in strategies) s.id: s};

  /// Estratégias do app. Cada etapa do plano registra a sua aqui.
  static final standard = ProgressionRegistry(const [
    DoubleProgressionStrategy(),
    LinearProgressionStrategy(),
    RirBasedStrategy(),
    RpeBasedStrategy(),
  ]);

  ProgressionStrategy? strategyFor(StrategyId id) => _strategies[id];

  Iterable<ProgressionStrategy> get all => _strategies.values;
}
