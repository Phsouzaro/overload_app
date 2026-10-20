import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/repositories/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<List<WorkoutTemplate>> templates() =>
      repo.watchActiveTemplates().first;

  group('grupos de treino', () {
    test('createTemplate grava o grupo, sem espaços nas pontas', () async {
      await repo.createTemplate('Treino A', group: '  GYM ');
      await repo.createTemplate('Sem grupo', group: '   ');

      final all = await templates();
      expect(all.map((t) => t.groupName), ['GYM', null]);
    });

    test('setTemplateGroup troca e remove o grupo', () async {
      final id = await repo.createTemplate('Treino A', group: 'GYM');

      await repo.setTemplateGroup(id, 'HOME');
      expect((await templates()).single.groupName, 'HOME');

      await repo.setTemplateGroup(id, null);
      expect((await templates()).single.groupName, isNull);
    });

    test('groupsOf lista grupos sem repetir, em ordem alfabética', () async {
      await repo.createTemplate('A', group: 'HOME');
      await repo.createTemplate('B', group: 'GYM');
      await repo.createTemplate('C', group: 'HOME');
      await repo.createTemplate('D');
      await repo.createTemplate('E', group: 'calistenia');

      expect(WorkoutRepository.groupsOf(await templates()), [
        'calistenia',
        'GYM',
        'HOME',
      ]);
    });
  });

  group('WorkoutRepository.reorderVisible', () {
    test('sem filtro equivale a reordenar a lista inteira', () async {
      for (final n in ['A', 'B', 'C']) {
        await repo.createTemplate(n);
      }
      final all = await templates();

      final result = WorkoutRepository.reorderVisible(all, all, 0, 2);
      expect(result.map((t) => t.name), ['B', 'C', 'A']);
    });

    test('com filtro, só os treinos visíveis trocam de lugar', () async {
      // Ordem: A(GYM) B(HOME) C(GYM) D(HOME) E(GYM)
      for (final (n, g) in [
        ('A', 'GYM'),
        ('B', 'HOME'),
        ('C', 'GYM'),
        ('D', 'HOME'),
        ('E', 'GYM'),
      ]) {
        await repo.createTemplate(n, group: g);
      }
      final all = await templates();
      final gym = all.where((t) => t.groupName == 'GYM').toList();

      // Arrasta E para o topo dentro de GYM: GYM vira E, A, C.
      final result = WorkoutRepository.reorderVisible(all, gym, 2, 0);
      expect(result.map((t) => t.name), ['E', 'B', 'A', 'D', 'C']);

      await repo.reorderTemplates(result);
      expect((await templates()).map((t) => t.name), ['E', 'B', 'A', 'D', 'C']);
    });
  });
}
