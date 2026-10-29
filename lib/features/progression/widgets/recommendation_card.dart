import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/progression_repository.dart';
import '../../../core/database/tables.dart';
import '../../../core/progression/progression_enums.dart';
import '../../../core/progression/progression_models.dart';
import '../../../core/utils/unit_converter.dart';
import '../../active_session/widgets/set_details_sheet.dart' show formatRpe;
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
    final (title, icon, color) = recommendationHeadline(
      _rec.status,
      _rec.reasonCode,
      cs,
    );
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

/// Título, ícone e cor de uma recomendação: usados no card e no histórico.
(String, IconData, Color) recommendationHeadline(
  RecommendationStatus status,
  String reasonCode,
  ColorScheme cs,
) {
  // Progressão em ondas: o avanço no ciclo não é "subir" nem "manter".
  switch (reasonCode) {
    case 'cycleStart':
      return ('Início do ciclo de ondas', Icons.waves, cs.primary);
    case 'waveCompleted':
      return ('Onda concluída!', Icons.waves, cs.primary);
    case 'cycleCompleted':
      return ('Ciclo concluído!', Icons.trending_up, cs.primary);
    case 'waveFailed' || 'waveIncomplete' || 'waveInterrupted':
      return ('Repita a onda', Icons.replay, cs.secondary);
    case 'cycleRestarted':
      return ('Ciclo reiniciado', Icons.restart_alt, cs.tertiary);
  }
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
  final rpe = first.rpe != null ? ' · RPE ${formatRpe(first.rpe!)}' : '';
  if (uniform) {
    final r = reps(first);
    return '${load(first.weightKg)} — ${targets.length}${r.isEmpty ? ' séries' : ' × $r'}$rir$rpe';
  }
  // Metas diferentes: agrupa séries seguidas iguais, com o papel quando há
  // estrutura (ex: "Principal: 72.5 kg × 4–6 · Back-off: 3 × 62.5 kg × 8–10").
  final groups = <(SetTarget, int)>[];
  for (final t in targets) {
    final last = groups.lastOrNull;
    if (last != null &&
        last.$1.role == t.role &&
        last.$1.weightKg == t.weightKg &&
        last.$1.repsMin == t.repsMin &&
        last.$1.repsMax == t.repsMax) {
      groups[groups.length - 1] = (last.$1, last.$2 + 1);
    } else {
      groups.add((t, 1));
    }
  }
  String role(SetRole r) => switch (r) {
    SetRole.topSet => 'Principal: ',
    SetRole.backOff => 'Back-off: ',
    // Ondas: as cargas em sequência já dizem a estrutura.
    SetRole.wave || SetRole.work => '',
  };
  return [
    for (final (t, n) in groups)
      '${role(t.role)}${n > 1 ? '$n × ' : ''}${load(t.weightKg)} × ${reps(t)}'
          '${t.rir != null ? ' · RIR ${t.rir}' : ''}'
          '${t.rpe != null ? ' · RPE ${formatRpe(t.rpe!)}' : ''}',
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

/// Ajuste manual. Séries seguidas com a mesma meta (ex: todo o back-off)
/// são ajustadas juntas; metas diferentes (série principal × back-off, as
/// cargas de uma onda) são ajustadas separadamente, preservando a estrutura
/// e a ordem planejada.
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

class _RoleFields {
  final SetTarget first;
  final TextEditingController weight;
  final TextEditingController min;
  final TextEditingController max;

  _RoleFields(this.first, WeightUnit unit)
    : weight = TextEditingController(
        text: first.weightKg == null
            ? ''
            : UnitConverter.toDisplay(first.weightKg!, unit).toStringAsFixed(1),
      ),
      min = TextEditingController(text: first.repsMin?.toString() ?? ''),
      max = TextEditingController(text: first.repsMax?.toString() ?? '');

  void dispose() {
    weight.dispose();
    min.dispose();
    max.dispose();
  }
}

class _AdjustDialogState extends State<_AdjustDialog> {
  /// Um grupo de campos por sequência de séries iguais (mesmo papel, carga e
  /// faixa), na ordem planejada, com quantas séries ele cobre.
  final List<(_RoleFields, int)> _groups = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final t in widget.targets) {
      final last = _groups.lastOrNull;
      if (last != null &&
          last.$1.first.role == t.role &&
          last.$1.first.weightKg == t.weightKg &&
          last.$1.first.repsMin == t.repsMin &&
          last.$1.first.repsMax == t.repsMax) {
        _groups[_groups.length - 1] = (last.$1, last.$2 + 1);
      } else {
        _groups.add((_RoleFields(t, widget.unit), 1));
      }
    }
  }

  @override
  void dispose() {
    for (final (f, _) in _groups) {
      f.dispose();
    }
    super.dispose();
  }

  void _save() {
    final adjusted = <SetTarget>[];
    for (final (f, count) in _groups) {
      final role = f.first.role;
      final display = double.tryParse(f.weight.text.replaceAll(',', '.'));
      final min = int.tryParse(f.min.text);
      final max = int.tryParse(f.max.text) ?? min;
      if ((!widget.bodyweight && (display == null || display <= 0)) ||
          min == null ||
          min < 1 ||
          max! < min) {
        setState(() => _error = 'Confira as cargas e as faixas de repetições');
        return;
      }
      final target = SetTarget(
        role: role,
        weightKg: display == null || display <= 0
            ? null
            : UnitConverter.fromDisplay(display, widget.unit),
        repsMin: min,
        repsMax: max,
        rir: f.first.rir,
        rpe: f.first.rpe,
      );
      adjusted.addAll(List.filled(count, target));
    }
    Navigator.pop(context, adjusted);
  }

  /// "Back-off", ou "Onda · séries 4–6" quando o papel tem vários grupos.
  String _title(int index) {
    final role = _groups[index].$1.first.role;
    final sameRole = _groups.where((g) => g.$1.first.role == role).length;
    if (sameRole == 1) return _roleTitle(role);
    var start = 1;
    for (var i = 0; i < index; i++) {
      start += _groups[i].$2;
    }
    final end = start + _groups[index].$2 - 1;
    return '${_roleTitle(role)} · ${start == end ? 'série $start' : 'séries $start–$end'}';
  }

  static String _roleTitle(SetRole role) => switch (role) {
    SetRole.topSet => 'Série principal',
    SetRole.backOff => 'Back-off',
    SetRole.wave => 'Onda',
    SetRole.work => 'Séries',
  };

  @override
  Widget build(BuildContext context) {
    final label = UnitConverter.label(widget.unit);
    final grouped = _groups.length > 1;

    Widget group(int index, _RoleFields f) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped) ...[
          Text(_title(index), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: f.weight,
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
                controller: f.min,
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
                controller: f.max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps máx.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return AlertDialog(
      title: const Text('Ajustar sugestão'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _groups.length; i++) ...[
              group(i, _groups[i].$1),
              const SizedBox(height: 16),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
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
