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
import '../../../core/progression/strategies/rir_based_progression.dart';
import '../../../core/progression/strategies/rpe_based_progression.dart';
import '../../../core/progression/strategies/top_set_back_off.dart';
import '../../../core/progression/strategies/wave_loading.dart';
import '../../active_session/widgets/set_details_sheet.dart'
    show formatRpe, rpeScale;
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
  RirBasedConfig _rir = const RirBasedConfig();
  RpeBasedConfig _rpe = const RpeBasedConfig();
  TopSetBackOffConfig _topSet = const TopSetBackOffConfig();
  WaveLoadingConfig _wave = const WaveLoadingConfig();
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
        case StrategyId.rirBased:
          _rir = RirBasedConfig.fromJson(params);
        case StrategyId.rpeBased:
          _rpe = RpeBasedConfig.fromJson(params);
        case StrategyId.topSetBackOff:
          _topSet = TopSetBackOffConfig.fromJson(params);
        case StrategyId.waveLoading:
          _wave = WaveLoadingConfig.fromJson(params);
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
    StrategyId.rirBased => _rir,
    StrategyId.rpeBased => _rpe,
    StrategyId.topSetBackOff => _topSet,
    StrategyId.waveLoading => _wave,
    null => null,
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
                        if (s.supportsLoadType(
                          _bodyweight
                              ? ExerciseLoadType.bodyweight
                              : ExerciseLoadType.weighted,
                        ))
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
                  if (_strategy == StrategyId.rirBased)
                    _RirBasedForm(
                      config: _rir,
                      onChanged: (c) => setState(() => _rir = c),
                    ),
                  if (_strategy == StrategyId.rpeBased)
                    _RpeBasedForm(
                      config: _rpe,
                      onChanged: (c) => setState(() => _rpe = c),
                    ),
                  if (_strategy == StrategyId.topSetBackOff)
                    _TopSetBackOffForm(
                      config: _topSet,
                      onChanged: (c) => setState(() => _topSet = c),
                    ),
                  if (_strategy == StrategyId.waveLoading)
                    _WaveLoadingForm(
                      config: _wave,
                      unit: unit,
                      onChanged: (c) => setState(() => _wave = c),
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
    StrategyId.rirBased =>
      'Usa o RIR que você informa e a faixa de repetições para subir a carga',
    StrategyId.rpeBased =>
      'Usa o esforço percebido (RPE 6–10) e a faixa de repetições',
    StrategyId.topSetBackOff =>
      'Uma série pesada e séries de redução, cada uma com sua meta',
    StrategyId.waveLoading =>
      'Sequência de ondas planejadas; avança só quando a onda é concluída',
  };
}

/// Ondas editáveis: cada onda tem as próprias séries, com repetições e
/// percentual da carga de referência, na ordem em que serão feitas.
class _WaveLoadingForm extends StatefulWidget {
  final WaveLoadingConfig config;
  final WeightUnit unit;
  final ValueChanged<WaveLoadingConfig> onChanged;

