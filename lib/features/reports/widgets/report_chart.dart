import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportLineChart extends StatelessWidget {
  final List<({DateTime date, double value})> points;
  final String yLabel;
  final Color? color;

  const ReportLineChart({
    super.key,
    required this.points,
    required this.yLabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'Dados insuficientes.\nComplete mais sessões para ver o gráfico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13),
            ),
          ],
        ),
      );
    }

    final chartColor =
        color ?? Theme.of(context).colorScheme.primary;
    final values = points.map((p) => p.value).toList();
    final minY =
        (values.reduce((a, b) => a < b ? a : b) * 0.9).floorToDouble();
    final maxY =
        (values.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final labelInterval =
        (points.length / 4).ceil().clamp(1, 999).toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: chartColor,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.08),
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
              reservedSize: 52,
              getTitlesWidget: (value, _) => Text(
                '${value.toStringAsFixed(value >= 1000 ? 0 : 1)}$yLabel',
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
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM').format(points[i].date),
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
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
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
                      '${s.y.toStringAsFixed(s.y >= 1000 ? 0 : 1)}$yLabel\n'
                      '${DateFormat('dd/MM/yy').format(points[s.x.toInt()].date)}',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
