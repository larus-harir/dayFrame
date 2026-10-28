import 'package:flutter/material.dart';
import '../core/bible_data.dart';
import '../core/store.dart';

class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final verse = store.selectedVerse;
    void move(int delta) => store.moveBibleVerse(delta);
    var distance = 0.0;
    return Card(
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
                  child: GestureDetector(
                    key: const Key('verse-swipe'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) => distance = 0,
                    onHorizontalDragUpdate: (details) =>
                        distance += details.delta.dx,
                    onHorizontalDragEnd: (details) {
                      final speed = details.primaryVelocity ?? 0;
                      if (distance.abs() > 48 || speed.abs() > 100) {
                        move(
                          (distance.abs() > 48 ? distance : speed) < 0 ? 1 : -1,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            store.bibleContent.referenceFor(verse),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (store.bibleContent.verses[verse.key]
                              case final String text)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                text,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Text(
                            '오늘 ${store.todayReadCount}절',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
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
              label: Text(
                store.bibleContent.missing.contains(verse.key)
                    ? '본문 없음 · 다음 절'
                    : store.isBibleRead(verse)
                    ? '읽음 취소'
                    : '읽음 · 다음 절',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
