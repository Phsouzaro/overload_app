import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/progression/progression_enums.dart';
import '../../../core/progression/progression_models.dart';
import '../../../core/progression/progression_rules.dart';
import '../../../core/progression/progression_strategy.dart';
import '../../../core/progression/strategies/double_progression.dart';
import '../../../core/progression/strategies/linear_progression.dart';
import '../../../core/utils/unit_converter.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/progression_providers.dart';
import '../widgets/recommendation_card.dart';

/// "Estratégia de Progressão" de um exercício: método, parâmetros, exemplo
/// calculado pelo próprio motor e recomendações anteriores.
class ProgressionConfigScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ProgressionConfigScreen({super.key, required this.exercise});

  @override
  ConsumerState<ProgressionConfigScreen> createState() =>
      _ProgressionConfigScreenState();
}

class _ProgressionConfigScreenState
    extends ConsumerState<ProgressionConfigScreen> {
  bool _loading = true;
  bool _saving = false;
  ProgressionConfigEntry? _active;

  /// `null` = sem progressão automática.
  StrategyId? _strategy;
  DoubleProgressionConfig _double = const DoubleProgressionConfig();
  LinearProgressionConfig _linear = const LinearProgressionConfig();
  late final TextEditingController _increment;
  bool _newBaseline = false;

  bool get _bodyweight => widget.exercise.setType == SetType.bodyweight;

  @override
  void initState() {
    super.initState();
    final unit = ref.read(settingsProvider).unit;
    _increment = TextEditingController(
      text: unit == WeightUnit.lbs ? '5' : '2.5',
    );
    _load();
  }

  @override
  void dispose() {
    _increment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final active = await ref
        .read(progressionRepositoryProvider)
        .activeConfig(widget.exercise.id);
    if (!mounted) return;
    final unit = ref.read(settingsProvider).unit;
    setState(() {
      _active = active;
      _loading = false;
      if (active == null) return;
      _strategy = active.strategy;
      final params = (jsonDecode(active.paramsJson) as Map)
          .cast<String, Object?>();
      switch (active.strategy) {
        case StrategyId.doubleProgression:
          _double = DoubleProgressionConfig.fromJson(params);
        case StrategyId.linear:
          _linear = LinearProgressionConfig.fromJson(params);
        default:
          break;
      }
      _increment.text = _formatNumber(
        UnitConverter.toDisplay(active.incrementKg, unit),
      );
    });
  }

  static String _formatNumber(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

  double? get _incrementKg {
    final display = double.tryParse(_increment.text.replaceAll(',', '.'));
    if (display == null || display <= 0) return null;
    return UnitConverter.fromDisplay(display, ref.read(settingsProvider).unit);
  }

  ProgressionConfig? get _config => switch (_strategy) {
    StrategyId.doubleProgression => _double,
    StrategyId.linear => _linear,
    _ => null,
  };

  List<String> get _issues {
    final config = _config;
    if (config == null) return const [];
    final strategy = ref
        .read(progressionRegistryProvider)
        .strategyFor(_strategy!);
    return [
      if (_incrementKg == null) 'incremento: informe um valor maior que zero',
      if (strategy != null)
        for (final i in strategy.validateConfig(config)) i.toString(),
    ];
  }

  Future<void> _save() async {
    final repo = ref.read(progressionRepositoryProvider);
    final now = DateTime.now();
    final config = _config;

    setState(() => _saving = true);
    try {
      if (config == null) {
        if (_active != null) await repo.deactivate(widget.exercise.id, now);
        if (mounted) {
          _snack('Progressão automática desativada');
          Navigator.pop(context);
        }
        return;
      }

      final params = config.toJson();
      final increment = _incrementKg!;
      final unchanged =
          _active != null &&
          _active!.strategy == config.strategy &&
          jsonEncode(params) == _active!.paramsJson &&
          (increment - _active!.incrementKg).abs() < 1e-6 &&
          !_newBaseline;
      if (!unchanged) {
        await repo.saveConfig(
          exerciseId: widget.exercise.id,
          strategy: config.strategy,
          params: params,
          incrementKg: increment,
          now: now,
          baselineFrom: _newBaseline ? now : _active?.baselineFrom,
        );
      }
      if (mounted) {
        _snack(unchanged ? 'Nada mudou' : 'Estratégia salva');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(progressionRegistryProvider);
    final unit = ref.watch(settingsProvider).unit;
    final issues = _issues;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estratégia de Progressão'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.exercise.setType == SetType.time
          ? const _TimeExerciseNotice()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _Section('Método'),
                RadioGroup<StrategyId?>(
                  groupValue: _strategy,
                  onChanged: (v) => setState(() => _strategy = v),
                  child: Column(
                    children: [
                      const RadioListTile<StrategyId?>(
                        contentPadding: EdgeInsets.zero,
                        value: null,
                        title: Text('Sem progressão automática'),
                        subtitle: Text('Registro manual, como sempre'),
                      ),
                      for (final s in registry.all)
                        RadioListTile<StrategyId?>(
                          contentPadding: EdgeInsets.zero,
                          value: s.id,
                          title: Text(s.displayName),
                          subtitle: Text(_strategyHint(s.id)),
                        ),
                    ],
                  ),
                ),
                if (_config != null) ...[
                  const SizedBox(height: 8),
                  _Section('Parâmetros'),
                  if (_strategy == StrategyId.doubleProgression)
                    _DoubleProgressionForm(
                      config: _double,
                      onChanged: (c) => setState(() => _double = c),
                    ),
                  if (_strategy == StrategyId.linear)
                    _LinearProgressionForm(
                      config: _linear,
                      onChanged: (c) => setState(() => _linear = c),
                    ),
                  _IncrementField(
                    controller: _increment,
                    unit: unit,
                    bodyweight: _bodyweight,
                    onChanged: () => setState(() {}),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _newBaseline,
                    onChanged: (v) => setState(() => _newBaseline = v!),
                    title: const Text('Começar nova referência hoje'),
                    subtitle: const Text(
                      'Ignora o histórico anterior (troca de equipamento, '
                      'volta após pausa).',
                    ),
                  ),
                  if (issues.isNotEmpty)
                    _Issues(issues)
                  else ...[
                    const SizedBox(height: 8),
                    _Section('Exemplo'),
                    _Example(
                      strategy: registry.strategyFor(_strategy!)!,
                      config: _config!,
                      incrementKg: _incrementKg!,
                      bodyweight: _bodyweight,
                      unit: unit,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                _Section('Recomendações anteriores'),
                _History(exercise: widget.exercise),
              ],
            ),
      floatingActionButton: _loading || widget.exercise.setType == SetType.time
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving || issues.isNotEmpty ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
    );
  }

  static String _strategyHint(StrategyId id) => switch (id) {
    StrategyId.doubleProgression =>
      'Aumenta as repetições dentro da faixa e depois a carga',
    StrategyId.linear =>
      'Meta fixa de repetições; sobe a carga após sessões bem-sucedidas',
    _ => '',
  };
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _TimeExerciseNotice extends StatelessWidget {
  const _TimeExerciseNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Text(
      'Exercícios por tempo não têm progressão automática: '
      'aumente a duração manualmente quando se sentir pronto.',
      textAlign: TextAlign.center,
    ),
  );
}

class _DoubleProgressionForm extends StatelessWidget {
  final DoubleProgressionConfig config;
  final ValueChanged<DoubleProgressionConfig> onChanged;

  const _DoubleProgressionForm({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stepper(
          label: 'Séries de trabalho',
          value: config.sets,
          min: 1,
          max: 10,
          onChanged: (v) => onChanged(
            config.copyWith(
              sets: v,
              mainSetNumber: config.mainSetNumber.clamp(1, v),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Faixa de repetições: ${config.repsMin}–${config.repsMax}',
          style: textTheme.bodyLarge,
        ),
        RangeSlider(
          values: RangeValues(
            config.repsMin.toDouble(),
            config.repsMax.toDouble(),
          ),
          min: 1,
          max: 30,
          divisions: 29,
          labels: RangeLabels('${config.repsMin}', '${config.repsMax}'),
          onChanged: (r) => onChanged(
            config.copyWith(repsMin: r.start.round(), repsMax: r.end.round()),
          ),
        ),
        Row(
          children: [
            Expanded(child: Text('RIR-alvo', style: textTheme.bodyLarge)),
            DropdownButton<int?>(
              value: config.targetRir,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sem RIR-alvo'),
                ),
                for (var v = 0; v <= 5; v++)
                  DropdownMenuItem(value: v, child: Text('RIR $v')),
              ],
              onChanged: (v) => onChanged(config.copyWith(targetRir: () => v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Subir a carga quando', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<DoubleProgressionCriterion>(
          segments: const [
            ButtonSegment(
              value: DoubleProgressionCriterion.allSets,
              label: Text('Todas no topo'),
            ),
            ButtonSegment(
              value: DoubleProgressionCriterion.mainSet,
              label: Text('Série principal'),
            ),
          ],
          selected: {config.criterion},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(criterion: s.first)),
        ),
        if (config.criterion == DoubleProgressionCriterion.mainSet)
          _Stepper(
            label: 'Série principal',
            value: config.mainSetNumber,
            min: 1,
            max: config.sets,
            format: (v) => '$vª',
            onChanged: (v) => onChanged(config.copyWith(mainSetNumber: v)),
          ),
        const SizedBox(height: 8),
        Text('Arredondar carga sugerida', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<LoadRounding>(
          segments: const [
            ButtonSegment(
              value: LoadRounding.nearest,
              label: Text('Mais próximo'),
            ),
            ButtonSegment(value: LoadRounding.down, label: Text('Para baixo')),
            ButtonSegment(value: LoadRounding.up, label: Text('Para cima')),
          ],
          selected: {config.rounding},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(rounding: s.first)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.requireMarkedValid,
          onChanged: (v) => onChanged(config.copyWith(requireMarkedValid: v)),
          title: const Text('Exigir execução marcada como válida'),
          subtitle: const Text(
            'Desligado: séries sem qualidade marcada contam como válidas',
          ),
        ),
      ],
    );
  }
}

class _LinearProgressionForm extends StatelessWidget {
  final LinearProgressionConfig config;
  final ValueChanged<LinearProgressionConfig> onChanged;

  const _LinearProgressionForm({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stepper(
          label: 'Séries de trabalho',
          value: config.sets,
          min: 1,
          max: 10,
          onChanged: (v) => onChanged(config.copyWith(sets: v)),
        ),
        _Stepper(
          label: 'Repetições por série',
          value: config.targetReps,
          min: 1,
          max: 50,
          onChanged: (v) => onChanged(config.copyWith(targetReps: v)),
        ),
        _Stepper(
          label: 'Sessões bem-sucedidas para subir',
          value: config.successesRequired,
          min: 1,
          max: 5,
          onChanged: (v) => onChanged(config.copyWith(successesRequired: v)),
        ),
        _Stepper(
          label: 'Falhas seguidas toleradas',
          value: config.failureTolerance,
          min: 1,
          max: 10,
          onChanged: (v) => onChanged(config.copyWith(failureTolerance: v)),
        ),
        const SizedBox(height: 8),
        Text(
          'Depois das falhas toleradas, sugerir',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 6),
        SegmentedButton<StallPolicy>(
          segments: const [
            ButtonSegment(value: StallPolicy.maintain, label: Text('Manter')),
            ButtonSegment(value: StallPolicy.review, label: Text('Revisar')),
            ButtonSegment(value: StallPolicy.reduce, label: Text('Reduzir')),
          ],
          selected: {config.stallPolicy},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(stallPolicy: s.first)),
        ),
        if (config.stallPolicy == StallPolicy.reduce)
          _Stepper(
            label: 'Redução sugerida',
            value: config.deloadPercent,
            min: 5,
            max: 30,
            format: (v) => '$v%',
            onChanged: (v) => onChanged(config.copyWith(deloadPercent: v)),
          ),
        Text(
          'Toda redução é só uma sugestão: nada muda sem você aceitar.',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('RIR-alvo', style: textTheme.bodyLarge)),
            DropdownButton<int?>(
              value: config.targetRir,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sem RIR-alvo'),
                ),
                for (var v = 0; v <= 5; v++)
                  DropdownMenuItem(value: v, child: Text('RIR $v')),
              ],
              onChanged: (v) => onChanged(config.copyWith(targetRir: () => v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Arredondar carga sugerida', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<LoadRounding>(
          segments: const [
            ButtonSegment(
              value: LoadRounding.nearest,
              label: Text('Mais próximo'),
            ),
            ButtonSegment(value: LoadRounding.down, label: Text('Para baixo')),
            ButtonSegment(value: LoadRounding.up, label: Text('Para cima')),
          ],
          selected: {config.rounding},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(rounding: s.first)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: config.requireMarkedValid,
          onChanged: (v) => onChanged(config.copyWith(requireMarkedValid: v)),
          title: const Text('Exigir execução marcada como válida'),
          subtitle: const Text(
            'Desligado: séries sem qualidade marcada contam como válidas',
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int)? format;

  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            format?.call(value) ?? '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _IncrementField extends StatelessWidget {
  final TextEditingController controller;
  final WeightUnit unit;
  final bool bodyweight;
  final VoidCallback onChanged;

  const _IncrementField({
    required this.controller,
    required this.unit,
    required this.bodyweight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: bodyweight
              ? 'Incremento da carga adicional'
              : 'Incremento de carga',
          helperText: 'Menor salto disponível no equipamento',
          suffixText: UnitConverter.label(unit),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _Issues extends StatelessWidget {
  final List<String> issues;
  const _Issues(this.issues);

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in issues) Text('• $i', style: TextStyle(color: error)),
        ],
      ),
    );
  }
}

/// Exemplo calculado pela própria estratégia com sessões fictícias: mostra o
/// comportamento exato da config, sem repetir regras na interface.
class _Example extends StatelessWidget {
  final ProgressionStrategy strategy;
  final ProgressionConfig config;
  final double incrementKg;
  final bool bodyweight;
  final WeightUnit unit;

  const _Example({
    required this.strategy,
    required this.config,
    required this.incrementKg,
    required this.bodyweight,
    required this.unit,
  });

  /// Cenários: rótulo e sessões (mais recente primeiro) com as reps de cada
  /// série.
  List<(String, List<List<int>>)> _scenarios() {
    List<int> all(int sets, int reps) => [for (var i = 0; i < sets; i++) reps];
    return switch (config) {
      final DoubleProgressionConfig c => [
        ('Dentro da faixa', [all(c.sets, c.repsMin)]),
        ('Topo da faixa', [all(c.sets, c.repsMax)]),
      ],
      final LinearProgressionConfig c => [
        (
          'Meta completa',
          [
            for (var i = 0; i < c.successesRequired; i++)
              all(c.sets, c.targetReps),
          ],
        ),
        (
          'Faltou 1 rep',
          [
            [
              for (var i = 0; i < c.sets; i++)
                i == c.sets - 1 ? c.targetReps - 1 : c.targetReps,
            ],
          ],
        ),
        (
          '${c.failureTolerance} falha(s) seguida(s)',
          [
            for (var i = 0; i < c.failureTolerance; i++)
              [
                for (var j = 0; j < c.sets; j++)
                  j == c.sets - 1 ? c.targetReps - 1 : c.targetReps,
              ],
          ],
        ),
      ],
      _ => const [],
    };
  }

  int? get _targetRir => switch (config) {
    final DoubleProgressionConfig c => c.targetRir,
    final LinearProgressionConfig c => c.targetRir,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final load = bodyweight
        ? null
        : UnitConverter.fromDisplay(unit == WeightUnit.lbs ? 100 : 50, unit);
    final now = DateTime.now();
    final ctx = ExerciseContext(
      exerciseId: 0,
      name: 'Exemplo',
      loadType: bodyweight
          ? ExerciseLoadType.bodyweight
          : ExerciseLoadType.weighted,
      incrementKg: incrementKg,
      formatLoad: (kg) => UnitConverter.format(kg, unit),
    );

    return Column(
      children: [
        for (final (label, sessions) in _scenarios())
          Builder(
            builder: (context) {
              final result = strategy.evaluateWith(
                config: config,
                exercise: ctx,
                now: now,
                history: [
                  for (var i = 0; i < sessions.length; i++)
                    SessionRecord(
                      sessionId: i,
                      date: now.subtract(Duration(days: 2 + 2 * i)),
                      sets: [
                        for (final r in sessions[i])
                          SetRecord(
                            weightKg: load,
                            reps: r,
                            rir: _targetRir,
                            quality: config.requireMarkedValid
                                ? ExecutionQuality.valid
                                : null,
                          ),
                      ],
                    ),
                ],
              );
              final repsText = sessions.length == 1
                  ? sessions.single.join('/')
                  : '${sessions.length} sessões de ${sessions.first.join('/')}';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('$label: $repsText'),
                  subtitle: Text(
                    result.nextTargets.isEmpty
                        ? result.explanation
                        : 'Próxima: ${describeTargets(result.nextTargets, unit, bodyweight: bodyweight)}',
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  final Exercise exercise;
  const _History({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recs = ref
        .watch(exerciseRecommendationsProvider(exercise.id))
        .valueOrNull;
    if (recs == null) return const SizedBox.shrink();
    if (recs.isEmpty) {
      return Text(
        'Nenhuma recomendação ainda.',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return Column(
      children: [
        for (final r in recs)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(_statusLabel(r.status)),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(r.generatedAt)} · '
              '${_decisionLabel(r.decision)}',
            ),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(r.explanation)],
          ),
      ],
    );
  }

  static String _statusLabel(RecommendationStatus s) => switch (s) {
    RecommendationStatus.increaseWeight => 'Subir carga',
    RecommendationStatus.increaseReps => 'Mais repetições',
    RecommendationStatus.maintain => 'Manter carga',
    RecommendationStatus.decreaseWeight => 'Reduzir carga',
    RecommendationStatus.deloadSuggested => 'Deload',
    RecommendationStatus.insufficientData => 'Dados insuficientes',
    RecommendationStatus.manualReview => 'Revisão manual',
  };

  static String _decisionLabel(RecommendationDecision d) => switch (d) {
    RecommendationDecision.pending => 'Pendente',
    RecommendationDecision.accepted => 'Aceita',
    RecommendationDecision.kept => 'Carga mantida',
    RecommendationDecision.adjusted => 'Ajustada',
    RecommendationDecision.dismissed => 'Vista',
    RecommendationDecision.superseded => 'Substituída',
  };
}
