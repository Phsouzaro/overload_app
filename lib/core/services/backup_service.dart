import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

/// Backup completo do banco (todas as tabelas) em um arquivo `.sqlite`.
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  static final _sqliteMagic = ascii.encode('SQLite format 3\u0000');

  /// Arquivo do banco usado pelo app.
  static Future<File> databaseFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, '${AppDatabase.dbName}.sqlite'));
  }

  /// Grava uma cópia consistente do banco em [path] (`VACUUM INTO`, que
  /// funciona com o banco aberto e em uso).
  Future<File> writeBackup(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    await _db.customStatement('VACUUM INTO ?', [path]);
    return file;
  }

  /// Gera o backup e abre o compartilhamento do Android.
  Future<void> shareBackup() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final file = await writeBackup(
      p.join(dir.path, 'overload_backup_$stamp.sqlite'),
    );

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/vnd.sqlite3'),
    ], subject: 'Overload — Backup');
  }

  /// Confere se [header] (os primeiros 100 bytes do arquivo) é de um banco do
  /// Overload que esta versão do app consegue abrir. Retorna a versão do schema.
  static int validateHeader(List<int> header, {required int currentSchema}) {
    if (header.length < 100) {
      throw const FormatException(
        'Arquivo inválido: não é um backup do Overload',
      );
    }
    for (var i = 0; i < _sqliteMagic.length; i++) {
      if (header[i] != _sqliteMagic[i]) {
        throw const FormatException(
          'Arquivo inválido: não é um backup do Overload',
        );
      }
    }
    // PRAGMA user_version (gravado pelo drift): 4 bytes big-endian no offset 60.
    final version =
        (header[60] << 24) |
        (header[61] << 16) |
        (header[62] << 8) |
        header[63];
    if (version < 1) {
      throw const FormatException(
        'Arquivo inválido: não é um backup do Overload',
      );
    }
    if (version > currentSchema) {
      throw const FormatException(
        'Backup feito em uma versão mais nova do app. Atualize o app '
        'antes de restaurar.',
      );
    }
    return version;
  }

  static Future<List<int>> _readHeader(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(100);
    } finally {
      await raf.close();
    }
  }

  /// Valida [source] sem alterar nada. Lança [FormatException] se o arquivo
  /// não puder ser restaurado.
  Future<void> validateBackup(File source) async {
    validateHeader(await _readHeader(source), currentSchema: _db.schemaVersion);
  }

  /// Substitui o banco em [target] pelo backup [source].
  ///
  /// Antes, guarda o banco atual em `<target>_antes_da_restauracao.sqlite`.
  /// Fecha o [AppDatabase]: quem chama precisa abrir um novo depois (no app,
  /// invalidando o `databaseProvider`). Migrations de backups antigos rodam
  /// ao abrir.
  Future<void> restore(File source, {required File target}) async {
    await validateBackup(source);

    final safetyCopy = p.join(
      p.dirname(target.path),
      '${p.basenameWithoutExtension(target.path)}_antes_da_restauracao.sqlite',
    );
    await writeBackup(safetyCopy);
    await _db.close();

    final tmp = File('${target.path}.restaurando');
    await source.copy(tmp.path);
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('${target.path}$suffix');
      if (await f.exists()) await f.delete();
    }
    await tmp.rename(target.path);
  }
}
