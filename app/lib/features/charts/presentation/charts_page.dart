import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/diagnosis_visuals.dart';
import '../../measurement/application/measurement_providers.dart';
import '../../measurement/domain/entities/measurement.dart';

/// Gráficos interativos das medições: dispersão resistência×profundidade e
/// comparação por barras. Suporta zoom/pan (InteractiveViewer) e toque.
class ChartsPage extends ConsumerWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(measurementsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos')),
      body: items.isEmpty
          ? const Center(child: Text('Sem dados para exibir.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Resistência × Profundidade',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChartCard(child: _ScatterByDepth(items: items)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Comparação de coeficientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChartCard(child: _CoefficientBars(items: items)),
                const SizedBox(height: AppSpacing.md),
                const _Legend(),
              ],
            ),
    );
  }
}

/// Estilos compartilhados dos eixos/grade, derivados do tema atual.
({TextStyle label, Color grid, Color border}) _chartStyles(
  BuildContext context,
) {
  final scheme = Theme.of(context).colorScheme;
  return (
    label: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
    grid: scheme.outlineVariant.withValues(alpha: 0.4),
    border: scheme.outlineVariant,
  );
}

Widget _axisLabel(double value, TitleMeta meta, TextStyle style) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(meta.formattedValue, style: style),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: 280,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ScatterByDepth extends StatelessWidget {
  const _ScatterByDepth({required this.items});
  final List<Measurement> items;

  @override
  Widget build(BuildContext context) {
    final styles = _chartStyles(context);
    final spots = items
        .map(
          (m) => ScatterSpot(
            m.deep,
            m.coefficient,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: diagnosisColor(m.coefficient),
            ),
          ),
        )
        .toList();

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text('kgf/cm²', style: styles.label),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => _axisLabel(v, meta, styles.label),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Profundidade (cm)', style: styles.label),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => _axisLabel(v, meta, styles.label),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: (_) =>
              FlLine(color: styles.grid, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: styles.grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: styles.border),
        ),
      ),
    );
  }
}

class _CoefficientBars extends StatelessWidget {
  const _CoefficientBars({required this.items});
  final List<Measurement> items;

  @override
  Widget build(BuildContext context) {
    final styles = _chartStyles(context);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < items.length; i++) {
      final m = items[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: m.coefficient,
              color: diagnosisColor(m.coefficient),
              width: 14,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: groups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => _axisLabel(v, meta, styles.label),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('#${items[i].id ?? i + 1}', style: styles.label),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: (_) =>
              FlLine(color: styles.grid, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: styles.border),
        ),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const entries = <(String, double)>[
      ('Adequado (<10)', 5),
      ('Moderada (≤20)', 15),
      ('Alta (≤30)', 25),
      ('Compactado (≤40)', 35),
      ('Extremo (>40)', 45),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: diagnosisColor(e.$2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(e.$1, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
