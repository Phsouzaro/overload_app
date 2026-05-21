import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

class SetRowWidget extends StatefulWidget {
  final SessionSet set;
  final int index;
  final double? prWeight;
  final double? hintWeight;
  final int? hintReps;
  final int? hintDuration;
  final Future<void> Function(
    double? weight,
    int? reps,
    int? duration,
    bool isWarmup,
    bool toFailure,
  ) onConfirm;
  final VoidCallback onDelete;

  const SetRowWidget({
    super.key,
    required this.set,
    required this.index,
    required this.onConfirm,
    required this.onDelete,
    this.prWeight,
    this.hintWeight,
    this.hintReps,
    this.hintDuration,
  });

  @override
  State<SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<SetRowWidget> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationController;
  late bool _isWarmup;
  late bool _toFailure;
  bool _confirmed = false;

  bool get _isPR {
    if (!_confirmed || _isWarmup) return false;
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) return false;
    if (widget.prWeight == null) return true;
    return weight > widget.prWeight!;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _weightController = TextEditingController(
      text: s.weightKg?.toStringAsFixed(1) ??
          widget.hintWeight?.toStringAsFixed(1) ??
          '',
    );
    _repsController = TextEditingController(
      text: s.reps?.toString() ?? widget.hintReps?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: s.durationSeconds?.toString() ??
          widget.hintDuration?.toString() ??
          '',
    );
    _isWarmup = s.isWarmup;
    _toFailure = s.toFailure;
    _confirmed =
        s.weightKg != null || s.reps != null || s.durationSeconds != null;
  }

  @override
  void didUpdateWidget(SetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a série ainda não tem valores no banco e o usuário não confirmou,
    // atualiza os controllers quando os hints chegarem (prevAsync atrasado).
    final s = widget.set;
    final hasDbValues =
        s.weightKg != null || s.reps != null || s.durationSeconds != null;
    if (hasDbValues || _confirmed) return;

    if (widget.hintWeight != oldWidget.hintWeight &&
        widget.hintWeight != null &&
        _weightController.text.isEmpty) {
      _weightController.text = widget.hintWeight!.toStringAsFixed(1);
    }
    if (widget.hintReps != oldWidget.hintReps &&
        widget.hintReps != null &&
        _repsController.text.isEmpty) {
      _repsController.text = widget.hintReps!.toString();
    }
    if (widget.hintDuration != oldWidget.hintDuration &&
        widget.hintDuration != null &&
        _durationController.text.isEmpty) {
      _durationController.text = widget.hintDuration!.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);
    final duration = int.tryParse(_durationController.text);

    await widget.onConfirm(weight, reps, duration, _isWarmup, _toFailure);
    if (mounted) setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.set.setType;
    final cs = Theme.of(context).colorScheme;

    final isPR = widget.set.setType == SetType.weight && _isPR;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: _confirmed
          ? BoxDecoration(
              color: isPR
                  ? Colors.amber.withOpacity(0.12)
                  : cs.primaryContainer.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${widget.index}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPR
                    ? Colors.amber
                    : _isWarmup
                        ? cs.tertiary
                        : cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Input fields
          if (type == SetType.weight) ...[
            Expanded(
              child: _NumberField(
                  controller: _weightController,
                  hint: 'kg',
                  decimal: true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('×', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _NumberField(
                  controller: _repsController, hint: 'reps'),
            ),
          ] else if (type == SetType.time) ...[
            Expanded(
              child: _NumberField(
                  controller: _durationController, hint: 'seg'),
            ),
          ] else ...[
            Expanded(
              child: _NumberField(
                  controller: _repsController, hint: 'reps'),
            ),
          ],

          const SizedBox(width: 2),

          // Warmup
          _IconToggle(
            icon: Icons.whatshot,
            active: _isWarmup,
            activeColor: cs.tertiary,
            tooltip: 'Aquecimento',
            onTap: () => setState(() => _isWarmup = !_isWarmup),
          ),

          // To failure (not for time sets)
          if (type != SetType.time)
            _IconToggle(
              icon: Icons.bolt,
              active: _toFailure,
              activeColor: cs.error,
              tooltip: 'Até a falha',
              onTap: () => setState(() => _toFailure = !_toFailure),
            ),

          // Confirm
          _IconToggle(
            icon: isPR
                ? Icons.emoji_events
                : _confirmed
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
            active: _confirmed,
            activeColor: isPR ? Colors.amber : cs.primary,
            tooltip: isPR ? 'Personal Record!' : 'Confirmar série',
            onTap: _confirm,
          ),

          // Delete
          IconButton(
            icon: Icon(Icons.close, size: 18, color: cs.outline),
            tooltip: 'Remover',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _IconToggle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: active ? activeColor : Theme.of(context).colorScheme.outline,
      ),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onTap,
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;

  const _NumberField({
    required this.controller,
    required this.hint,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal, signed: false),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
