import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/report_repository.dart';
import '../../../core/database/repositories/session_repository.dart';
export '../../../core/database/repositories/session_repository.dart'
    show FinishedSessionSummary, SessionSetDetail;

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(databaseProvider));
});

final sessionExercisesProvider =
    StreamProvider.family<List<SessionExerciseWithExercise>, int>(
        (ref, sessionId) {
  return ref
      .watch(sessionRepositoryProvider)
      .watchSessionExercises(sessionId);
});

final sessionSetsProvider =
    StreamProvider.family<List<SessionSet>, int>((ref, sessionExerciseId) {
  return ref.watch(sessionRepositoryProvider).watchSets(sessionExerciseId);
});

final previousSetsProvider = FutureProvider.family<List<SessionSet>,
    ({int templateId, int exerciseId})>((ref, params) {
  return ref
      .watch(sessionRepositoryProvider)
      .getPreviousSets(params.templateId, params.exerciseId);
});

final exercisePrWeightProvider =
    FutureProvider.autoDispose.family<double?, int>((ref, exerciseId) {
  return ReportRepository(ref.watch(databaseProvider))
      .getExerciseMaxWeight(exerciseId);
});

final finishedSessionsProvider =
    StreamProvider<List<FinishedSessionSummary>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchFinishedSessions();
});
