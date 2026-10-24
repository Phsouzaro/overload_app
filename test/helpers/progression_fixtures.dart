import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/progression/progression_enums.dart';
import 'package:overload/core/progression/progression_models.dart';
import 'package:overload/core/progression/progression_strategy.dart';

/// Banco em memória com o schema criado (inclui os exercícios do seed).
Future<AppDatabase> openTestDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  return db;
}

Future<int> insertExercise(
  AppDatabase db, {
  String name = 'Supino Fictício',
  SetType setType = SetType.weight,
}) => db
    .into(db.exercises)
    .insert(
      ExercisesCompanion.insert(
        name: name,
        muscleGroup: 'Peito',
        setType: setType,
      ),
    );

Future<int> insertTemplate(AppDatabase db, {String name = 'Treino A'}) => db
    .into(db.workoutTemplates)
    .insert(WorkoutTemplatesCompanion.insert(name: name));

Future<void> linkToTemplate(AppDatabase db, int templateId, int exerciseId) =>
    db
        .into(db.templateExercises)
        .insert(
          TemplateExercisesCompanion.insert(
            templateId: templateId,
            exerciseId: exerciseId,
            position: 0,
          ),
        );

Future<int> insertSession(
  AppDatabase db,
  int templateId, {
  required DateTime startedAt,
  bool finished = true,
}) => db
    .into(db.sessions)
    .insert(
      SessionsCompanion.insert(
        templateId: templateId,
        startedAt: startedAt,
        finishedAt: finished
            ? Value(startedAt.add(const Duration(hours: 1)))
            : const Value.absent(),
      ),
    );

Future<int> insertSessionExercise(
  AppDatabase db,
  int sessionId,
  int exerciseId, {
  int? configId,
  bool excluded = false,
}) => db
    .into(db.sessionExercises)
    .insert(
      SessionExercisesCompanion.insert(
        sessionId: sessionId,
        exerciseId: exerciseId,
        position: 0,
        progressionConfigId: Value(configId),
        excludeFromProgression: Value(excluded),
      ),
    );

Future<void> insertSet(
  AppDatabase db,
  int sessionExerciseId, {
  double? weightKg,
  int? reps,
  bool isWarmup = false,
  int? rir,
  double? rpe,
  ExecutionQuality? quality,
  SetRole? role,
  int position = 0,
}) => db
    .into(db.sessionSets)
    .insert(
      SessionSetsCompanion.insert(
        sessionExerciseId: sessionExerciseId,
        setType: SetType.weight,
        position: position,
        weightKg: Value(weightKg),
        reps: Value(reps),
        isWarmup: Value(isWarmup),
        rir: Value(rir),
        rpe: Value(rpe),
        executionQuality: Value(quality),
        setRole: Value(role),
      ),
    );

/// Sessão finalizada com um exercício e séries de trabalho [reps] em [weightKg].
Future<int> insertWorkout(
  AppDatabase db, {
  required int templateId,
  required int exerciseId,
  required DateTime date,
  double weightKg = 50,
  List<int> reps = const [10, 10, 10],
  int? configId,
  bool excluded = false,
  bool finished = true,
}) async {
  final sessionId = await insertSession(
    db,
    templateId,
    startedAt: date,
    finished: finished,
  );
  final seId = await insertSessionExercise(
    db,
    sessionId,
    exerciseId,
    configId: configId,
    excluded: excluded,
  );
  for (var i = 0; i < reps.length; i++) {
    await insertSet(db, seId, weightKg: weightKg, reps: reps[i], position: i);
  }
  return sessionId;
}

// ── Estratégia de teste ─────────────────────────────────────────────────────
// Usada só para exercitar a infraestrutura antes de existirem estratégias
// reais. Não faz parte do app.

class FakeConfig extends ProgressionConfig {
  final int sets;
  final double nextWeightKg;
  @override
  final bool requireMarkedValid;

  const FakeConfig({
    this.sets = 3,
    this.nextWeightKg = 52.5,
    this.requireMarkedValid = false,
  });

  @override
  StrategyId get strategy => StrategyId.doubleProgression;

  @override
  Map<String, Object?> toJson() => {
    'sets': sets,
    'nextWeightKg': nextWeightKg,
    'requireMarkedValid': requireMarkedValid,
  };
}

class FakeStrategy extends ProgressionStrategy<FakeConfig> {
  final List<ProgressionInput<FakeConfig>> inputs = [];
  final bool throwOnEvaluate;

  FakeStrategy({this.throwOnEvaluate = false});

  @override
  StrategyId get id => StrategyId.doubleProgression;

  @override
  String get displayName => 'Estratégia de teste';

  @override
  FakeConfig configFromJson(Map<String, Object?> json) => FakeConfig(
    sets: json['sets'] as int,
    nextWeightKg: (json['nextWeightKg'] as num).toDouble(),
    requireMarkedValid: json['requireMarkedValid'] as bool? ?? false,
  );

  @override
  List<ConfigIssue> validate(FakeConfig config) => [
    if (config.sets < 1) const ConfigIssue('sets', 'mínimo 1 série'),
  ];

  @override
  ProgressionResult evaluate(ProgressionInput<FakeConfig> input) {
    inputs.add(input);
    if (throwOnEvaluate) throw StateError('falha simulada');
    final count = (input.previousState['count'] as int? ?? 0) + 1;
    return ProgressionResult(
      status: RecommendationStatus.increaseWeight,
      reasonCode: 'fake',
      explanation: 'Sugestão de teste',
      currentWeightKg: input.history.first.sets.first.weightKg,
      analyzedSessionIds: [for (final s in input.history) s.sessionId],
      met: const [Criterion('fakeMet', 'critério atendido')],
      unmet: const [Criterion('fakeUnmet', 'critério não atendido')],
      nextTargets: [
        for (var i = 0; i < input.config.sets; i++)
          SetTarget(
            weightKg: input.config.nextWeightKg,
            repsMin: 8,
            repsMax: 12,
          ),
      ],
      state: {'count': count},
    );
  }
}
