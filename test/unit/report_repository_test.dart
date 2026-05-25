import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/report_repository.dart';
import 'package:overload/core/database/tables.dart';

// ── Helper: banco de dados em memória ─────────────────────────────────────────

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

// ── Helpers de inserção ───────────────────────────────────────────────────────

Future<int> _insertExercise(
  AppDatabase db, {
  String name = 'Supino Fictício',
  String muscleGroup = 'Peito',
  SetType setType = SetType.weight,
}) =>
    db.into(db.exercises).insert(ExercisesCompanion.insert(
          name: name,
          muscleGroup: muscleGroup,
          setType: setType,
        ));

Future<int> _insertTemplate(AppDatabase db, {String name = 'Treino A'}) =>
    db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(name: name),
        );

Future<int> _insertSession(
  AppDatabase db,
  int templateId, {
  bool finished = true,
  DateTime? startedAt,
}) =>
    db.into(db.sessions).insert(SessionsCompanion.insert(
          templateId: templateId,
          startedAt: startedAt ?? DateTime(2024, 6, 1),
          finishedAt:
              finished ? Value(DateTime(2024, 6, 1, 1)) : const Value.absent(),
        ));

Future<int> _insertSessionExercise(
  AppDatabase db,
  int sessionId,
  int exerciseId, {
  int position = 0,
}) =>
    db.into(db.sessionExercises).insert(SessionExercisesCompanion.insert(
          sessionId: sessionId,
          exerciseId: exerciseId,
          position: position,
        ));

