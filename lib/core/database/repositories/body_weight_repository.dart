import 'package:drift/drift.dart';
import '../app_database.dart';

class BodyWeightRepository {
  final AppDatabase _db;

  BodyWeightRepository(this._db);

  Stream<List<BodyWeightEntry>> watchEntriesFrom(DateTime from) {
    return (_db.select(_db.bodyWeightEntries)
          ..where((e) => e.recordedAt.isBiggerOrEqualValue(from))
          ..orderBy([(e) => OrderingTerm.asc(e.recordedAt)]))
        .watch();
  }

  Stream<List<BodyWeightEntry>> watchRecentEntries({int limit = 15}) {
    return (_db.select(_db.bodyWeightEntries)
          ..orderBy([(e) => OrderingTerm.desc(e.recordedAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> addEntry(double weightKg, {DateTime? date}) {
    return _db.into(_db.bodyWeightEntries).insert(
          BodyWeightEntriesCompanion.insert(
            weightKg: weightKg,
            recordedAt: date ?? DateTime.now(),
          ),
        );
  }

  Future<void> updateEntry(int id, double weightKg, DateTime date) {
    return (_db.update(_db.bodyWeightEntries)..where((e) => e.id.equals(id)))
        .write(BodyWeightEntriesCompanion(
          weightKg: Value(weightKg),
          recordedAt: Value(date),
        ));
  }

  Future<void> deleteEntry(int id) {
    return (_db.delete(_db.bodyWeightEntries)
          ..where((e) => e.id.equals(id)))
        .go();
  }
}
