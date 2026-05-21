import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../providers/exercise_providers.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;

  const AddExerciseScreen({super.key, this.exercise});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedMuscleGroup;
  late SetType _selectedSetType;
  late int _restSeconds;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _selectedMuscleGroup = e?.muscleGroup ?? kMuscleGroups.first;
    _selectedSetType = e?.setType ?? SetType.weight;
    _restSeconds = e?.restSeconds ?? 90;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Exercício' : 'Novo Exercício'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do exercício',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedMuscleGroup,
              decoration: const InputDecoration(
                labelText: 'Grupo muscular',
                border: OutlineInputBorder(),
              ),
              items: kMuscleGroups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedMuscleGroup = v!),
            ),
            const SizedBox(height: 20),
            Text(
              'Tipo de série',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _SetTypeSelector(
              value: _selectedSetType,
              onChanged: (v) => setState(() => _selectedSetType = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Descanso padrão',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  _formatRest(_restSeconds),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: _restSeconds.toDouble(),
              min: 0,
              max: 300,
              divisions: 20,
              label: _formatRest(_restSeconds),
              onChanged: (v) => setState(() => _restSeconds = v.toInt()),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Salvar' : 'Criar Exercício'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRest(int seconds) {
    if (seconds == 0) return 'Sem descanso';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}min' : '${m}min ${s}s';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(exerciseRepositoryProvider);
    final name = _nameController.text.trim();

    if (_isEditing) {
      await repo.updateExercise(
        widget.exercise!.id,
        name: name,
        muscleGroup: _selectedMuscleGroup,
        setType: _selectedSetType,
        restSeconds: _restSeconds,
      );
    } else {
      await repo.createExercise(
        name: name,
        muscleGroup: _selectedMuscleGroup,
        setType: _selectedSetType,
        restSeconds: _restSeconds,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

class _SetTypeSelector extends StatelessWidget {
  final SetType value;
  final ValueChanged<SetType> onChanged;

  const _SetTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SetType>(
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
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