  const _WaveLoadingForm({
    required this.config,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_WaveLoadingForm> createState() => _WaveLoadingFormState();
}

class _WaveLoadingFormState extends State<_WaveLoadingForm> {
  late final TextEditingController _base = TextEditingController(
    text: widget.config.baseKg == null
        ? ''
        : _ProgressionConfigScreenState._formatNumber(
            UnitConverter.toDisplay(widget.config.baseKg!, widget.unit),
          ),
  );

  WaveLoadingConfig get _c => widget.config;

  @override
  void dispose() {
    _base.dispose();
    super.dispose();
  }

  void _setWaves(List<List<WaveStep>> waves) =>
      widget.onChanged(_c.copyWith(waves: waves));

  List<List<WaveStep>> get _copy => [
    for (final w in _c.waves) [...w],
  ];

  void _updateStep(int w, int s, {int? reps, double? percent}) {
    final waves = _copy;
    final old = waves[w][s];
    waves[w][s] = WaveStep(
      reps: reps ?? old.reps,
      percent: percent ?? old.percent,
    );
    _setWaves(waves);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;

    Widget adjust(String text, VoidCallback? minus, VoidCallback? plus) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.remove),
          onPressed: minus,
        ),
        SizedBox(
          width: 52,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.add),
          onPressed: plus,
        ),
      ],
    );

    Widget wave(int w) {
      final steps = _c.waves[w];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Onda ${w + 1} · ${WaveLoadingConfig.describeWave(steps)}',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  if (_c.waves.length > 1)
                    IconButton(
                      tooltip: 'Remover onda',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _setWaves(_copy..removeAt(w)),
                    ),
                ],
              ),
              for (var s = 0; s < steps.length; s++)
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${s + 1}', style: textTheme.bodySmall),
                    ),
                    adjust(
                      '${steps[s].reps} reps',
                      steps[s].reps > 1
                          ? () => _updateStep(w, s, reps: steps[s].reps - 1)
                          : null,
                      steps[s].reps < 30
                          ? () => _updateStep(w, s, reps: steps[s].reps + 1)
                          : null,
                    ),
                    adjust(
                      '${formatRpe(steps[s].percent)}%',
                      steps[s].percent > 30
                          ? () => _updateStep(
                              w,
                              s,
                              percent: steps[s].percent - 2.5 < 30
                                  ? 30
                                  : steps[s].percent - 2.5,
                            )
                          : null,
                      steps[s].percent < 120
                          ? () => _updateStep(
                              w,
                              s,
                              percent: steps[s].percent + 2.5 > 120
                                  ? 120
                                  : steps[s].percent + 2.5,
                            )
                          : null,
                    ),
                    const Spacer(),
                    if (steps.length > 1)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remover série',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _setWaves(_copy..[w].removeAt(s)),
                      ),
                  ],
                ),
              if (steps.length < 8)
                TextButton.icon(
                  onPressed: () => _setWaves(_copy..[w].add(steps.last)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Série'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cada onda é uma sessão. Percentuais sobre a carga de referência '
          '(100%), arredondados ao incremento.',
          style: textTheme.bodySmall?.copyWith(color: outline),
        ),
        const SizedBox(height: 4),
        for (var w = 0; w < _c.waves.length; w++) wave(w),
        if (_c.waves.length < 6)
          TextButton.icon(
            // A nova onda parte da última, 5% mais pesada: o usuário ajusta.
            onPressed: () => _setWaves([
              ..._copy,
              [
                for (final s in _c.waves.last)
                  WaveStep(
                    reps: s.reps,
                    percent: s.percent + 5 > 120 ? 120 : s.percent + 5,
                  ),
              ],
            ]),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar onda'),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _base,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final display = double.tryParse(v.replaceAll(',', '.'));
            // Texto ilegível vira carga inválida, para a validação acusar
            // em vez de cair silenciosamente no cálculo automático.
            widget.onChanged(
              _c.copyWith(
                baseKg: () => display == null
                    ? (v.trim().isEmpty ? null : -1)
                    : UnitConverter.fromDisplay(display, widget.unit),
              ),
            );
          },
          decoration: InputDecoration(
            labelText: 'Carga de referência (100%)',
            helperText: 'Vazio: calculada pela última sessão',
            suffixText: UnitConverter.label(widget.unit),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        _Stepper(
          label: 'Incrementos por ciclo',
          value: _c.cycleIncrements,
          min: 1,
          max: 5,
          onChanged: (v) => widget.onChanged(_c.copyWith(cycleIncrements: v)),
        ),
        _Stepper(
          label: 'Tentativas antes de revisar',
          value: _c.failureTolerance,
          min: 1,
          max: 5,
          onChanged: (v) => widget.onChanged(_c.copyWith(failureTolerance: v)),
        ),
        Text('Falha técnica', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<TechnicalFailurePolicy>(
          segments: const [
            ButtonSegment(
              value: TechnicalFailurePolicy.repeatWave,
              label: Text('Repetir a onda'),
            ),
            ButtonSegment(
              value: TechnicalFailurePolicy.restartCycle,
              label: Text('Recomeçar o ciclo'),
            ),
          ],
          selected: {_c.onTechnicalFailure},
          onSelectionChanged: (s) =>
              widget.onChanged(_c.copyWith(onTechnicalFailure: s.first)),
        ),
        const SizedBox(height: 4),
        Text(
          'Onda concluída avança para a próxima; onda malsucedida é '
          'repetida. A última onda concluída sobe a referência.',
          style: textTheme.bodySmall?.copyWith(color: outline),
        ),
        const SizedBox(height: 8),
        Text('Arredondar cargas', style: textTheme.bodyLarge),
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
          selected: {_c.rounding},
          onSelectionChanged: (s) =>
              widget.onChanged(_c.copyWith(rounding: s.first)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _c.requireMarkedValid,
          onChanged: (v) =>
              widget.onChanged(_c.copyWith(requireMarkedValid: v)),
          title: const Text('Exigir execução marcada como válida'),
          subtitle: const Text(
            'Desligado: séries sem qualidade marcada contam como válidas',
          ),
        ),
      ],
    );
  }
}

