import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../exercise_library/providers/exercise_providers.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final selectedGroup = ref.watch(selectedMuscleGroupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Exercício')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar exercício...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(exerciseSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip(
                  label: 'Todos',
                  selected: selectedGroup == null,
                  onTap: () => ref
                      .read(selectedMuscleGroupProvider.notifier)
                      .state = null,
                ),
                ...kMuscleGroups.map(
                  (g) => _Chip(
                    label: g,
                    selected: selectedGroup == g,
                    onTap: () => ref
                        .read(selectedMuscleGroupProvider.notifier)
                        .state = g,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (exercises) => ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        _iconForSetType(exercise.setType),
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    title: Text(exercise.name),
                    subtitle: Text(exercise.muscleGroup),
                    onTap: () => Navigator.pop(context, exercise),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSetType(SetType type) {
    return switch (type) {
      SetType.weight => Icons.fitness_center,
      SetType.time => Icons.timer_outlined,
      SetType.bodyweight => Icons.accessibility_new,
    };
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      ),
    );
  }
}
