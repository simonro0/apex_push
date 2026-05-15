import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Overlay chart combining a BarChart (interactive) with a LineChart trend
/// overlay (non-interactive). Both layers share the same Y-axis scale.
class MonthlyComboChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final List<FlSpot>            spots;
  final int                     days;
  final double                  maxY;
  final void Function(int day)  onBarTap;
  final String                  yAxisLabel;

  const MonthlyComboChart({
    super.key,
    required this.barGroups,
    required this.spots,
    required this.days,
    required this.maxY,
    required this.onBarTap,
    required this.yAxisLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(context).colorScheme.secondary;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final sharedTitles = FlTitlesData(
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
            final day = value.toInt() + 1;
            if (day % 5 != 0 || day > days) return const SizedBox.shrink();
            return Text(
              '$day',
              style: TextStyle(fontSize: 10, color: hintColor),
            );
          },
        ),
      ),
    );

    // The LineChart overlay must declare the same reservedSize for leftTitles
    // so that its coordinate space aligns pixel-perfectly with the BarChart.
    final overlayTitles = FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 40)),
      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 22)),
    );

    return Stack(
      children: [
        // ── Bar layer ──────────────────────────────────────────────────────
        BarChart(
          BarChartData(
            barGroups:    barGroups,
            maxY:         maxY,
            minY:         0,
            gridData:     const FlGridData(show: true),
            borderData:   FlBorderData(show: false),
            titlesData:   sharedTitles,
            alignment:    BarChartAlignment.center,
            groupsSpace:  0,
            barTouchData: BarTouchData(
              touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                if (event is! FlTapUpEvent) return;
                if (response?.spot == null) return;
                onBarTap(response!.spot!.touchedBarGroup.x);
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  rod.toY > 0 ? rod.toY.toStringAsFixed(0) : '',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
        // ── Line overlay ───────────────────────────────────────────────────
        if (spots.length >= 2)
          IgnorePointer(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots:     spots,
                    isCurved:  false,
                    color:     lineColor,
                    barWidth:  2,
                    dotData:   FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius:      3,
                        color:       lineColor,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX:        -0.5,
                maxX:        days - 0.5,
                minY:        0,
                maxY:        maxY,
                titlesData:  overlayTitles,
                gridData:    const FlGridData(show: false),
                borderData:  FlBorderData(show: false),
              ),
            ),
          ),
      ],
    );
  }
}
