// Enums do mecanismo de progressão. São gravados no banco pelo nome
// (`textEnum`): renomear um valor exige migration dos dados existentes.

/// Estratégias de progressão disponíveis (ver docs/PROGRESSAO.md).
enum StrategyId {
  doubleProgression,
  linear,
  rirBased,
  rpeBased,
  topSetBackOff,
  waveLoading,
}

/// Resultado da avaliação para a próxima sessão.
enum RecommendationStatus {
  increaseWeight,
  increaseReps,
  maintain,
  decreaseWeight,
  deloadSuggested,
  insufficientData,
  manualReview,
}

/// O que o usuário fez com a recomendação. Só `accepted` e `adjusted` mudam
/// as metas da próxima sessão.
enum RecommendationDecision {
  pending,
  accepted,
  kept,
  adjusted,
  dismissed,

  /// Substituída por uma recomendação mais nova antes de ser decidida.
  superseded,
}

/// Qualidade da execução de uma série. Ausente (`null` no banco) significa
/// "não registrada".
enum ExecutionQuality {
  valid,

  /// A técnica deixou de atender ao padrão. Não é o mesmo que falha muscular
  /// (`toFailure`): a série conta como esforço, mas não comprova meta.
  technicalFailure,
  invalid,
}

/// Papel da série dentro da estrutura do exercício. Aquecimento continua sendo
/// `isWarmup`; ausente (`null`) em séries de trabalho comuns e no histórico.
enum SetRole { work, topSet, backOff, wave }
