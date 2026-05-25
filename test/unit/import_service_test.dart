import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/database/tables.dart';
import 'package:overload/core/services/import_service.dart';

// ── JSON fixtures ──────────────────────────────────────────────────────────────

/// Exercícios com nomes que NÃO existem no seed (nomes únicos de teste).
const _jsonDoisNovos = '''
{
  "version": 1,
  "template": {
    "name": "Treino Teste",
    "exercises": [
      {
        "name": "Exercício Fictício Alpha",
        "muscleGroup": "Grupo Teste",
        "setType": "weight",
        "restSeconds": 90
      },
      {
        "name": "Exercício Fictício Beta",
        "muscleGroup": "Grupo Teste",
        "setType": "bodyweight",
        "restSeconds": 60
      }
    ]
  }
}
''';

/// Mistura: "Supino Reto" está no seed (será reutilizado) +
/// um exercício fictício (será criado).
const _jsonMistoComSeed = '''
{
  "version": 1,
  "template": {
    "name": "Treino Misto",
    "exercises": [
      {
        "name": "Supino Reto",
        "muscleGroup": "Peito",
        "setType": "weight",
        "restSeconds": 90
      },
      {
        "name": "Exercício Fictício Gamma",
        "muscleGroup": "Grupo Teste",
        "setType": "weight",
        "restSeconds": 60
      }
    ]
  }
}
''';

/// JSON com versão não suportada.
const _jsonVersaoInvalida = '''
{
  "version": 99,
  "template": {
    "name": "Qualquer",
    "exercises": []
  }
}
''';

/// Template sem exercícios.
const _jsonSemExercicios = '''
{
  "version": 1,
  "template": {
    "name": "Treino Vazio",
    "exercises": []
  }
}
''';

// ── Helper ─────────────────────────────────────────────────────────────────────

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

