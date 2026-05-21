import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentBodyWeightEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Logo banner ──────────────────────────────────────────────
          _LogoBanner(),
          const SizedBox(height: 8),

          // ── Peso atual ──────────────────────────────────────────────
          recentAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (entries) => _CurrentWeightCard(
              latestEntry: entries.isEmpty ? null : entries.first,
            ),
          ),
          const SizedBox(height: 16),

          // ── Gráfico ─────────────────────────────────────────────────
          const _WeightChartSection(),
          const SizedBox(height: 16),

          // ── Histórico ───────────────────────────────────────────────
          Text('Histórico',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          recentAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (entries) => entries.isEmpty
                ? const _EmptyHistory()
                : Column(
                    children: entries
                        .map((e) => _HistoryItem(entry: e))
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Peso'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final saved = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Ex: 83.5',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '.'));
            if (parsed != null) Navigator.pop(context, parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                  controller.text.replaceAll(',', '.'));
              if (parsed != null) Navigator.pop(context, parsed);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved != null) {
      await ref.read(bodyWeightRepositoryProvider).addEntry(saved);
    }
  }
}

// ── Cartão peso atual ────────────────────────────────────────────────────────

class _CurrentWeightCard extends StatelessWidget {
  final BodyWeightEntry? latestEntry;

  const _CurrentWeightCard({required this.latestEntry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peso atual',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  latestEntry != null
                      ? '${latestEntry!.weightKg.toStringAsFixed(1)} kg'
                      : '— kg',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (latestEntry != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(latestEntry!.recordedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seção do gráfico ─────────────────────────────────────────────────────────

class _WeightChartSection extends ConsumerWidget {
  const _WeightChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedWeightPeriodProvider);
    final entriesAsync = ref.watch(bodyWeightChartEntriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progressão',
                style: Theme.of(context).textTheme.titleMedium),
            SegmentedButton<WeightPeriod>(
              segments: WeightPeriod.values
                  .map((p) => ButtonSegment(
                        value: p,
                        label: Text(p.label,
                            style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
              selected: {selectedPeriod},
              onSelectionChanged: (s) => ref
                  .read(selectedWeightPeriodProvider.notifier)
                  .state = s.first,
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: entriesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (entries) => entries.length < 2
                ? const _EmptyChart()
                : _WeightLineChart(entries: entries),
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            'Registre ao menos 2 pesos para ver o gráfico',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<BodyWeightEntry> entries;

  const _WeightLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();

    final weights = entries.map((e) => e.weightKg).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2)
        .floorToDouble();
    final maxY = (weights.reduce((a, b) => a > b ? a : b) + 2)
        .ceilToDouble();

    final labelInterval =
        (entries.length / 4).ceil().toDouble().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                '${value.toStringAsFixed(1)}kg',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: labelInterval,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM').format(entries[i].recordedAt),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).colorScheme.surfaceContainerHighest,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${entries[s.x.toInt()].weightKg.toStringAsFixed(1)} kg\n'
                      '${DateFormat('dd/MM/yy').format(entries[s.x.toInt()].recordedAt)}',
                      TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Histórico ────────────────────────────────────────────────────────────────

class _HistoryItem extends ConsumerWidget {
  final BodyWeightEntry entry;

  const _HistoryItem({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.monitor_weight_outlined),
      title: Text(
        '${entry.weightKg.toStringAsFixed(1)} kg',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(entry.recordedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir registro?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref
                    .read(bodyWeightRepositoryProvider)
                    .deleteEntry(entry.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final weightController =
        TextEditingController(text: entry.weightKg.toStringAsFixed(1));
    DateTime selectedDate = entry.recordedAt;

    final saved = await showDialog<({double weight, DateTime date})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Registro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                    weightController.text.replaceAll(',', '.'));
                if (parsed != null) {
                  Navigator.pop(context, (weight: parsed, date: selectedDate));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != null) {
      await ref
          .read(bodyWeightRepositoryProvider)
          .updateEntry(entry.id, saved.weight, saved.date);
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Nenhum registro ainda.\nToque em "Registrar Peso" para começar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}

// ── Logo Banner ───────────────────────────────────────────────────────────────

class _LogoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0d0d1f),
            const Color(0xFF1a1040),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logo_icon.svg',
            width: 72,
            height: 72,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERLOAD',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registre. Evolua. Supere.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
