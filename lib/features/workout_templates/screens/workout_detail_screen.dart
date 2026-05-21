import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/workout_repository.dart';
import '../../../core/database/tables.dart';
import '../../active_session/providers/session_providers.dart';
import '../../active_session/screens/active_session_screen.dart';
import '../providers/workout_providers.dart';
import 'exercise_picker_screen.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final int templateId;
  final String templateName;

  const WorkoutDetailScreen({
    super.key,
    required this.templateId,
    required this.templateName,
  });

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  late List<TemplateExerciseWithDetails> _localList = [];
  bool _reordering = false;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync =
        ref.watch(templateExercisesProvider(widget.templateId));

    exercisesAsync.whenData((data) {
      if (!_reordering) _localList = data;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.templateName),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Iniciar sessão',
            onPressed: _localList.isEmpty ? null : _startSession,
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (_) => _localList.isEmpty
            ? const _EmptyState()
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _localList.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final item = _localList[index];
                  return _ExerciseItem(
                    key: ValueKey(item.templateExercise.id),
                    item: item,
                    onRemove: () => _removeExercise(item),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPicker,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _startSession() async {
    final sessionId = await ref
        .read(sessionRepositoryProvider)
        .startSession(widget.templateId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          sessionId: sessionId,
          templateId: widget.templateId,
          templateName: widget.templateName,
        ),
      ),
    );
  }

  Future<void> _openPicker() async {
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (exercise != null) {
      await ref
          .read(workoutRepositoryProvider)
          .addExerciseToTemplate(widget.templateId, exercise.id);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      _reordering = true;
      final item = _localList.removeAt(oldIndex);
      _localList.insert(newIndex, item);
    });
    ref
        .read(workoutRepositoryProvider)
        .updateExercisePositions(_localList)
        .then((_) => setState(() => _reordering = false));
  }

  Future<void> _removeExercise(TemplateExerciseWithDetails item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover exercício?'),
        content: Text(
            'Remover "${item.exercise.name}" deste treino?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(workoutRepositoryProvider)
          .removeExerciseFromTemplate(item.templateExercise.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhum exercício ainda',
              style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8),
          Text('Toque em + para adicionar exercícios',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final TemplateExerciseWithDetails item;
  final VoidCallback onRemove;

  const _ExerciseItem({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final exercise = item.exercise;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForSetType(exercise.setType),
          size: 18,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(exercise.muscleGroup),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).colorScheme.error,
            onPressed: onRemove,
          ),
          const Icon(Icons.drag_handle),
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
