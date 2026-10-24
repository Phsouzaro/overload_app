import 'progression_enums.dart';
import 'progression_models.dart';

/// Parâmetros de uma estratégia. Cada estratégia define os seus: o motor não
/// presume campos comuns além destes.
abstract class ProgressionConfig {
  const ProgressionConfig();

  StrategyId get strategy;

  /// Exigir execução marcada como válida. Desligado (padrão), séries sem
  /// qualidade registrada contam como válidas para metas de repetição.
  bool get requireMarkedValid;

  Map<String, Object?> toJson();
}

/// Entrada de uma avaliação. Tudo que a estratégia precisa vem aqui: ela não
/// acessa banco, relógio nem configurações globais.
class ProgressionInput<C extends ProgressionConfig> {
  final C config;
  final ExerciseContext exercise;

  /// Sessões finalizadas do exercício, mais recente primeiro, já filtradas
  /// por `baselineFrom` e sem sessões marcadas para não avaliar.
  final List<SessionRecord> history;

  /// `ProgressionResult.state` da recomendação anterior com a mesma config.
  final Map<String, Object?> previousState;

  /// Momento da avaliação, injetado para o resultado ser reproduzível.
  final DateTime now;

  const ProgressionInput({
    required this.config,
    required this.exercise,
    required this.history,
    required this.now,
    this.previousState = const {},
  });
}

/// Contrato de uma estratégia de progressão.
///
/// Implementações devem ser puras e determinísticas: a mesma entrada gera
/// sempre o mesmo resultado. Para adicionar uma estratégia, implemente esta
/// classe e registre-a em `ProgressionRegistry.standard`.
abstract class ProgressionStrategy<C extends ProgressionConfig> {
  const ProgressionStrategy();

  StrategyId get id;

  /// Nome exibido ao usuário.
  String get displayName;

  C configFromJson(Map<String, Object?> json);

  /// Lista vazia = configuração válida.
  List<ConfigIssue> validate(C config);

  ProgressionResult evaluate(ProgressionInput<C> input);

  // Pontos de entrada para quem só conhece o tipo base da config (o registry
  // guarda `ProgressionStrategy` sem o genérico). Montam a entrada com o tipo
  // concreto `C`; passar `ProgressionInput<ProgressionConfig>` direto para
  // `evaluate` falharia em tempo de execução.

  List<ConfigIssue> validateConfig(ProgressionConfig config) =>
      validate(config as C);

  ProgressionResult evaluateWith({
    required ProgressionConfig config,
    required ExerciseContext exercise,
    required List<SessionRecord> history,
    required DateTime now,
    Map<String, Object?> previousState = const {},
  }) {
    return evaluate(
      ProgressionInput<C>(
        config: config as C,
        exercise: exercise,
        history: history,
        now: now,
        previousState: previousState,
      ),
    );
  }
}