class _TopSetBackOffForm extends StatelessWidget {
  final TopSetBackOffConfig config;
  final ValueChanged<TopSetBackOffConfig> onChanged;

  const _TopSetBackOffForm({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;

    Widget range(
      String label,
      int min,
      int max,
      int limit,
      void Function(int min, int max) onRange,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $min–$max', style: textTheme.bodyLarge),
        RangeSlider(
          values: RangeValues(min.toDouble(), max.toDouble()),
          min: 1,
          max: limit.toDouble(),
          divisions: limit - 1,
          labels: RangeLabels('$min', '$max'),
          onChanged: (r) => onRange(r.start.round(), r.end.round()),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Série principal', style: textTheme.titleSmall),
        range(
          'Repetições',
          config.topRepsMin,
          config.topRepsMax,
          20,
          (a, b) => onChanged(config.copyWith(topRepsMin: a, topRepsMax: b)),
        ),
        Row(
          children: [
            Expanded(child: Text('RIR-alvo', style: textTheme.bodyLarge)),
            DropdownButton<int?>(
              value: config.topTargetRir,
              items: [
                const DropdownMenuItem(value: null, child: Text('Sem RIR')),
                for (var v = 0; v <= 5; v++)
                  DropdownMenuItem(value: v, child: Text('RIR $v')),
              ],
              onChanged: (v) =>
                  onChanged(config.copyWith(topTargetRir: () => v)),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('RPE máximo', style: textTheme.bodyLarge)),
            DropdownButton<double?>(
              value: config.topTargetRpe,
              items: [
                const DropdownMenuItem(value: null, child: Text('Sem RPE')),
                for (final v in rpeScale)
                  DropdownMenuItem(
                    value: v,
                    child: Text('RPE ${formatRpe(v)}'),
                  ),
              ],
              onChanged: (v) =>
                  onChanged(config.copyWith(topTargetRpe: () => v)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Back-off', style: textTheme.titleSmall),
        _Stepper(
          label: 'Séries de back-off',
          value: config.backOffSets,
          min: 1,
          max: 6,
          onChanged: (v) => onChanged(config.copyWith(backOffSets: v)),
        ),
        _Stepper(
          label: 'Redução da carga',
          value: config.backOffPercent,
          min: 5,
          max: 40,
          format: (v) => '−$v%',
          onChanged: (v) => onChanged(config.copyWith(backOffPercent: v)),
        ),
        range(
          'Repetições',
          config.backOffRepsMin,
          config.backOffRepsMax,
          30,
          (a, b) =>
              onChanged(config.copyWith(backOffRepsMin: a, backOffRepsMax: b)),
        ),
        Text(
          'O back-off é calculado sobre a carga da série principal e '
          'arredondado ao incremento. Cada parte sobe pela própria meta; '
          'a redução planejada não conta como regressão.',
          style: textTheme.bodySmall?.copyWith(color: outline),
        ),
        const SizedBox(height: 8),
        Text('Arredondar cargas', style: textTheme.bodyLarge),
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

class _RpeBasedForm extends StatelessWidget {
  final RpeBasedConfig config;
  final ValueChanged<RpeBasedConfig> onChanged;

  const _RpeBasedForm({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;
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
            Expanded(child: Text('RPE-alvo', style: textTheme.bodyLarge)),
            DropdownButton<double>(
              value: config.targetRpe,
              items: [
                for (final v in rpeScale)
                  DropdownMenuItem(
                    value: v,
                    child: Text('RPE ${formatRpe(v)}'),
                  ),
              ],
              onChanged: (v) => onChanged(config.copyWith(targetRpe: v)),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text('Tolerância de RPE', style: textTheme.bodyLarge),
            ),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0, label: Text('±0')),
                ButtonSegment(value: 0.5, label: Text('±0,5')),
                ButtonSegment(value: 1, label: Text('±1')),
              ],
              selected: {config.rpeTolerance},
              onSelectionChanged: (s) =>
                  onChanged(config.copyWith(rpeTolerance: s.first)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'A carga só sobe com RPE de no máximo '
          '${formatRpe(config.targetRpe + config.rpeTolerance)} e todas as '
          'séries no topo da faixa. RPE não é convertido em RIR.',
          style: textTheme.bodySmall?.copyWith(color: outline),
        ),
        const SizedBox(height: 8),
        Text('Avaliar o RPE de', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<EffortCriterion>(
          segments: const [
            ButtonSegment(
              value: EffortCriterion.allSets,
              label: Text('Todas as séries'),
            ),
            ButtonSegment(
              value: EffortCriterion.lastSet,
              label: Text('Última série'),
            ),
          ],
          selected: {config.criterion},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(criterion: s.first)),
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

class _RirBasedForm extends StatelessWidget {
  final RirBasedConfig config;
  final ValueChanged<RirBasedConfig> onChanged;

  const _RirBasedForm({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;
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
        _Stepper(
          label: 'RIR-alvo',
          value: config.targetRir,
          min: 0,
          max: 5,
          onChanged: (v) => onChanged(config.copyWith(targetRir: v)),
        ),
        _Stepper(
          label: 'Tolerância de RIR',
          value: config.rirTolerance,
          min: 0,
          max: 2,
          format: (v) => '±$v',
          onChanged: (v) => onChanged(config.copyWith(rirTolerance: v)),
        ),
        Text(
          'A carga só sobe com RIR de pelo menos '
          '${config.targetRir - config.rirTolerance} e todas as séries no '
          'topo da faixa. RIR alto sozinho não sobe a carga.',
          style: textTheme.bodySmall?.copyWith(color: outline),
        ),
        const SizedBox(height: 8),
        Text('Avaliar o RIR de', style: textTheme.bodyLarge),
        const SizedBox(height: 6),
        SegmentedButton<EffortCriterion>(
          segments: const [
            ButtonSegment(
              value: EffortCriterion.allSets,
              label: Text('Todas as séries'),
            ),
            ButtonSegment(
              value: EffortCriterion.lastSet,
              label: Text('Última série'),
            ),
          ],
          selected: {config.criterion},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(criterion: s.first)),
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

class _Scenario {
  final String label;

  /// Sessões (mais recente primeiro), cada uma com as reps de cada série.
  final List<List<int>> sessions;
  final int? rir;
  final double? rpe;

  /// Papel e carga de cada série, quando a estrutura não é "todas iguais"
  /// (ex: série principal + back-off). `null` = papel nenhum, carga base.
  final List<SetRole>? roles;
  final List<double>? loads;

  /// Qualidade de cada série (`null` = padrão da config).
  final List<ExecutionQuality?>? qualities;

  /// Estado anterior da estratégia (ex: posição no ciclo de ondas).
  final Map<String, Object?> state;

  const _Scenario(
    this.label,
    this.sessions, {
    this.rir,
    this.rpe,
    this.roles,
    this.loads,
    this.qualities,
    this.state = const {},
  });
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

  /// Cenários: rótulo, sessões (mais recente primeiro) com as reps de cada
  /// série, e o RIR/RPE registrados nelas (`null` = não registrado).
  List<_Scenario> _scenarios(double? load) {
    List<int> all(int sets, int reps) => [for (var i = 0; i < sets; i++) reps];
    List<int> missOne(int sets, int reps) => [
      for (var i = 0; i < sets; i++) i == sets - 1 ? reps - 1 : reps,
    ];
    return switch (config) {
      final DoubleProgressionConfig c => [
        _Scenario('Dentro da faixa', [
          all(c.sets, c.repsMin),
        ], rir: c.targetRir),
        _Scenario('Topo da faixa', [all(c.sets, c.repsMax)], rir: c.targetRir),
      ],
      final LinearProgressionConfig c => [
        _Scenario('Meta completa', [
          for (var i = 0; i < c.successesRequired; i++)
            all(c.sets, c.targetReps),
        ], rir: c.targetRir),
        _Scenario('Faltou 1 rep', [
          missOne(c.sets, c.targetReps),
        ], rir: c.targetRir),
        _Scenario('${c.failureTolerance} falha(s) seguida(s)', [
          for (var i = 0; i < c.failureTolerance; i++)
            missOne(c.sets, c.targetReps),
        ], rir: c.targetRir),
      ],
      final RirBasedConfig c => [
        _Scenario('Topo com RIR ${c.targetRir}', [
          all(c.sets, c.repsMax),
        ], rir: c.targetRir),
        if (c.targetRir - c.rirTolerance - 1 >= 0)
          _Scenario(
            'Topo com RIR ${c.targetRir - c.rirTolerance - 1} (esforço alto)',
            [all(c.sets, c.repsMax)],
            rir: c.targetRir - c.rirTolerance - 1,
          ),
        _Scenario('Topo sem RIR registrado', [all(c.sets, c.repsMax)]),
      ],
      final RpeBasedConfig c => [
        _Scenario('Topo com RPE ${formatRpe(c.targetRpe)}', [
          all(c.sets, c.repsMax),
        ], rpe: c.targetRpe),
        if (c.targetRpe + c.rpeTolerance + 0.5 <= 10)
          _Scenario(
            'Topo com RPE ${formatRpe(c.targetRpe + c.rpeTolerance + 0.5)} '
            '(esforço alto)',
            [all(c.sets, c.repsMax)],
            rpe: c.targetRpe + c.rpeTolerance + 0.5,
          ),
        _Scenario('Topo sem RPE registrado', [all(c.sets, c.repsMax)]),
      ],
      final TopSetBackOffConfig c => () {
        final top = load ?? 0;
        // Simula o back-off que o usuário teria feito: o próprio percentual,
        // arredondado ao incremento (função do motor, não regra nova).
        final backOff = ProgressionRules.roundToIncrement(
          top * (1 - c.backOffPercent / 100),
          incrementKg,
          mode: c.rounding,
        );
        final roles = [
          SetRole.topSet,
          for (var i = 0; i < c.backOffSets; i++) SetRole.backOff,
        ];
        final loads = [top, for (var i = 0; i < c.backOffSets; i++) backOff];
        List<int> reps(int topReps, int backOffReps) => [
          topReps,
          for (var i = 0; i < c.backOffSets; i++) backOffReps,
        ];
        return [
          _Scenario(
            'Principal no topo',
            [reps(c.topRepsMax, c.backOffRepsMin)],
            rir: c.topTargetRir,
            rpe: c.topTargetRpe,
            roles: roles,
            loads: loads,
          ),
          _Scenario(
            'Back-off no topo',
            [reps(c.topRepsMin, c.backOffRepsMax)],
            rir: c.topTargetRir,
            rpe: c.topTargetRpe,
            roles: roles,
            loads: loads,
          ),
          if (c.backOffRepsMin > 1)
            _Scenario(
              'Back-off abaixo do mínimo',
              [reps(c.topRepsMax, c.backOffRepsMin - 1)],
              rir: c.topTargetRir,
              rpe: c.topTargetRpe,
              roles: roles,
              loads: loads,
            ),
        ];
      }(),
      final WaveLoadingConfig c => () {
        // Sessões que seguem o plano do próprio motor (planFor), na onda
        // indicada pelo estado: nada de regra repetida na interface.
        final base = c.baseKg ?? WaveLoadingStrategy.inferBase(
          c,
          load ?? 0,
          incrementKg,
        );
        _Scenario at(
          String label,
          int wave, {
          bool missLast = false,
          bool technicalFailure = false,
        }) {
          final plan = WaveLoadingStrategy.planFor(c, wave, base, incrementKg);
          return _Scenario(
            label,
            [
              [
                for (var i = 0; i < plan.length; i++)
                  missLast && i == plan.length - 1
                      ? plan[i].repsMin! - 1
                      : plan[i].repsMin!,
              ],
            ],
            roles: [for (final _ in plan) SetRole.wave],
            loads: [for (final t in plan) t.weightKg!],
            qualities: [
              for (var i = 0; i < plan.length; i++)
                technicalFailure && i == 0
                    ? ExecutionQuality.technicalFailure
                    : null,
            ],
            state: WaveState(cycle: 1, wave: wave, baseKg: base).toJson(),
          );
        }

        final last = c.waves.length - 1;
        return [
          at('Onda 1 completa', 0),
          if (c.waves.first.last.reps > 1)
            at('Onda 1 com 1 rep a menos', 0, missLast: true),
          at('Onda 1 com falha técnica', 0, technicalFailure: true),
          if (last > 0) at('Onda ${last + 1} completa', last),
        ];
      }(),
      _ => const [],
    };
  }

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
        for (final _Scenario(
              :label,
              :sessions,
              :rir,
              :rpe,
              :roles,
              :loads,
              :qualities,
              :state,
            )
            in _scenarios(load))
          Builder(
            builder: (context) {
              final result = strategy.evaluateWith(
                config: config,
                exercise: ctx,
                now: now,
                previousState: state,
                history: [
                  for (var i = 0; i < sessions.length; i++)
                    SessionRecord(
                      sessionId: i,
                      date: now.subtract(Duration(days: 2 + 2 * i)),
                      sets: [
                        for (var j = 0; j < sessions[i].length; j++)
                          SetRecord(
                            weightKg: loads?[j] ?? load,
                            reps: sessions[i][j],
                            role: roles?[j],
                            rir: rir,
                            rpe: rpe,
                            quality:
                                qualities?[j] ??
                                (config.requireMarkedValid
                                    ? ExecutionQuality.valid
                                    : null),
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
                    result.nextTargets.isEmpty ||
                            result.status ==
                                RecommendationStatus.insufficientData
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
