import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../exercise_library/providers/exercise_providers.dart';
import '../../settings/providers/settings_provider.dart';

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

  /// Opens the quick-create bottom sheet. If the user saves, the new exercise
  /// is returned and the picker is immediately popped with it.
  Future<void> _quickCreate(String initialName) async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickCreateSheet(initialName: initialName),
    );

    if (exercise != null && mounted) {
      Navigator.pop(context, exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final selectedGroup = ref.watch(selectedMuscleGroupProvider);
    final searchQuery = ref.watch(exerciseSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Exercício')),
      body: Column(
        children: [
          // ── Search field ───────────────────────────────────────────────
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

          // ── Muscle group chips ─────────────────────────────────────────
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

          // ── Exercise list ──────────────────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (exercises) {
                if (exercises.isEmpty) {
                  // ── Empty state: prompt to create ──────────────────────
                  return _EmptyState(
                    searchQuery: searchQuery,
                    onCreateTap: () => _quickCreate(searchQuery),
                  );
                }

                return ListView.builder(
                  // +1 for optional "create" row at the bottom
                  itemCount:
                      exercises.length + (searchQuery.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Last item when searching: quick-create shortcut
                    if (index == exercises.length) {
                      return _CreateShortcutTile(
                        query: searchQuery,
                        onTap: () => _quickCreate(searchQuery),
                      );
                    }

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
                );
              },
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onCreateTap;

  const _EmptyState({required this.searchQuery, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasQuery = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              hasQuery
                  ? 'Nenhum resultado para\n"$searchQuery"'
                  : 'Nenhum exercício cadastrado',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: Text(
                hasQuery ? 'Criar "$searchQuery"' : 'Criar exercício',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick-create shortcut at the bottom of the list ───────────────────────────

class _CreateShortcutTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const _CreateShortcutTile({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DashedBorder(
          borderRadius: BorderRadius.circular(12),
          color: cs.primary.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Criar "$query" e adicionar',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple dashed border container (drawn via CustomPaint).
class DashedBorder extends StatelessWidget {
  final BorderRadius borderRadius;
  final Color color;
  final Widget child;

  const DashedBorder({
    super.key,
    required this.borderRadius,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: borderRadius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final BorderRadius radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = radius.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);

    const dashLen = 6.0;
    const gapLen = 4.0;
    final metric = path.computeMetrics().first;
    double dist = 0;
    while (dist < metric.length) {
      final end = (dist + dashLen).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(dist, end), paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

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

// ── Quick-create bottom sheet ─────────────────────────────────────────────────

class _QuickCreateSheet extends ConsumerStatefulWidget {
  final String initialName;

  const _QuickCreateSheet({required this.initialName});

  @override
  ConsumerState<_QuickCreateSheet> createState() => _QuickCreateSheetState();
}

class _QuickCreateSheetState extends ConsumerState<_QuickCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedMuscleGroup;
  late SetType _selectedSetType;
  late int _restSeconds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialName);
    _selectedMuscleGroup = kMuscleGroups.first;
    _selectedSetType = SetType.weight;
    _restSeconds = ref.read(settingsProvider).defaultRestSeconds;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(exerciseRepositoryProvider);
    final id = await repo.createExercise(
      name: _nameController.text.trim(),
      muscleGroup: _selectedMuscleGroup,
      setType: _selectedSetType,
      restSeconds: _restSeconds,
    );

    final exercise = await repo.getById(id);
    if (mounted) Navigator.pop(context, exercise);
  }

  String _formatRest(int s) {
    if (s == 0) return 'Sem descanso';
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    final r = s % 60;
    return r == 0 ? '${m}min' : '${m}min ${r}s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // push content above keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Novo Exercício',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                autofocus: widget.initialName.isEmpty,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome do exercício',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              // Muscle group
              DropdownButtonFormField<String>(
                value: _selectedMuscleGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo muscular',
                  border: OutlineInputBorder(),
                ),
                items: kMuscleGroups
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedMuscleGroup = v!),
              ),
              const SizedBox(height: 16),

              // Set type
              Text('Tipo de série',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<SetType>(
                segments: const [
                  ButtonSegment(
                    value: SetType.weight,
                    icon: Icon(Icons.fitness_center),
                    label: Text('Carga'),
                  ),
                  ButtonSegment(
                    value: SetType.time,
                    icon: Icon(Icons.timer_outlined),
                    label: Text('Tempo'),
                  ),
                  ButtonSegment(
                    value: SetType.bodyweight,
                    icon: Icon(Icons.accessibility_new),
                    label: Text('Corpo'),
                  ),
                ],
                selected: {_selectedSetType},
                onSelectionChanged: (s) =>
                    setState(() => _selectedSetType = s.first),
              ),
              const SizedBox(height: 16),

              // Rest
              Row(
                children: [
                  Expanded(
                    child: Text('Descanso padrão',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  Text(_formatRest(_restSeconds),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Slider(
                value: _restSeconds.toDouble(),
                min: 0,
                max: 300,
                divisions: 20,
                label: _formatRest(_restSeconds),
                onChanged: (v) =>
                    setState(() => _restSeconds = v.toInt()),
              ),
              const SizedBox(height: 8),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Criar e adicionar ao treino'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
