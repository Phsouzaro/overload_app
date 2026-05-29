import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/session_repository.dart';
import 'package:overload/core/database/tables.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<int> _insertExercise(AppDatabase db, {String name = 'Supino'}) =>
    db.into(db.exercises).insert(ExercisesCompanion.insert(
          name: name,
          muscleGroup: 'Peito',
          setType: SetType.weight,
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
          startedAt: startedAt ?? DateTime(2024, 1, 1),
          finishedAt:
              finished ? Value(DateTime(2024, 1, 1, 2)) : const Value.absent(),
        ));

Future<int> _insertSessionExercise(
        AppDatabase db, int sessionId, int exerciseId) =>
    db.into(db.sessionExercises).insert(SessionExercisesCompanion.insert(
          sessionId: sessionId,
          exerciseId: exerciseId,
          position: 0,
        ));

Future<void> _insertSet(
  AppDatabase db,
  int sessionExerciseId, {
  double? weightKg,
  int? reps,
  bool isWarmup = false,
  int position = 0,
}) =>
    db.into(db.sessionSets).insert(SessionSetsCompanion.insert(
          sessionExerciseId: sessionExerciseId,
          setType: SetType.weight,
          position: position,
          weightKg: Value(weightKg),
          reps: Value(reps),
          isWarmup: Value(isWarmup),
        ));

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late SessionRepository repo;

  setUp(() async {
    db = _makeDb();
    repo = SessionRepository(db);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║ getPreviousSets — busca global por exercício                             ║
  // ╚══════════════════════════════════════════════════════════════════════════╝

  group('SessionRepository.getPreviousSets — busca global por exercício', () {
    test('retorna vazio quando nunca houve sessão com esse exercício', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      final sets = await repo.getPreviousSets(tplId, exId);
      expect(sets, isEmpty);
    });

    test('retorna séries da última sessão do mesmo template', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 0);
      await _insertSet(db, seId, weightKg: 100, reps: 7, position: 1);

      final sets = await repo.getPreviousSets(tplId, exId);
      expect(sets.length, 2);
      expect(sets.first.weightKg, 100.0);
    });

    test(
        'retorna séries de OUTRO template quando o template atual nunca '
        'teve aquele exercício', () async {
      final exId = await _insertExercise(db, name: 'Hip Thrust');

      // Template A: já tem histórico de Hip Thrust
      final tplA = await _insertTemplate(db, name: 'ELA - Segunda');
      final sessA = await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              templateId: tplA,
              startedAt: DateTime(2024, 3, 1),
              finishedAt: Value(DateTime(2024, 3, 1, 2)),
            ),
          );
      final seA = await _insertSessionExercise(db, sessA, exId);
      await _insertSet(db, seA, weightKg: 80, reps: 10);

      // Template B: NUNCA foi usado (importado recentemente)
      final tplB = await _insertTemplate(db, name: 'ELA - Sexta');

      // Consultando para o template B → deve encontrar o histórico do template A
      final sets = await repo.getPreviousSets(tplB, exId);
      expect(sets.length, 1);
      expect(sets.first.weightKg, 80.0);
    });

    test('retorna a sessão MAIS RECENTE quando há múltiplos treinos com o '
        'mesmo exercício', () async {
      final exId = await _insertExercise(db, name: 'Agachamento');
      final tplA = await _insertTemplate(db, name: 'Treino A');
      final tplB = await _insertTemplate(db, name: 'Treino B');

      // Sessão antiga (Treino A) — 80 kg
      final sOld = await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              templateId: tplA,
              startedAt: DateTime(2024, 1, 1),
              finishedAt: Value(DateTime(2024, 1, 1, 2)),
            ),
          );
      final seOld = await _insertSessionExercise(db, sOld, exId);
      await _insertSet(db, seOld, weightKg: 80, reps: 10);

      // Sessão recente (Treino B) — 100 kg
      final sNew = await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              templateId: tplB,
              startedAt: DateTime(2024, 6, 1),
              finishedAt: Value(DateTime(2024, 6, 1, 2)),
            ),
          );
      final seNew = await _insertSessionExercise(db, sNew, exId);
      await _insertSet(db, seNew, weightKg: 100, reps: 8);

      // Qualquer template que pergunte deve receber a sessão mais recente (100 kg)
      final setsForA = await repo.getPreviousSets(tplA, exId);
      final setsForB = await repo.getPreviousSets(tplB, exId);

      expect(setsForA.first.weightKg, 100.0); // não mais o 80 kg do próprio A
      expect(setsForB.first.weightKg, 100.0);
    });

    test('ignora séries de aquecimento', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 60, reps: 10, isWarmup: true, position: 0);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 1);

      final sets = await repo.getPreviousSets(tplId, exId);
      // Apenas a série de trabalho (não aquecimento)
      expect(sets.length, 1);
      expect(sets.first.weightKg, 100.0);
    });

    test('não retorna dados de sessão não finalizada', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      // Sessão em andamento (sem finishedAt)
      final sessId = await _insertSession(db, tplId, finished: false);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 120, reps: 5);

      final sets = await repo.getPreviousSets(tplId, exId);
      expect(sets, isEmpty);
    });

    test('não mistura séries de exercícios diferentes', () async {
      final exSupino = await _insertExercise(db, name: 'Supino');
      final exAgach = await _insertExercise(db, name: 'Agachamento');
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);

      final seSupino = await _insertSessionExercise(db, sessId, exSupino);
      await _insertSet(db, seSupino, weightKg: 100, reps: 8);

      final seAgach = await _insertSessionExercise(db, sessId, exAgach);
      await _insertSet(db, seAgach, weightKg: 120, reps: 5);

      final setsSupino = await repo.getPreviousSets(tplId, exSupino);
      final setsAgach = await repo.getPreviousSets(tplId, exAgach);

      expect(setsSupino.first.weightKg, 100.0);
      expect(setsAgach.first.weightKg, 120.0);
    });
  });
}
