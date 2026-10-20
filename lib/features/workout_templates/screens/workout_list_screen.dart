import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/workout_repository.dart';
import '../../active_session/widgets/active_session_banner.dart';
import '../../reports/providers/report_providers.dart';
import '../providers/workout_providers.dart';
import '../../../features/session_history/screens/session_history_screen.dart';
import 'archived_workouts_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutListScreen extends ConsumerStatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  ConsumerState<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends ConsumerState<WorkoutListScreen> {
  bool _importing = false;

  Future<void> _showCreateDialog() async {
    final name = await _showNameDialog(context, title: 'Novo Treino');
    if (name != null && name.isNotEmpty) {
      // Criado com o filtro de um grupo ativo, o treino já entra nele.
      await ref
          .read(workoutRepositoryProvider)
          .createTemplate(name, group: ref.read(selectedTemplateGroupProvider));
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ref.read(importServiceProvider).importTemplate();
      if (result == null) return; // user cancelled

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${result.templateName}" importado! '
              '${result.exercisesAdded > 0 ? '${result.exercisesAdded} exercício(s) criado(s). ' : ''}'
              '${result.exercisesReused > 0 ? '${result.exercisesReused} reutilizado(s).' : ''}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao importar: ${e is FormatException ? e.message : e}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo_icon.svg',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text('Meus Treinos'),
          ],
        ),
        actions: [
          if (_importing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Importar treino',
              onPressed: _import,
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Arquivados',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchivedWorkoutsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const ActiveSessionBanner(),
          Expanded(child: _buildTemplates(templatesAsync)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Treino'),
      ),
    );
  }

  Widget _buildTemplates(AsyncValue<List<WorkoutTemplate>> templatesAsync) {
    return templatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (templates) {
        if (templates.isEmpty) return const _EmptyState();

        final groups = WorkoutRepository.groupsOf(templates);
        // Grupo selecionado que deixou de existir (ex: último treino saiu
        // dele) volta para "Todos".
        final rawSelected = ref.watch(selectedTemplateGroupProvider);
        final selected = groups.contains(rawSelected) ? rawSelected : null;
        final visible = selected == null
            ? templates
            : templates.where((t) => t.groupName == selected).toList();

        return Column(
          children: [
            if (groups.isNotEmpty)
              _GroupChips(
                groups: groups,
                selected: selected,
                onSelected: (g) =>
                    ref.read(selectedTemplateGroupProvider.notifier).state = g,
              ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: visible.length,
                itemBuilder: (context, index) => _TemplateCard(
                  key: ValueKey(visible[index].id),
                  template: visible[index],
                  groups: groups,
                  showGroup: selected == null,
                ),
                onReorderItem: (oldIndex, newIndex) {
                  ref
                      .read(workoutRepositoryProvider)
                      .reorderTemplates(
                        WorkoutRepository.reorderVisible(
                          templates,
                          visible,
                          oldIndex,
                          newIndex,
                        ),
                      );
                },
                // Custom drag handle style
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Theme.of(context).colorScheme.shadow,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupChips extends StatelessWidget {
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _GroupChips({
    required this.groups,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelected(value),
      ),
    );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
        children: [chip('Todos', null), for (final g in groups) chip(g, g)],
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
          // Full logo with athlete + "OVERLOAD" text
          SvgPicture.asset('assets/images/logo.svg', width: 280, height: 280),
          const SizedBox(height: 8),
          Text(
            'Nenhum treino ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 6),
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
  final List<String> groups;
  // Com um grupo filtrado, todos os cards são dele: não repete o nome.
  final bool showGroup;

  const _TemplateCard({
    super.key,
    required this.template,
    required this.groups,
    required this.showGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('dismiss_${template.id}'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${template.name} arquivado')));
      },
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: 8,
          right: 8,
          top: 4,
          bottom: 4,
        ),
        title: Text(
          template.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: showGroup && template.groupName != null
            ? Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      template.groupName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle — visual cue + long-press initiates reorder
            Icon(
              Icons.drag_handle_rounded,
              color: Theme.of(context).colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<_TemplateAction>(
          onSelected: (action) => _handleAction(context, ref, action),
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
              value: _TemplateAction.group,
              child: ListTile(
                leading: Icon(Icons.label_outline),
                title: Text('Grupo'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _TemplateAction.share,
              child: ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Compartilhar'),
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
            builder: (_) => WorkoutDetailScreen(
              templateId: template.id,
              templateName: template.name,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _TemplateAction action,
  ) async {
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
      case _TemplateAction.group:
        final choice = await _showGroupDialog(
          context,
          current: template.groupName,
          groups: groups,
        );
        if (choice != null) {
          await repo.setTemplateGroup(template.id, choice.group);
        }
      case _TemplateAction.share:
        try {
          await ref.read(exportServiceProvider).exportTemplate(template.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
          }
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

enum _TemplateAction { rename, group, share, archive }

/// Escolha de grupo para um treino. Retorna `null` se cancelar; `group` nulo
/// significa "Sem grupo".
Future<({String? group})?> _showGroupDialog(
  BuildContext context, {
  required String? current,
  required List<String> groups,
}) {
  return showDialog<({String? group})>(
    context: context,
    builder: (_) => _GroupDialog(current: current, groups: groups),
  );
}

class _GroupDialog extends StatefulWidget {
  final String? current;
  final List<String> groups;

  const _GroupDialog({required this.current, required this.groups});

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createFromText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // "gym" com um grupo "GYM" já existente: usa o existente.
    final existing = widget.groups
        .where((g) => g.toLowerCase() == text.toLowerCase())
        .firstOrNull;
    Navigator.pop(context, (group: existing ?? text));
  }

  @override
  Widget build(BuildContext context) {
    Widget option(String label, String? value, IconData icon) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: widget.current == value
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, (group: value)),
    );

    return AlertDialog(
      title: const Text('Grupo do treino'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in widget.groups) option(g, g, Icons.label_outline),
            option('Sem grupo', null, Icons.label_off_outlined),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Novo grupo',
                hintText: 'Ex: GYM, HOME, CALISTENIA',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Criar grupo',
                  onPressed: _createFromText,
                ),
              ),
              onSubmitted: (_) => _createFromText(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

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
