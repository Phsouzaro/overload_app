import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/report_repository.dart';
import '../../../core/services/export_service.dart';

enum ReportPeriod {
  month(30, '1 Mês'),
  threeMonths(90, '3 Meses'),
  sixMonths(180, '6 Meses'),
  all(0, 'Tudo');

  final int days;
  final String label;
  const ReportPeriod(this.days, this.label);

  DateTime? get fromDate => days == 0
      ? null
      : DateTime.now().subtract(Duration(days: days));
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(databaseProvider));
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(databaseProvider));
});

// ── Exercício ─────────────────────────────────────────────────────────────────

final reportExerciseIdProvider = StateProvider<int?>((ref) => null);
final reportExercisePeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.threeMonths);

final exerciseProgressProvider =
    FutureProvider.autoDispose<List<ExerciseProgressPoint>>((ref) {
  final exerciseId = ref.watch(reportExerciseIdProvider);
  final period = ref.watch(reportExercisePeriodProvider);
  if (exerciseId == null) return Future.value([]);
  return ref
      .watch(reportRepositoryProvider)
      .getExerciseProgress(exerciseId, from: period.fromDate);
});

// ── Treino ───────────────────────────────────────────────────────────────────

final reportTemplateIdProvider = StateProvider<int?>((ref) => null);
final reportWorkoutPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.threeMonths);

final workoutProgressProvider =
    FutureProvider.autoDispose<List<WorkoutSessionPoint>>((ref) {
  final templateId = ref.watch(reportTemplateIdProvider);
  final period = ref.watch(reportWorkoutPeriodProvider);
  if (templateId == null) return Future.value([]);
  return ref
      .watch(reportRepositoryProvider)
      .getWorkoutProgress(templateId, from: period.fromDate);
});
