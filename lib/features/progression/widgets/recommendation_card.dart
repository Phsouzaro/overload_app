import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/progression_repository.dart';
import '../../../core/database/tables.dart';
import '../../../core/progression/progression_enums.dart';
import '../../../core/progression/progression_models.dart';
import '../../../core/utils/unit_converter.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/progression_providers.dart';

/// Sugestão de progressão com as ações Aceitar · Manter carga atual ·
/// Ajustar · Justificativa. Nada muda nas metas sem uma dessas ações.
class RecommendationCard extends ConsumerStatefulWidget {
  final ProgressionRecommendationEntry recommendation;
  final Exercise exercise;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.exercise,
  });

  @override
  ConsumerState<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<RecommendationCard> {
  late RecommendationDecision _decision = widget.recommendation.decision;
  bool _showReasons = false;

  ProgressionRecommendationEntry get _rec => widget.recommendation;

  @override
  void didUpdateWidget(RecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendation.decision != _rec.decision) {
      _decision = _rec.decision;
    }
  }

  Future<void> _decide(
    RecommendationDecision decision, {
    List<SetTarget>? finalTargets,
  }) async {
    await ref
        .read(progressionRepositoryProvider)
        .decide(
          _rec.id,
          decision,
          now: DateTime.now(),
          finalTargets: finalTargets,
        );
    if (mounted) setState(() => _decision = decision);
  }

  Future<void> _adjust(List<SetTarget> targets, WeightUnit unit) async {
    final adjusted = await showDialog<List<SetTarget>>(
      context: context,
      builder: (_) => _AdjustDialog(
        targets: targets,
        unit: unit,
        bodyweight: widget.exercise.setType == SetType.bodyweight,
      ),
    );
    if (adjusted != null) {
      await _decide(RecommendationDecision.adjusted, finalTargets: adjusted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unit = ref.watch(settingsProvider).unit;
    final targets = ProgressionRepository.decodeTargets(
      _rec.recommendedTargetsJson,
    );
    final bodyweight = widget.exercise.setType == SetType.bodyweight;
    final (title, icon, color) = _headline(_rec.status, cs);
    final pending = _decision == RecommendationDecision.pending;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.exercise.name,
              style: textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 8),
            Text(_rec.explanation, style: textTheme.bodyMedium),
            if (targets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Próxima sessão sugerida:', style: textTheme.labelMedium),
              Text(
                describeTargets(targets, unit, bodyweight: bodyweight),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
            if (_showReasons) _Reasons(recommendation: _rec),
            const SizedBox(height: 4),
            if (pending)
              Wrap(
                spacing: 4,
                children: [
                  if (targets.isNotEmpty) ...[
                    FilledButton(
                      onPressed: () => _decide(RecommendationDecision.accepted),
                      child: const Text('Aceitar sugestão'),
                    ),
                    TextButton(
                      onPressed: () => _decide(RecommendationDecision.kept),
                      child: const Text('Manter carga atual'),
                    ),
                    TextButton(
                      onPressed: () => _adjust(targets, unit),
                      child: const Text('Ajustar'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () =>
                          _decide(RecommendationDecision.dismissed),
                      child: const Text('Entendi'),
                    ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showReasons = !_showReasons),
                    child: Text(
                      _showReasons ? 'Ocultar justificativa' : 'Justificativa',
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _decisionLabel(_decision),
                      style: textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showReasons = !_showReasons),
                    child: Text(_showReasons ? 'Ocultar' : 'Justificativa'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static (String, IconData, Color) _headline(
    RecommendationStatus status,
    ColorScheme cs,
  ) {
    return switch (status) {
      RecommendationStatus.increaseWeight => (
        'Progressão identificada!',
        Icons.trending_up,
        cs.primary,
      ),
      RecommendationStatus.increaseReps => (
        'Busque mais repetições',
        Icons.add_task,
        cs.primary,
      ),
      RecommendationStatus.maintain => (
        'Mantenha a carga',
        Icons.pause_circle_outline,
        cs.secondary,
      ),
      RecommendationStatus.decreaseWeight => (
        'Redução de carga sugerida',
        Icons.trending_down,
        cs.tertiary,
      ),
      RecommendationStatus.deloadSuggested => (
        'Deload sugerido',
        Icons.battery_charging_full,
        cs.tertiary,
      ),
      RecommendationStatus.insufficientData => (
        'Dados insuficientes',
        Icons.info_outline,
        cs.outline,
      ),
      RecommendationStatus.manualReview => (
        'Revisão necessária',
        Icons.rate_review_outlined,
        cs.tertiary,
      ),
    };
  }

  static String _decisionLabel(RecommendationDecision d) => switch (d) {
    RecommendationDecision.accepted =>
      'Sugestão aceita: vale para o próximo treino.',
    RecommendationDecision.adjusted =>
      'Ajuste salvo: vale para o próximo treino.',
    RecommendationDecision.kept =>
      'Carga atual mantida. O próximo treino segue como sempre.',
    RecommendationDecision.dismissed => 'Ok, registrado.',
    RecommendationDecision.superseded =>
      'Substituída por uma sugestão mais recente.',
    RecommendationDecision.pending => '',
  };
}

/// Ex: "52,5 kg — 3 × 8–12". Metas diferentes entre séries são listadas.
String describeTargets(
  List<SetTarget> targets,
  WeightUnit unit, {
  bool bodyweight = false,
}) {
  String load(double? kg) {
    if (bodyweight) {
      return kg == null || kg <= 0
          ? 'Peso corporal'
          : 'Peso corporal ${UnitConverter.extraLoad(kg, unit).trim()}';
    }
    return kg == null ? '—' : UnitConverter.format(kg, unit);
  }

  String reps(SetTarget t) {
    if (t.repsMin == null) return '';
    return t.repsMax == null || t.repsMax == t.repsMin
        ? '${t.repsMin}'
        : '${t.repsMin}–${t.repsMax}';
  }

  final first = targets.first;
  final uniform = targets.every(
    (t) =>
        t.weightKg == first.weightKg &&
        t.repsMin == first.repsMin &&
        t.repsMax == first.repsMax,
  );
  final rir = first.rir != null ? ' · RIR ${first.rir}' : '';
  if (uniform) {
    final r = reps(first);
    return '${load(first.weightKg)} — ${targets.length}${r.isEmpty ? ' séries' : ' × $r'}$rir';
  }
  return [
    for (final t in targets) '${load(t.weightKg)} × ${reps(t)}',
  ].join('  ·  ');
}

class _Reasons extends StatelessWidget {
  final ProgressionRecommendationEntry recommendation;

  const _Reasons({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final met = ProgressionRepository.decodeCriteria(
      recommendation.criteriaMetJson,
    );
    final unmet = ProgressionRepository.decodeCriteria(
      recommendation.criteriaUnmetJson,
    );

    Widget line(Criterion c, bool ok) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check : Icons.close,
            size: 16,
            color: ok ? cs.primary : cs.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              c.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (met.isEmpty && unmet.isEmpty)
            Text(
              'Sem critérios avaliados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final c in met) line(c, true),
          for (final c in unmet) line(c, false),
          const SizedBox(height: 6),
          Text(
            'Sugestões são apoio ao treino, não garantia de segurança. '
            'Ajuste conforme se sentir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ajuste manual: mesma carga e faixa para todas as séries sugeridas.
class _AdjustDialog extends StatefulWidget {
  final List<SetTarget> targets;
  final WeightUnit unit;
  final bool bodyweight;

  const _AdjustDialog({
    required this.targets,
    required this.unit,
    required this.bodyweight,
  });

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  late final _weight = TextEditingController(
    text: widget.targets.first.weightKg == null
        ? ''
        : UnitConverter.toDisplay(
            widget.targets.first.weightKg!,
            widget.unit,
          ).toStringAsFixed(1),
  );
  late final _min = TextEditingController(
    text: widget.targets.first.repsMin?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.targets.first.repsMax?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _save() {
    final display = double.tryParse(_weight.text.replaceAll(',', '.'));
    final min = int.tryParse(_min.text);
    final max = int.tryParse(_max.text) ?? min;
    if ((!widget.bodyweight && (display == null || display <= 0)) ||
        min == null ||
        min < 1 ||
        max! < min) {
      setState(() => _error = 'Confira a carga e a faixa de repetições');
      return;
    }
    final kg = display == null || display <= 0
        ? null
        : UnitConverter.fromDisplay(display, widget.unit);
    Navigator.pop(context, [
      for (final t in widget.targets)
        SetTarget(
          role: t.role,
          weightKg: kg,
          repsMin: min,
          repsMax: max,
          rir: t.rir,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final label = UnitConverter.label(widget.unit);
    return AlertDialog(
      title: const Text('Ajustar sugestão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.bodyweight ? 'Carga adicional' : 'Carga',
              suffixText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps mín.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps máx.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
