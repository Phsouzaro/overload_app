import 'package:drift/drift.dart';

import '../progression/progression_enums.dart';

enum SetType { weight, time, bodyweight }

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get setType => textEnum<SetType>()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  // Grupo do treino na tela inicial (ex: GYM, HOME); nulo = sem grupo (v5).
  TextColumn get groupName => text().nullable()();
}

class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get restSecondsOverride => integer().nullable()();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

class SessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()();
  // Descanso usado nesta sessão (override do treino ou padrão do exercício),
  // copiado no início. Nulo em sessões anteriores à v3: usa o do exercício.
  IntColumn get restSeconds => integer().nullable()();
  // Exercício adicionado durante a sessão, fora do treino salvo (v4).
  BoolColumn get isExtra => boolean().withDefault(const Constant(false))();

  // ── Progressão (v6) ──
  // Config vigente quando a sessão começou: preserva qual estratégia valeu.
  IntColumn get progressionConfigId =>
      integer().nullable().references(ProgressionConfigs, #id)();
  // Recomendação cujas metas foram aplicadas nesta sessão.
  IntColumn get recommendationId =>
      integer().nullable().references(ProgressionRecommendations, #id)();
  // Deload planejado ou sessão atípica: fica fora da avaliação.
  BoolColumn get excludeFromProgression =>
      boolean().withDefault(const Constant(false))();
}

class SessionSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionExerciseId =>
      integer().references(SessionExercises, #id)();
  TextColumn get setType => textEnum<SetType>()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get toFailure => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();

  // ── Progressão (v6). Nulos no histórico antigo = "não registrado". ──
  IntColumn get rir => integer().nullable()(); // 0–5 (5 = "5 ou mais")
  RealColumn get rpe => real().nullable()(); // 6–10, passos de 0,5
  TextColumn get executionQuality =>
      textEnum<ExecutionQuality>().nullable()();
  TextColumn get setRole => textEnum<SetRole>().nullable()();
  // Meta planejada, copiada da recomendação aceita no início da sessão.
  RealColumn get targetWeightKg => real().nullable()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
}

/// Configuração de progressão de um exercício. Versionada: editar insere uma
/// linha nova e marca a anterior com `supersededAt`, para que recomendações
/// antigas continuem apontando para a versão que as gerou.
@DataClassName('ProgressionConfigEntry')
class ProgressionConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get strategy => textEnum<StrategyId>()();
  // Parâmetros próprios da estratégia (cada uma tem os seus).
  TextColumn get paramsJson => text()();
  RealColumn get incrementKg => real()();
  DateTimeColumn get createdAt => dateTime()();
  // Preenchido quando a versão é substituída ou a estratégia é desativada.
  DateTimeColumn get supersededAt => dateTime().nullable()();
  // "Nova referência": histórico anterior a esta data é ignorado.
  DateTimeColumn get baselineFrom => dateTime().nullable()();
}

/// Recomendação gerada ao fim de uma sessão, com a decisão do usuário.
/// Nunca é reescrita após decidida (auditoria).
@DataClassName('ProgressionRecommendationEntry')
class ProgressionRecommendations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get configId => integer().references(ProgressionConfigs, #id)();
  TextColumn get strategy => textEnum<StrategyId>()();
  DateTimeColumn get generatedAt => dateTime()();
  IntColumn get sourceSessionId => integer().references(Sessions, #id)();
  TextColumn get analyzedSessionIdsJson => text()();
  TextColumn get status => textEnum<RecommendationStatus>()();
  TextColumn get reasonCode => text()();
  TextColumn get explanation => text()();
  TextColumn get criteriaMetJson => text()();
  TextColumn get criteriaUnmetJson => text()();
  RealColumn get currentWeightKg => real().nullable()();
  TextColumn get recommendedTargetsJson => text()();
  TextColumn get strategyStateJson => text()();
  TextColumn get decision => textEnum<RecommendationDecision>()
      .withDefault(Constant(RecommendationDecision.pending.name))();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  // Metas finais quando o usuário ajusta a sugestão.
  TextColumn get finalTargetsJson => text().nullable()();
}

class BodyWeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weightKg => real()();
  DateTimeColumn get recordedAt => dateTime()();
}
