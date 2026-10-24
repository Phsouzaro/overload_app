import 'progression_enums.dart';
import 'progression_models.dart';

/// Regras compartilhadas entre estratégias. Ficam aqui para não serem
/// reimplementadas (e divergirem) em cada uma.
abstract final class ProgressionRules {
  /// Sem treinar o exercício por mais que isso, a recomendação pede revisão
  /// manual em vez de progredir.
  static const longBreakDays = 21;

  /// Séries de trabalho: preenchidas e que não são aquecimento.
  static List<SetRecord> workingSets(SessionRecord session) => [
    for (final s in session.sets)
      if (!s.isWarmup && (s.weightKg != null || s.reps != null)) s,
  ];

  /// Se a série pode comprovar que uma meta foi atingida.
  ///
  /// Falha técnica e execução inválida nunca comprovam. Qualidade não
  /// registrada comprova, a menos que a config exija marcação explícita.
  static bool countsTowardGoal(
    SetRecord set, {
    required bool requireMarkedValid,
  }) {
    return switch (set.quality) {
      ExecutionQuality.valid => true,
      ExecutionQuality.technicalFailure || ExecutionQuality.invalid => false,
      null => !requireMarkedValid,
    };
  }

  /// Alguma série de trabalho sem qualidade registrada (para avisar na
  /// justificativa que ela foi considerada válida).
  static bool hasUnrecordedQuality(Iterable<SetRecord> sets) =>
      sets.any((s) => s.quality == null);

  /// Arredonda [weightKg] para um múltiplo de [incrementKg] (o menor salto
  /// de carga disponível). Incremento ≤ 0 devolve o valor sem mudar.
  static double roundToIncrement(
    double weightKg,
    double incrementKg, {
    LoadRounding mode = LoadRounding.nearest,
  }) {
    if (incrementKg <= 0) return weightKg;
    final steps = weightKg / incrementKg;
    // Tolerância para erro de ponto flutuante (ex: 59.99999 passos).
    const eps = 1e-9;
    final rounded = switch (mode) {
      LoadRounding.nearest => steps.round(),
      LoadRounding.down => (steps + eps).floor(),
      LoadRounding.up => (steps - eps).ceil(),
    };
    // Corta resíduos binários (ex: 52.50000000001).
    return double.parse((rounded * incrementKg).toStringAsFixed(4));
  }

  /// Dias desde a sessão mais recente do histórico; `null` sem histórico.
  static int? daysSinceLastSession(List<SessionRecord> history, DateTime now) {
    if (history.isEmpty) return null;
    return now.difference(history.first.date).inDays;
  }

  static bool isLongBreak(List<SessionRecord> history, DateTime now) {
    final days = daysSinceLastSession(history, now);
    return days != null && days > longBreakDays;
  }
}

enum LoadRounding { nearest, down, up }
