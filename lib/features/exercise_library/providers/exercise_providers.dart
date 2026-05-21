import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final muscleGroup = ref.watch(selectedMuscleGroupProvider);
  final search = ref.watch(exerciseSearchQueryProvider);
  return ref.watch(exerciseRepositoryProvider).watchExercises(
        muscleGroup: muscleGroup,
        search: search,
      );
});
