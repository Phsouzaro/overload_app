import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/workout_repository.dart';
import '../../../core/services/import_service.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

/// Grupo selecionado nos chips da tela inicial; `null` = Todos.
final selectedTemplateGroupProvider = StateProvider<String?>((_) => null);

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.watch(databaseProvider));
});

final workoutTemplatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchActiveTemplates();
});

final archivedTemplatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchArchivedTemplates();
});

final templateExercisesProvider = StreamProvider.family<
    List<TemplateExerciseWithDetails>, int>((ref, templateId) {
  return ref
      .watch(workoutRepositoryProvider)
      .watchTemplateExercises(templateId);
});
