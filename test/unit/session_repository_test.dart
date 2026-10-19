import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm, Value;
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

    test('ignora séries vazias (pré-criadas e não preenchidas)', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 0);
      await _insertSet(db, seId, position: 1); // vazia

      final sets = await repo.getPreviousSets(tplId, exId);
      expect(sets.length, 1);
      expect(sets.first.weightKg, 100.0);
    });

    test(
        'pula a sessão mais recente quando ela só tem séries vazias e usa a '
        'anterior', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);

      final antiga =
          await _insertSession(db, tplId, startedAt: DateTime(2024, 1, 1));
      final seAntiga = await _insertSessionExercise(db, antiga, exId);
      await _insertSet(db, seAntiga, weightKg: 90, reps: 10);

      final recente =
          await _insertSession(db, tplId, startedAt: DateTime(2024, 2, 1));
      final seRecente = await _insertSessionExercise(db, recente, exId);
      await _insertSet(db, seRecente, position: 0);
      await _insertSet(db, seRecente, position: 1);

      final sets = await repo.getPreviousSets(tplId, exId);
      expect(sets.length, 1);
      expect(sets.first.weightKg, 90.0);
    });
  });

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║ getSessionSummary                                                        ║
  // ╚══════════════════════════════════════════════════════════════════════════╝

  group('SessionRepository.getSessionSummary', () {
    test('não conta séries vazias nem aquecimento', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 50, reps: 10, isWarmup: true);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 1);
      await _insertSet(db, seId, position: 2); // vazia
      await _insertSet(db, seId, position: 3); // vazia

      final summary = await repo.getSessionSummary(sessId);
      expect(summary.totalSets, 1);
      expect(summary.totalVolume, 800.0);
    });
  });

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║ finishSession / discardSession / startSession                            ║
  // ╚══════════════════════════════════════════════════════════════════════════╝

  group('SessionRepository.startSession — descanso por treino', () {
    Future<int> linkExercise(int tplId, int exId, {int? restOverride}) =>
        db.into(db.templateExercises).insert(
              TemplateExercisesCompanion.insert(
                templateId: tplId,
                exerciseId: exId,
                position: 0,
                restSecondsOverride: Value(restOverride),
              ),
            );

    Future<int?> sessionRest(int sessionId) async =>
        (await (db.select(db.sessionExercises)
                  ..where((se) => se.sessionId.equals(sessionId)))
                .getSingle())
            .restSeconds;

    test('usa o descanso definido no treino quando existe', () async {
      final exId = await _insertExercise(db); // padrão do exercício: 90s
      final tplId = await _insertTemplate(db);
      await linkExercise(tplId, exId, restOverride: 150);

      final sessId = await repo.startSession(tplId);
      expect(await sessionRest(sessId), 150);
    });

    test('sem override usa o padrão do exercício', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      await linkExercise(tplId, exId);

      final sessId = await repo.startSession(tplId);
      expect(await sessionRest(sessId), 90);
    });
  });

  group('SessionRepository — exercício extra na sessão', () {
    Future<Exercise> exercise(int id) =>
        (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingle();

    test('entra no fim da sessão, marcado como extra, sem mudar o treino',
        () async {
      final exA = await _insertExercise(db, name: 'Supino');
      final exB = await _insertExercise(db, name: 'Rosca');
      final tplId = await _insertTemplate(db);
      await db.into(db.templateExercises).insert(
            TemplateExercisesCompanion.insert(
                templateId: tplId, exerciseId: exA, position: 0),
          );
      final sessId = await repo.startSession(tplId);

      await repo.addExtraExercise(sessId, await exercise(exB));

      final ses = await (db.select(db.sessionExercises)
            ..where((se) => se.sessionId.equals(sessId))
            ..orderBy([(se) => OrderingTerm.asc(se.position)]))
          .get();
      expect(ses.map((se) => se.exerciseId), [exA, exB]);
      expect(ses.map((se) => se.isExtra), [false, true]);

      final links = await db.select(db.templateExercises).get();
      expect(links.map((te) => te.exerciseId), [exA]);
    });

    test('sem histórico cria uma série vazia; com histórico copia a quantidade',
        () async {
      final exNovo = await _insertExercise(db, name: 'Novo');
      final exComHist = await _insertExercise(db, name: 'Com histórico');
      final tplId = await _insertTemplate(db);

      final antiga = await _insertSession(db, tplId);
      final seAntiga = await _insertSessionExercise(db, antiga, exComHist);
      await _insertSet(db, seAntiga, weightKg: 50, reps: 10, position: 0);
      await _insertSet(db, seAntiga, weightKg: 50, reps: 9, position: 1);
      await _insertSet(db, seAntiga, weightKg: 50, reps: 8, position: 2);

      final sessId = await _insertSession(db, tplId, finished: false);
      await repo.addExtraExercise(sessId, await exercise(exNovo));
      await repo.addExtraExercise(sessId, await exercise(exComHist));

      Future<int> setCount(int exId) async {
        final se = await (db.select(db.sessionExercises)
              ..where((se) =>
                  se.sessionId.equals(sessId) & se.exerciseId.equals(exId)))
            .getSingle();
        return (await (db.select(db.sessionSets)
                  ..where((s) => s.sessionExerciseId.equals(se.id)))
                .get())
            .length;
      }

      expect(await setCount(exNovo), 1);
      expect(await setCount(exComHist), 3);
    });

    test('removeSessionExercise apaga o exercício e suas séries', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId, finished: false);
      await repo.addExtraExercise(sessId, await exercise(exId));
      final se = await db.select(db.sessionExercises).getSingle();

      await repo.removeSessionExercise(se.id);

      expect(await db.select(db.sessionExercises).get(), isEmpty);
      expect(await db.select(db.sessionSets).get(), isEmpty);
    });
  });

  group('SessionRepository.updateNotes', () {
    test('salva o texto sem espaços nas pontas', () async {
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);

      await repo.updateNotes(sessId, '  Ombro incomodou no supino \n');
      expect((await repo.getSession(sessId)).notes,
          'Ombro incomodou no supino');
    });

    test('texto vazio remove a anotação', () async {
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);

      await repo.updateNotes(sessId, 'Algo');
      await repo.updateNotes(sessId, '   ');
      expect((await repo.getSession(sessId)).notes, isNull);
    });
  });

  group('SessionRepository — sessão em andamento', () {
    test('getActiveSession retorna null quando todas estão finalizadas',
        () async {
      final tplId = await _insertTemplate(db);
      await _insertSession(db, tplId);

      expect(await repo.getActiveSession(), isNull);
    });

    test('getActiveSession retorna a sessão não finalizada com o treino',
        () async {
      final tplId = await _insertTemplate(db, name: 'Treino B');
      await _insertSession(db, tplId);
      final ativa = await _insertSession(db, tplId, finished: false);

      final active = await repo.getActiveSession();
      expect(active!.session.id, ativa);
      expect(active.templateName, 'Treino B');
    });

    test('watchActiveSession emite null depois de encerrar', () async {
      final tplId = await _insertTemplate(db);
      final ativa = await _insertSession(db, tplId, finished: false);

      final emissions = <int?>[];
      final sub = repo
          .watchActiveSession()
          .listen((a) => emissions.add(a?.session.id));
      await pumpEventQueue();
      await repo.finishSession(ativa);
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, ativa);
      expect(emissions.last, isNull);
    });
  });

  group('SessionRepository — ciclo de vida da sessão', () {
    test('getSession expõe startedAt/finishedAt usados para a duração',
        () async {
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId);

      final session = await repo.getSession(sessId);
      expect(session.startedAt, DateTime(2024, 1, 1));
      expect(session.finishedAt!.difference(session.startedAt),
          const Duration(hours: 2));
    });

    test('finishSession grava finishedAt para a duração do resumo', () async {
      final tplId = await _insertTemplate(db);
      final inicio = DateTime.now().subtract(const Duration(minutes: 45));
      final sessId =
          await _insertSession(db, tplId, finished: false, startedAt: inicio);

      await repo.finishSession(sessId);

      final session = await repo.getSession(sessId);
      final duracao = session.finishedAt!.difference(session.startedAt);
      expect(duracao.inMinutes, inInclusiveRange(44, 46));
    });

    test('finishSession remove séries vazias e mantém as preenchidas',
        () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final sessId = await _insertSession(db, tplId, finished: false);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 8, position: 0);
      await _insertSet(db, seId, position: 1);

      await repo.finishSession(sessId);

      final sets = await db.select(db.sessionSets).get();
      expect(sets.length, 1);
      expect(sets.first.weightKg, 100.0);

      final session = await (db.select(db.sessions)
            ..where((s) => s.id.equals(sessId)))
          .getSingle();
      expect(session.finishedAt, isNotNull);
    });

    test('finishSession não mexe nas séries de outras sessões', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final outra = await _insertSession(db, tplId);
      final seOutra = await _insertSessionExercise(db, outra, exId);
      await _insertSet(db, seOutra); // vazia, legado

      final sessId = await _insertSession(db, tplId, finished: false);
      await _insertSessionExercise(db, sessId, exId);

      await repo.finishSession(sessId);

      expect((await db.select(db.sessionSets).get()).length, 1);
    });

    test('discardSession apaga sessão, exercícios e séries', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      final mantida = await _insertSession(db, tplId);
      final seMantida = await _insertSessionExercise(db, mantida, exId);
      await _insertSet(db, seMantida, weightKg: 80, reps: 10);

      final sessId = await _insertSession(db, tplId, finished: false);
      final seId = await _insertSessionExercise(db, sessId, exId);
      await _insertSet(db, seId, weightKg: 100, reps: 8);

      await repo.discardSession(sessId);

      final sessions = await db.select(db.sessions).get();
      expect(sessions.map((s) => s.id), [mantida]);
      final ses = await db.select(db.sessionExercises).get();
      expect(ses.map((se) => se.id), [seMantida]);
      final sets = await db.select(db.sessionSets).get();
      expect(sets.length, 1);
      expect(sets.first.weightKg, 80.0);
    });

    test('startSession remove sessões não finalizadas abandonadas', () async {
      final exId = await _insertExercise(db);
      final tplId = await _insertTemplate(db);
      await db.into(db.templateExercises).insert(
            TemplateExercisesCompanion.insert(
              templateId: tplId,
              exerciseId: exId,
              position: 0,
            ),
          );

      final finalizada = await _insertSession(db, tplId);
      final seFin = await _insertSessionExercise(db, finalizada, exId);
      await _insertSet(db, seFin, weightKg: 100, reps: 8);

      final abandonada = await _insertSession(db, tplId, finished: false);
      final seAb = await _insertSessionExercise(db, abandonada, exId);
      await _insertSet(db, seAb, weightKg: 200, reps: 1);

      final novaId = await repo.startSession(tplId);

      final ids = (await db.select(db.sessions).get()).map((s) => s.id);
      expect(ids, containsAll([finalizada, novaId]));
      expect(ids, isNot(contains(abandonada)));

      // Nova sessão pré-cria 1 série vazia (baseada na sessão finalizada)
      final novaSe = await (db.select(db.sessionExercises)
            ..where((se) => se.sessionId.equals(novaId)))
          .getSingle();
      final novaSets = await (db.select(db.sessionSets)
            ..where((s) => s.sessionExerciseId.equals(novaSe.id)))
          .get();
      expect(novaSets.length, 1);
      expect(novaSets.first.weightKg, isNull);
    });
  });
}
