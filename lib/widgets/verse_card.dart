import 'package:flutter/material.dart';
import '../core/bible_data.dart';
import '../core/store.dart';

class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final verse = store.selectedVerse;
    void move(int delta) => store.goToBiblePage(verse.index + delta);
    var distance = 0.0;
    return GestureDetector(
      key: const Key('verse-swipe'),
      onHorizontalDragStart: (_) => distance = 0,
      onHorizontalDragUpdate: (details) => distance += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final speed = details.primaryVelocity ?? 0;
        if (distance.abs() > 48 || speed.abs() > 100) {
          move((distance.abs() > 48 ? distance : speed) < 0 ? 1 : -1);
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: '이전 절',
                    onPressed: verse.index == 0 ? null : () => move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          verse.reference,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '오늘 ${store.todayReadCount}절',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '다음 절',
                    onPressed: verse.index == totalBibleVerses - 1
                        ? null
                        : () => move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              TextButton.icon(
                key: const Key('verse-read'),
                onPressed: store.toggleBibleRead,
                icon: Icon(
                  store.isBibleRead(verse) ? Icons.undo : Icons.check,
                  size: 18,
                ),
                label: Text(store.isBibleRead(verse) ? '읽음 취소' : '읽음 · 다음 절'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
