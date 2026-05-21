import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/body_weight_repository.dart';

enum WeightPeriod {
  week(7, 'Semana'),
  month(30, 'Mês'),
  sixMonths(180, '6 Meses');

  final int days;
  final String label;
  const WeightPeriod(this.days, this.label);
}

final bodyWeightRepositoryProvider = Provider<BodyWeightRepository>((ref) {
  return BodyWeightRepository(ref.watch(databaseProvider));
});

final selectedWeightPeriodProvider =
    StateProvider<WeightPeriod>((ref) => WeightPeriod.month);

final bodyWeightChartEntriesProvider =
    StreamProvider<List<BodyWeightEntry>>((ref) {
  final period = ref.watch(selectedWeightPeriodProvider);
  final from = DateTime.now().subtract(Duration(days: period.days));
  return ref.watch(bodyWeightRepositoryProvider).watchEntriesFrom(from);
});

final recentBodyWeightEntriesProvider =
    StreamProvider<List<BodyWeightEntry>>((ref) {
  return ref.watch(bodyWeightRepositoryProvider).watchRecentEntries();
});
