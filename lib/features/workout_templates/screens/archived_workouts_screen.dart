import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_providers.dart';

class ArchivedWorkoutsScreen extends ConsumerWidget {
  const ArchivedWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos Arquivados')),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (templates) => templates.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum treino arquivado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                    ),
                    title: Text(template.name),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.unarchive_outlined),
                      label: const Text('Restaurar'),
                      onPressed: () async {
                        await ref
                            .read(workoutRepositoryProvider)
                            .unarchiveTemplate(template.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${template.name} restaurado')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
