import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../providers/exercise_providers.dart';
import 'add_exercise_screen.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
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
      appBar: AppBar(title: const Text('Exercícios')),
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
                _FilterChip(
                  label: 'Todos',
                  selected: selectedGroup == null,
                  onSelected: () => ref
                      .read(selectedMuscleGroupProvider.notifier)
                      .state = null,
                ),
                ...kMuscleGroups.map(
                  (g) => _FilterChip(
                    label: g,
                    selected: selectedGroup == g,
                    onSelected: () => ref
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
              data: (exercises) => exercises.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) =>
                          _ExerciseCard(exercise: exercises[index]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final Exercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          _iconForSetType(exercise.setType),
          size: 18,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(exercise.muscleGroup),
      trailing: PopupMenuButton<_ExerciseAction>(
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _ExerciseAction.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _ExerciseAction.archive,
            child: ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Arquivar'),
              contentPadding: EdgeInsets.zero,
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

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _ExerciseAction action,
  ) async {
    final repo = ref.read(exerciseRepositoryProvider);
    switch (action) {
      case _ExerciseAction.edit:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExerciseScreen(exercise: exercise),
          ),
        );
      case _ExerciseAction.archive:
        final hasHistory = await repo.hasHistory(exercise.id);
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Arquivar exercício?'),
            content: Text(
              hasHistory
                  ? 'O histórico de "${exercise.name}" será mantido, mas ele não aparecerá mais na biblioteca.'
                  : 'Tem certeza que deseja arquivar "${exercise.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Arquivar'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await repo.archiveExercise(exercise.id);
        }
    }
  }
}

enum _ExerciseAction { edit, archive }
