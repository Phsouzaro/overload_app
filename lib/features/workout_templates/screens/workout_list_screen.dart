import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/workout_providers.dart';
import '../../../features/session_history/screens/session_history_screen.dart';
import 'archived_workouts_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SessionHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Arquivados',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ArchivedWorkoutsScreen()),
            ),
          ),
        ],
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (templates) => templates.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: templates.length,
                itemBuilder: (context, index) => _TemplateCard(
                  template: templates[index],
                  ref: ref,
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Treino'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, title: 'Novo Treino');
    if (name != null && name.isNotEmpty) {
      await ref.read(workoutRepositoryProvider).createTemplate(name);
    }
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
          Icon(
            Icons.fitness_center,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum treino ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "+ Novo Treino" para começar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final WorkoutTemplate template;
  final WidgetRef ref;

  const _TemplateCard({required this.template, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.archive_outlined,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => _confirmArchive(context),
      onDismissed: (_) {
        ref.read(workoutRepositoryProvider).archiveTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.name} arquivado')),
        );
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          template.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        trailing: PopupMenuButton<_TemplateAction>(
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _TemplateAction.rename,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Renomear'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _TemplateAction.archive,
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Arquivar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkoutDetailScreen(templateId: template.id, templateName: template.name),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _TemplateAction action) async {
    final repo = ref.read(workoutRepositoryProvider);
    switch (action) {
      case _TemplateAction.rename:
        final name = await _showNameDialog(
          context,
          title: 'Renomear Treino',
          initialValue: template.name,
        );
        if (name != null && name.isNotEmpty) {
          await repo.renameTemplate(template.id, name);
        }
      case _TemplateAction.archive:
        final confirm = await _confirmArchive(context);
        if (confirm == true) {
          await repo.archiveTemplate(template.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${template.name} arquivado')),
            );
          }
        }
    }
  }

  Future<bool?> _confirmArchive(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar treino?'),
        content: Text(
          'O histórico de sessões de "${template.name}" será mantido.',
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
  }
}

enum _TemplateAction { rename, archive }

Future<String?> _showNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Ex: Treino A - Peito e Tríceps',
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}
