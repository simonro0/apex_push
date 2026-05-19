import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart for a calendar month.
///
/// Always renders exactly 31 slots (x = 0..30) so the bar positions and
/// axis labels are identical across months.  The caller is responsible for
/// filling slots beyond the actual month length with invisible bars.
class MonthlyComboChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final double                  maxY;
  final void Function(int x)    onBarTap;

  const MonthlyComboChart({
    super.key,
    required this.barGroups,
    required this.maxY,
    required this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return BarChart(
      BarChartData(
        barGroups:  barGroups,
        maxY:       maxY,
        minY:       0,
        gridData:   const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        alignment:  BarChartAlignment.center,
        groupsSpace: 0,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                final label = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : value.toInt().toString();
                return Text(
                  label,
                  style: TextStyle(fontSize: 10, color: hintColor),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 22,
              interval:     1,
              getTitlesWidget: (value, meta) {
                // Show labels at fixed positions: 5, 10, 15, 20, 25, 30.
                final day = value.toInt() + 1;
                if (day % 5 != 0 || day > 30) return const SizedBox.shrink();
                return Text(
                  '$day',
                  style: TextStyle(fontSize: 10, color: hintColor),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is! FlTapUpEvent) return;
            if (response?.spot == null) return;
            onBarTap(response!.spot!.touchedBarGroup.x);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                rod.toY > 0
                    ? BarTooltipItem(
                        rod.toY.toStringAsFixed(0),
                        TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}
