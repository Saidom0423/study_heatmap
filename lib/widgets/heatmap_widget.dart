import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/study_log.dart';

class HeatmapWidget extends StatelessWidget {
  final List<StudyLog> logs;

  const HeatmapWidget({
    super.key,
    required this.logs,
  });

  Color _colorForHours(double? hours) {
    if (hours == null || hours == 0) return AppTheme.heat0;
    if (hours < 1) return AppTheme.heat1;
    if (hours < 3) return AppTheme.heat2;
    if (hours < 5) return AppTheme.heat3;
    return AppTheme.heat4;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> hoursMap = {};

    for (final log in logs) {
      final key = DateFormat('yyyy-MM-dd').format(log.loggedDate);

      hoursMap[key] =
          (hoursMap[key] ?? 0) + log.hours;
    }

    final today = DateTime.now();

    final List<List<DateTime?>> weeks = [];

    DateTime start =
    today.subtract(const Duration(days: 364));

    while (start.weekday != DateTime.sunday) {
      start = start.subtract(const Duration(days: 1));
    }

    DateTime cursor = start;

    while (cursor.isBefore(today) || cursor == today) {
      final week = <DateTime?>[];

      for (int i = 0; i < 7; i++) {
        if (cursor.isAfter(today)) {
          week.add(null);
        } else {
          week.add(cursor);
        }

        cursor = cursor.add(
          const Duration(days: 1),
        );
      }

      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 24),
              ...weeks.map((week) {
                final firstDay =
                week.firstWhere((d) => d != null);

                if (firstDay != null &&
                    firstDay.day <= 7) {
                  return SizedBox(
                    width: 14,
                    child: Text(
                      DateFormat('MMM')
                          .format(firstDay)[0],
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white38,
                      ),
                    ),
                  );
                }

                return const SizedBox(width: 14);
              }),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                'S',
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
              ]
                  .map(
                    (d) => SizedBox(
                  height: 14,
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white38,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),

            const SizedBox(width: 4),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection:
                Axis.horizontal,
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: weeks.map((week) {
                    return Column(
                      children:
                      week.map((day) {
                        if (day == null) {
                          return const SizedBox(
                            height: 14,
                            width: 12,
                          );
                        }

                        final key =
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(day);

                        final hours =
                        hoursMap[key];

                        return Tooltip(
                          message:
                          hours != null
                              ? '${DateFormat('MMM d').format(day)}: ${hours.toStringAsFixed(1)}h'
                              : DateFormat(
                            'MMM d',
                          ).format(day),
                          child: Container(
                            margin:
                            const EdgeInsets.all(
                              1,
                            ),
                            width: 12,
                            height: 12,
                            decoration:
                            BoxDecoration(
                              color:
                              _colorForHours(
                                hours,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Text(
              'Less',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
              ),
            ),

            const SizedBox(width: 4),

            ...[
              AppTheme.heat0,
              AppTheme.heat1,
              AppTheme.heat2,
              AppTheme.heat3,
              AppTheme.heat4,
            ].map(
                  (c) => Container(
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius:
                  BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(width: 4),

            const Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ],
    );
  }
}