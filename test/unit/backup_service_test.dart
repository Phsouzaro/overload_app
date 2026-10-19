import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overload/core/database/app_database.dart';
import 'package:overload/core/services/backup_service.dart';
import 'package:path/path.dart' as p;

List<int> _header({
  int userVersion = 3,
  String magic = 'SQLite format 3\u0000',
}) {
  final bytes = List<int>.filled(100, 0);
  bytes.setRange(0, 16, ascii.encode(magic));
  bytes[60] = (userVersion >> 24) & 0xff;
  bytes[61] = (userVersion >> 16) & 0xff;
  bytes[62] = (userVersion >> 8) & 0xff;
  bytes[63] = userVersion & 0xff;
  return bytes;
}

Future<List<String>> _templateNames(AppDatabase db) async =>
    (await db.select(db.workoutTemplates).get()).map((t) => t.name).toList();

Future<void> _addTemplate(AppDatabase db, String name) => db
    .into(db.workoutTemplates)
    .insert(WorkoutTemplatesCompanion.insert(name: name));

void main() {
  group('BackupService.validateHeader', () {
    test('aceita banco do Overload com schema atual ou anterior', () {
      expect(BackupService.validateHeader(_header(), currentSchema: 3), 3);
      expect(
        BackupService.validateHeader(_header(userVersion: 2), currentSchema: 3),
        2,
      );
    });

    test('rejeita arquivo que não é SQLite', () {
      expect(
        () => BackupService.validateHeader(
          _header(magic: 'nao e um sqlite!'),
          currentSchema: 3,
        ),
        throwsFormatException,
      );
      expect(
        () => BackupService.validateHeader([1, 2, 3], currentSchema: 3),
        throwsFormatException,
      );
    });

    test('rejeita SQLite que não foi criado pelo app (user_version 0)', () {
      expect(
        () => BackupService.validateHeader(
          _header(userVersion: 0),
          currentSchema: 3,
        ),
        throwsFormatException,
      );
    });

    test('rejeita backup de versão mais nova do app', () {
      expect(
        () => BackupService.validateHeader(
          _header(userVersion: 4),
          currentSchema: 3,
        ),
        throwsFormatException,
      );
    });
  });

  group('BackupService — exportar e restaurar', () {
    late Directory tmp;

    setUp(() async => tmp = await Directory.systemTemp.createTemp('overload'));
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test(
      'restaura o backup no lugar do banco atual e guarda uma cópia',
      () async {
        // Banco de onde sai o backup
        final origem = AppDatabase.forTesting(NativeDatabase.memory());
        await _addTemplate(origem, 'Do backup');
        final backup = await BackupService(
          origem,
        ).writeBackup(p.join(tmp.path, 'backup.sqlite'));
        await origem.close();

        // Banco "atual" do app, em arquivo
        final target = File(p.join(tmp.path, 'overload_db.sqlite'));
        final atual = AppDatabase.forTesting(NativeDatabase(target));
        await _addTemplate(atual, 'Atual');

        await BackupService(atual).restore(backup, target: target);

        final restaurado = AppDatabase.forTesting(NativeDatabase(target));
        expect(await _templateNames(restaurado), ['Do backup']);
        await restaurado.close();

        final copia = File(
          p.join(tmp.path, 'overload_db_antes_da_restauracao.sqlite'),
        );
        expect(await copia.exists(), isTrue);
        final antigo = AppDatabase.forTesting(NativeDatabase(copia));
        expect(await _templateNames(antigo), ['Atual']);
        await antigo.close();
      },
    );

    test('arquivo inválido não altera o banco atual', () async {
      final target = File(p.join(tmp.path, 'overload_db.sqlite'));
      final atual = AppDatabase.forTesting(NativeDatabase(target));
      await _addTemplate(atual, 'Atual');

      final lixo = File(p.join(tmp.path, 'lixo.sqlite'))
        ..writeAsStringSync('isso não é um banco' * 10);

      await expectLater(
        BackupService(atual).restore(lixo, target: target),
        throwsFormatException,
      );
      expect(await _templateNames(atual), ['Atual']);
      await atual.close();
    });
  });
}