Future<void> _insertSet(
  AppDatabase db,
  int sessionExerciseId, {
  double? weightKg,
  int? reps,
  bool isWarmup = false,
  int position = 0,
  SetType setType = SetType.weight,
}) =>
    db.into(db.sessionSets).insert(SessionSetsCompanion.insert(
          sessionExerciseId: sessionExerciseId,
          setType: setType,
          position: position,
          weightKg: Value(weightKg),
          reps: Value(reps),
          isWarmup: Value(isWarmup),
        ));

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late ReportRepository repo;

  setUp(() async {
    db = _makeDb();
    repo = ReportRepository(db);
    await db.customSelect('SELECT 1').get(); // força inicialização do schema
  });

  tearDown(() => db.close());

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║ getExerciseHistory                                                       ║
  // ╚══════════════════════════════════════════════════════════════════════════╝

  group('ReportRepository.getExerciseHistory', () {
    test('retorna lista vazia quando não há sessões', () async {
      final exerciseId = await _insertExercise(db);
      final history = await repo.getExerciseHistory(exerciseId);
      expect(history, isEmpty);
    });

    test('não inclui sessões não finalizadas (sem finishedAt)', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId, finished: false);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 10);

      final history = await repo.getExerciseHistory(exId);
      expect(history, isEmpty);
    });

    test('inclui sessão finalizada com suas séries', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 10);

      final history = await repo.getExerciseHistory(exId);

      expect(history.length, 1);
      expect(history.first.sets.length, 1);
      expect(history.first.sets.first.weightKg, 100.0);
      expect(history.first.sets.first.reps, 10);
    });

    test('inclui séries de aquecimento junto com séries normais', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      await _insertSet(db, seId, weightKg: 60, reps: 10, isWarmup: true, position: 0);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 1);
      await _insertSet(db, seId, weightKg: 100, reps: 7, position: 2);

      final history = await repo.getExerciseHistory(exId);

      expect(history.first.sets.length, 3); // aquecimento + 2 séries normais
    });

    test('não retorna histórico de outro exercício', () async {
      final exSupino = await _insertExercise(db, name: 'Supino Fictício');
      final exAgach = await _insertExercise(db, name: 'Agachamento Fictício');
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exAgach);
      await _insertSet(db, seId, weightKg: 120, reps: 5);

      final history = await repo.getExerciseHistory(exSupino);
      expect(history, isEmpty);
    });

    test('retorna o nome do treino correto', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db, name: 'Meu Treino Especial');
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 5);

      final history = await repo.getExerciseHistory(exId);
      expect(history.first.templateName, 'Meu Treino Especial');
    });

    test('ordena por data decrescente (sessão mais recente primeiro)', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      // Sessão antiga
      final s1 = await db.into(db.sessions).insert(SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2024, 1, 1),
            finishedAt: Value(DateTime(2024, 1, 1, 1)),
          ));
      final se1 = await _insertSessionExercise(db, s1, exId);
      await _insertSet(db, se1, weightKg: 80, reps: 10);

      // Sessão recente
      final s2 = await db.into(db.sessions).insert(SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2024, 6, 1),
            finishedAt: Value(DateTime(2024, 6, 1, 1)),
          ));
      final se2 = await _insertSessionExercise(db, s2, exId);
      await _insertSet(db, se2, weightKg: 100, reps: 8);

      final history = await repo.getExerciseHistory(exId);

      expect(history.length, 2);
      // Mais recente primeiro
      expect(history[0].date, DateTime(2024, 6, 1));
      expect(history[1].date, DateTime(2024, 1, 1));
    });

    test('sessão sem séries não aparece no histórico', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      // sessionExercise criado mas sem nenhuma série inserida
      await _insertSessionExercise(db, sessionId, exId);

      final history = await repo.getExerciseHistory(exId);
      expect(history, isEmpty);
    });

    test('múltiplas sessões: cada uma aparece como entrada separada', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      for (var i = 0; i < 3; i++) {
        final s = await db.into(db.sessions).insert(SessionsCompanion.insert(
              templateId: tplId,
              startedAt: DateTime(2024, i + 1, 1),
              finishedAt: Value(DateTime(2024, i + 1, 1, 1)),
            ));
        final se = await _insertSessionExercise(db, s, exId);
        await _insertSet(db, se, weightKg: 80.0 + i * 5, reps: 10);
      }

      final history = await repo.getExerciseHistory(exId);
      expect(history.length, 3);
    });
  });

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║ getExerciseMaxWeight                                                     ║
  // ╚══════════════════════════════════════════════════════════════════════════╝

  group('ReportRepository.getExerciseMaxWeight', () {
    test('retorna null quando não há histórico', () async {
      final exId = await _insertExercise(db);
      expect(await repo.getExerciseMaxWeight(exId), isNull);
    });

    test('retorna o maior peso entre todas as séries', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      await _insertSet(db, seId, weightKg: 80, reps: 10, position: 0);
      await _insertSet(db, seId, weightKg: 100, reps: 5, position: 1);
      await _insertSet(db, seId, weightKg: 95, reps: 8, position: 2);

      expect(await repo.getExerciseMaxWeight(exId), 100.0);
    });

    test('ignora séries de aquecimento no cálculo do PR', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessionId, exId);
      // Série de aquecimento com peso maior — deve ser ignorada
      await _insertSet(db, seId, weightKg: 150, reps: 5, isWarmup: true, position: 0);
      // Série normal com peso menor — deve ser o PR
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 1);

      expect(await repo.getExerciseMaxWeight(exId), 100.0);
    });

    test('não inclui sessões não finalizadas no PR', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      // Sessão finalizada com 80 kg
      final s1 = await _insertSession(db, tplId, finished: true);
      final se1 = await _insertSessionExercise(db, s1, exId);
      await _insertSet(db, se1, weightKg: 80, reps: 10);

      // Sessão não finalizada com 200 kg (não deve contar)
      final s2 = await _insertSession(db, tplId, finished: false);
      final se2 = await _insertSessionExercise(db, s2, exId);
      await _insertSet(db, se2, weightKg: 200, reps: 5);

      expect(await repo.getExerciseMaxWeight(exId), 80.0);
    });

    test('PR de exercício diferente não interfere', () async {
      final exA = await _insertExercise(db, name: 'Exercício Fictício A');
      final exB = await _insertExercise(db, name: 'Exercício Fictício B');
      final tplId = await _insertTemplate(db);
      final sessionId = await _insertSession(db, tplId);

      final seA = await _insertSessionExercise(db, sessionId, exA);
      await _insertSet(db, seA, weightKg: 100, reps: 5);

      final seB = await _insertSessionExercise(db, sessionId, exB, position: 1);
      await _insertSet(db, seB, weightKg: 200, reps: 5);

      // PR de A não deve ser influenciado pelas séries de B
      expect(await repo.getExerciseMaxWeight(exA), 100.0);
      expect(await repo.getExerciseMaxWeight(exB), 200.0);
    });

    test('encontra PR entre múltiplas sessões', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      final s1 = await db.into(db.sessions).insert(SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2024, 1, 1),
            finishedAt: Value(DateTime(2024, 1, 1, 1)),
          ));
      final se1 = await _insertSessionExercise(db, s1, exId);
      await _insertSet(db, se1, weightKg: 90, reps: 5);

      final s2 = await db.into(db.sessions).insert(SessionsCompanion.insert(
            templateId: tplId,
            startedAt: DateTime(2024, 3, 1),
            finishedAt: Value(DateTime(2024, 3, 1, 1)),
          ));
      final se2 = await _insertSessionExercise(db, s2, exId);
      await _insertSet(db, se2, weightKg: 110, reps: 3); // novo PR

      expect(await repo.getExerciseMaxWeight(exId), 110.0);
    });
  });
}
