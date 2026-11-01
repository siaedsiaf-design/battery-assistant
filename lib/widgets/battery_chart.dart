// ══════════════════════════════════════════════════════════════════════
// BatteryChart — 24-hour drain history line chart using fl_chart
// ══════════════════════════════════════════════════════════════════════

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/battery_log.dart';

class BatteryChart extends StatelessWidget {
  final List<BatteryLog> logs;

  const BatteryChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No data yet.\nKeep the app running to build history.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    // Build FlSpot list — x = hours ago (0 = now), y = level.
    final now    = DateTime.now();
    final spots  = logs.map((l) {
      final hoursAgo = now.difference(l.timestamp).inMinutes / 60.0;
      return FlSpot(24 - hoursAgo, l.level.toDouble());
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 100,
        backgroundColor: Colors.transparent,

        // Grid lines.
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white10,
            strokeWidth: 1,
          ),
        ),

        // Axes.
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              'Hours ago',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (v, _) => Text(
                '${(24 - v).toInt()}h',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              reservedSize: 32,
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        // Tooltip.
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF1A1A2E),
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toInt()}%',
                const TextStyle(
                  color: Color(0xFF39FF14),
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF39FF14),
            barWidth: 2.5,
            isStrokeCapRound: true,

            // Gradient fill under the line.
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF39FF14).withOpacity(0.25),
                  const Color(0xFF39FF14).withOpacity(0.0),
                ],
              ),
            ),

            // Dots at data points.
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF39FF14),
                strokeWidth: 1,
                strokeColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }
}
