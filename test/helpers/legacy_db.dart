import 'package:overload/core/database/app_database.dart';

/// Volta um banco atual (v6) para o formato de uma versão anterior
/// ([version] 3, 4 ou 5), removendo as tabelas e colunas que surgiram
/// depois dela. Simula o banco (ou o backup) de um app antigo.
Future<void> downgradeTo(AppDatabase db, int version) async {
  assert(version >= 3 && version <= 5, 'versões suportadas: 3 a 5');
  await db.customStatement('PRAGMA foreign_keys = OFF');
  await db.customStatement('DROP TABLE progression_recommendations');
  await db.customStatement('DROP TABLE progression_configs');
  for (final (table, columns) in [
    (
      'session_exercises',
      // v4 acrescentou is_extra.
      'id, session_id, exercise_id, position, rest_seconds'
          '${version >= 4 ? ', is_extra' : ''}',
    ),
    (
      'session_sets',
      'id, session_exercise_id, set_type, weight_kg, reps, duration_seconds, '
          'is_warmup, to_failure, position',
    ),
    // v5 acrescentou group_name.
    if (version < 5)
      ('workout_templates', 'id, name, is_archived, created_at, position'),
  ]) {
    await db.customStatement(
      'CREATE TABLE ${table}_old AS SELECT $columns FROM $table',
    );
    await db.customStatement('DROP TABLE $table');
    await db.customStatement('ALTER TABLE ${table}_old RENAME TO $table');
  }
  await db.customStatement('PRAGMA user_version = $version');
}
