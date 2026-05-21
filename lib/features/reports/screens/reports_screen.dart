import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/report_repository.dart';
import '../../../core/utils/unit_converter.dart';
import '../../exercise_library/providers/exercise_providers.dart';
import '../../settings/providers/settings_provider.dart';
import '../../workout_templates/providers/workout_providers.dart';
import '../providers/report_providers.dart';
import '../widgets/report_chart.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await ref.read(exportServiceProvider).exportCsv();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relatórios'),
          actions: [
            if (_exporting)
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
                tooltip: 'Exportar CSV',
                onPressed: _export,
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Por Exercício'),
              Tab(text: 'Por Treino'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ExerciseReportTab(),
            _WorkoutReportTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab Exercício ─────────────────────────────────────────────────────────────

class _ExerciseReportTab extends ConsumerWidget {
  const _ExerciseReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final selectedId = ref.watch(reportExerciseIdProvider);
    final selectedPeriod = ref.watch(reportExercisePeriodProvider);
    final progressAsync = ref.watch(exerciseProgressProvider);
    final unit = ref.watch(settingsProvider).unit;
    final unitLabel = UnitConverter.label(unit);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seletor de exercício
        exercisesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
          data: (exercises) => DropdownButtonFormField<int>(
            value: selectedId,
            decoration: const InputDecoration(
              labelText: 'Selecione um exercício',
              border: OutlineInputBorder(),
            ),
            items: exercises
                .where((e) => e.setType.name == 'weight')
                .map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    ))
                .toList(),
            onChanged: (v) =>
                ref.read(reportExerciseIdProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 12),

        // Seletor de período
        _PeriodSelector(
          selected: selectedPeriod,
          onChanged: (p) =>
              ref.read(reportExercisePeriodProvider.notifier).state = p,
        ),
        const SizedBox(height: 20),

        if (selectedId == null)
          const _SelectPrompt('Selecione um exercício acima')
        else
          progressAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (points) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChartCard(
                  title: 'Carga Máxima',
                  chart: ReportLineChart(
                    points: points
                        .map((p) => (
                              date: p.date,
                              value: UnitConverter.toDisplay(
                                  p.maxWeight, unit),
                            ))
                        .toList(),
                    yLabel: unitLabel,
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Volume Total',
                  chart: ReportLineChart(
                    points: points
                        .map((p) => (
                              date: p.date,
                              value:
                                  UnitConverter.toDisplay(p.volume, unit),
                            ))
                        .toList(),
                    yLabel: unitLabel,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Tab Treino ────────────────────────────────────────────────────────────────

class _WorkoutReportTab extends ConsumerWidget {
  const _WorkoutReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider);
    final selectedId = ref.watch(reportTemplateIdProvider);
    final selectedPeriod = ref.watch(reportWorkoutPeriodProvider);
    final progressAsync = ref.watch(workoutProgressProvider);
    final unit = ref.watch(settingsProvider).unit;
    final unitLabel = UnitConverter.label(unit);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seletor de treino
        templatesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
          data: (templates) => DropdownButtonFormField<int>(
            value: selectedId,
            decoration: const InputDecoration(
              labelText: 'Selecione um treino',
              border: OutlineInputBorder(),
            ),
            items: templates
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    ))
                .toList(),
            onChanged: (v) =>
                ref.read(reportTemplateIdProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 12),

        // Seletor de período
        _PeriodSelector(
          selected: selectedPeriod,
          onChanged: (p) =>
              ref.read(reportWorkoutPeriodProvider.notifier).state = p,
        ),
        const SizedBox(height: 20),

        if (selectedId == null)
          const _SelectPrompt('Selecione um treino acima')
        else
          progressAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (points) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChartCard(
                  title: 'Volume por Sessão',
                  chart: ReportLineChart(
                    points: points
                        .map((p) => (
                              date: p.date,
                              value:
                                  UnitConverter.toDisplay(p.volume, unit),
                            ))
                        .toList(),
                    yLabel: unitLabel,
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Séries por Sessão',
                  chart: ReportLineChart(
                    points: points
                        .map((p) => (
                              date: p.date,
                              value: p.totalSets.toDouble(),
                            ))
                        .toList(),
                    yLabel: '',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 16),
                // Tabela de sessões
                _SessionTable(points: points, unit: unit),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Widgets compartilhados ────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReportPeriod>(
      segments: ReportPeriod.values
          .map((p) => ButtonSegment(
                value: p,
                label:
                    Text(p.label, style: const TextStyle(fontSize: 11)),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;

  const _ChartCard({required this.title, required this.chart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: chart),
          ],
        ),
      ),
    );
  }
}

class _SelectPrompt extends StatelessWidget {
  final String message;
  const _SelectPrompt(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}

class _SessionTable extends StatelessWidget {
  final List<WorkoutSessionPoint> points;
  final WeightUnit unit;
  const _SessionTable({required this.points, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox();
    final recent = points.reversed.take(10).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sessões Recentes',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...recent.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(p.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${p.totalSets} séries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${UnitConverter.toDisplay(p.volume, unit).toStringAsFixed(0)} ${UnitConverter.label(unit)} vol.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
