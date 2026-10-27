import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/format.dart';

class CompactCalendar extends StatelessWidget {
  const CompactCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.onMonth,
    required this.hasEvents,
  });
  final DateTime month, selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onMonth;
  final bool Function(DateTime) hasEvents;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month).weekday - 1;
    final length = DateTime(month.year, month.month + 1, 0).day;
    final rows = (first + length + 6) ~/ 7;
    final today = dayKey(DateTime.now());
    final cellHeight = math.max(
      34.0,
      MediaQuery.textScalerOf(context).scale(12) * 1.5 + 10,
    );
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 달',
              onPressed: () => onMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${month.year}년 ${month.month}월',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: '다음 달',
              onPressed: () => onMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final day in koreanWeekdays)
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final number = row * 7 + col - first + 1;
                      if (number < 1 || number > length) {
                        return SizedBox(height: cellHeight);
                      }
                      final date = DateTime(month.year, month.month, number);
                      final active = dayKey(date) == dayKey(selected);
                      final event = hasEvents(date);
                      return Semantics(
                        label:
                            '${month.month}월 $number일${event ? ', 일정 있음' : ''}',
                        selected: active,
                        child: InkWell(
                          key: ValueKey('day-${dayKey(date)}'),
                          onTap: () => onSelect(date),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: cellHeight,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: active ? colors.primaryContainer : null,
                              borderRadius: BorderRadius.circular(8),
                              border: dayKey(date) == today
                                  ? Border.all(color: colors.primary)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: active
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: event
                                        ? colors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
