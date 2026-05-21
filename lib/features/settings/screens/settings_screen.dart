import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/unit_converter.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Unidade de peso ──────────────────────────────────────────
          _SectionTitle('Unidade de Peso'),
          const SizedBox(height: 8),
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(
                value: WeightUnit.kg,
                icon: Icon(Icons.monitor_weight_outlined),
                label: Text('Quilogramas (kg)'),
              ),
              ButtonSegment(
                value: WeightUnit.lbs,
                icon: Icon(Icons.monitor_weight_outlined),
                label: Text('Libras (lbs)'),
              ),
            ],
            selected: {settings.unit},
            onSelectionChanged: (s) => notifier.setUnit(s.first),
          ),
          const SizedBox(height: 4),
          Text(
            settings.unit == WeightUnit.kg
                ? '1 kg = 2.205 lbs'
                : '1 lbs = 0.454 kg',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),

          const SizedBox(height: 32),

          // ── Descanso padrão ──────────────────────────────────────────
          _SectionTitle('Descanso Padrão'),
          const SizedBox(height: 4),
          Text(
            'Valor inicial ao criar um novo exercício',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: settings.defaultRestSeconds.toDouble(),
                  min: 0,
                  max: 300,
                  divisions: 20,
                  label: _formatRest(settings.defaultRestSeconds),
                  onChanged: (v) => notifier.setDefaultRest(v.toInt()),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  _formatRest(settings.defaultRestSeconds),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