// ── Testes ─────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late ImportService service;

  setUp(() async {
    db = _makeDb();
    service = ImportService(db);
    // Aguarda a criação do schema (incluindo seed data).
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  // ── Exercícios novos vs. reutilizados ──────────────────────────────────────
  group('contagem de exercícios adicionados e reutilizados', () {
    test('dois exercícios novos: added=2, reused=0', () async {
      final result = await service.parseAndImport(_jsonDoisNovos);

      expect(result.exercisesAdded, 2);
      expect(result.exercisesReused, 0);
    });

    test('um do seed + um novo: added=1, reused=1', () async {
      final result = await service.parseAndImport(_jsonMistoComSeed);

      expect(result.exercisesAdded, 1);
      expect(result.exercisesReused, 1);
    });

    test('reutiliza exercício ignorando maiúsculas (case-insensitive)', () async {
      // "SUPINO RETO" em maiúsculas deve referenciar o mesmo do seed.
      const jsonUppercase = '''
      {
        "version": 1,
        "template": {
          "name": "Treino Case",
          "exercises": [
            {
              "name": "SUPINO RETO",
              "muscleGroup": "Peito",
              "setType": "weight",
              "restSeconds": 90
            }
          ]
        }
      }
      ''';

      final result = await service.parseAndImport(jsonUppercase);

      expect(result.exercisesAdded, 0);
      expect(result.exercisesReused, 1);
    });

    test('exercício arquivado NÃO é reutilizado — um novo é criado', () async {
      // Insere "Exercício Arquivado" com isArchived=true
      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          name: 'Exercício Fictício Arquivado',
          muscleGroup: 'Grupo Teste',
          setType: SetType.weight,
          isArchived: const Value(true),
        ),
      );

      const jsonArquivado = '''
      {
        "version": 1,
        "template": {
          "name": "Treino Arquivado",
          "exercises": [
            {
              "name": "Exercício Fictício Arquivado",
              "muscleGroup": "Grupo Teste",
              "setType": "weight",
              "restSeconds": 90
            }
          ]
        }
      }
      ''';

      final result = await service.parseAndImport(jsonArquivado);

      // Arquivado é ignorado; exercício deve ser criado novamente.
      expect(result.exercisesAdded, 1);
      expect(result.exercisesReused, 0);
    });

    test('template sem exercícios: added=0, reused=0', () async {
      final result = await service.parseAndImport(_jsonSemExercicios);

      expect(result.exercisesAdded, 0);
      expect(result.exercisesReused, 0);
    });
  });

  // ── Nome do template retornado ─────────────────────────────────────────────
  group('nome do template importado', () {
    test('retorna o nome exato do JSON', () async {
      final result = await service.parseAndImport(_jsonDoisNovos);

      expect(result.templateName, 'Treino Teste');
    });
  });

  // ── Resolução de conflito de nome ──────────────────────────────────────────
  group('resolução de conflito de nome de template', () {
    test('segunda importação do mesmo nome → "(2)"', () async {
      await service.parseAndImport(_jsonDoisNovos); // cria "Treino Teste"
      final result = await service.parseAndImport(_jsonDoisNovos);

      expect(result.templateName, 'Treino Teste (2)');
    });

    test('terceira importação → "(3)"', () async {
      await service.parseAndImport(_jsonDoisNovos); // Treino Teste
      await service.parseAndImport(_jsonDoisNovos); // Treino Teste (2)
      final result = await service.parseAndImport(_jsonDoisNovos);

      expect(result.templateName, 'Treino Teste (3)');
    });

    test('importações independentes não interferem entre si', () async {
      final r1 = await service.parseAndImport(_jsonDoisNovos);
      final r2 = await service.parseAndImport(_jsonMistoComSeed);

      // Nomes distintos → sem conflito
      expect(r1.templateName, 'Treino Teste');
      expect(r2.templateName, 'Treino Misto');
    });
  });

  // ── Versão do arquivo ──────────────────────────────────────────────────────
  group('validação de versão', () {
    test('versão não suportada lança Exception', () async {
      expect(
        () => service.parseAndImport(_jsonVersaoInvalida),
        throwsA(isA<Exception>()),
      );
    });

    test('sem campo version assume versão 1 (compatibilidade)', () async {
      const jsonSemVersao = '''
      {
        "template": {
          "name": "Treino Sem Versão",
          "exercises": []
        }
      }
      ''';

      // Não deve lançar exceção.
      final result = await service.parseAndImport(jsonSemVersao);
      expect(result.templateName, 'Treino Sem Versão');
    });
  });

  // ── Propriedades dos exercícios criados ────────────────────────────────────
  group('propriedades persistidas corretamente', () {
    test('restSeconds é salvo corretamente', () async {
      await service.parseAndImport(_jsonDoisNovos);

      final exercises = await db.select(db.exercises).get();
      final alpha =
          exercises.where((e) => e.name == 'Exercício Fictício Alpha').single;
      final beta =
          exercises.where((e) => e.name == 'Exercício Fictício Beta').single;

      expect(alpha.restSeconds, 90);
      expect(beta.restSeconds, 60);
    });

    test('setType é salvo corretamente', () async {
      await service.parseAndImport(_jsonDoisNovos);

      final exercises = await db.select(db.exercises).get();
      final alpha =
          exercises.where((e) => e.name == 'Exercício Fictício Alpha').single;
      final beta =
          exercises.where((e) => e.name == 'Exercício Fictício Beta').single;

      expect(alpha.setType, SetType.weight);
      expect(beta.setType, SetType.bodyweight);
    });

    test('exercícios são vinculados ao template correto', () async {
      await service.parseAndImport(_jsonDoisNovos);

      final templates = await db.select(db.workoutTemplates).get();
      final template =
          templates.where((t) => t.name == 'Treino Teste').single;

      final links = await (db.select(db.templateExercises)
            ..where((te) => te.templateId.equals(template.id)))
          .get();

      expect(links.length, 2);
    });

    test('posição dos exercícios no template é sequencial (0, 1, 2...)', () async {
      await service.parseAndImport(_jsonDoisNovos);

      final templates = await db.select(db.workoutTemplates).get();
      final template =
          templates.where((t) => t.name == 'Treino Teste').single;

      final links = await (db.select(db.templateExercises)
            ..where((te) => te.templateId.equals(template.id))
            ..orderBy([(te) => OrderingTerm.asc(te.position)]))
          .get();

      expect(links[0].position, 0);
      expect(links[1].position, 1);
    });
  });
}
