import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/study_log.dart';

class StatsScreen extends StatelessWidget {
  final List<StudyLog> logs;
  const StatsScreen({super.key, required this.logs});

  Map<String, double> _monthlyHours() {
    final result = <String, double>{};
    for (final log in logs) {
      final key = DateFormat('MMM').format(log.loggedDate);
      result[key] = (result[key] ?? 0) + log.hours;
    }
    return result;
  }

  Map<String, double> _weeklyHours() {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('EEE').format(day);
      result[key] = 0;
    }
    for (final log in logs) {
      final diff = now.difference(log.loggedDate).inDays;
      if (diff <= 6) {
        final key = DateFormat('EEE').format(log.loggedDate);
        result[key] = (result[key] ?? 0) + log.hours;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weekly = _weeklyHours();
    final monthly = _monthlyHours();
    final totalHours = logs.fold(0.0, (s, l) => s + l.hours);
    final avgHours = logs.isEmpty ? 0.0 : totalHours / logs.length;
    final bestDay = logs.isEmpty
        ? 0.0
        : logs.map((l) => l.hours).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats 📊'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                _statCard('Avg/Day', '${avgHours.toStringAsFixed(1)}h'),
                const SizedBox(width: 12),
                _statCard('Best Day', '${bestDay.toStringAsFixed(1)}h'),
                const SizedBox(width: 12),
                _statCard('Total', '${totalHours.toStringAsFixed(1)}h'),
              ],
            ),
            const SizedBox(height: 28),

            // Weekly chart
            const Text('This Week',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: weekly.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: const Color(0xFF39D97E),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  ))
                      .toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final days = weekly.keys.toList();
                          if (val.toInt() < days.length) {
                            return Text(days[val.toInt()],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Monthly chart
            const Text('Monthly Breakdown',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: monthly.isEmpty
                  ? const Center(
                  child: Text('No data yet',
                      style: TextStyle(color: Colors.white38)))
                  : BarChart(
                BarChartData(
                  barGroups: monthly.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: const Color(0xFF26A865),
                        width: 20,
                        borderRadius:
                        BorderRadius.circular(4),
                      )
                    ],
                  ))
                      .toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final months = monthly.keys.toList();
                          if (val.toInt() < months.length) {
                            return Text(months[val.toInt()],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                        sideTitles:
                        SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles:
                        SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles:
                        SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF39D97E))),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}