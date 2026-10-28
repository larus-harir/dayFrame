import 'package:flutter/material.dart';
import '../core/bible/reference.dart';
import '../core/store.dart';

class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({super.key, required this.store});
  final PlannerStore store;

  @override
  Widget build(BuildContext context) {
    final verse = store.selectedVerse;
    final completed = store.isBibleReadToday(verse);
    final collapsed = store.display.bibleCollapsed;
    if (collapsed) {
      final passage = store.bibleContent.passageFor(verse);
      final reference =
          passage?.compactReference ??
          '${bibleBookNames[verse.book]} ${verse.chapter}:${verse.verse}';
      final dailyCompleted = store.hasReadBibleToday;
      return Align(
        key: const Key('verse-compact'),
        alignment: Alignment.centerRight,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Tooltip(
            message: '본문 펼치기',
            child: Semantics(
              label:
                  '${store.bibleContent.referenceFor(verse)}, ${dailyCompleted ? '오늘 읽기 완료' : '오늘 읽기 전'}',
              child: TextButton(
                key: const Key('verse-collapse'),
                onPressed: () =>
                    store.updateDisplay((p) => p.bibleCollapsed = false),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: .55),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(reference)),
                    const SizedBox(width: 8),
                    Icon(
                      dailyCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    var distance = 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: GestureDetector(
          key: const Key('verse-swipe'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => distance = 0,
          onHorizontalDragUpdate: (details) => distance += details.delta.dx,
          onHorizontalDragEnd: (details) {
            final speed = details.primaryVelocity ?? 0;
            if (distance.abs() > 48 || speed.abs() > 100) {
              store.moveBibleVerse(
                (distance.abs() > 48 ? distance : speed) < 0 ? 1 : -1,
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: '이전 절',
                    onPressed: verse.index == 0
                        ? null
                        : () => store.moveBibleVerse(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      store.bibleContent.referenceFor(verse),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('verse-collapse'),
                    tooltip: '본문 접기',
                    onPressed: () =>
                        store.updateDisplay((p) => p.bibleCollapsed = true),
                    icon: const Icon(Icons.unfold_less, size: 20),
                  ),
                  IconButton(
                    tooltip: '다음 절',
                    onPressed: verse.index == totalBibleVerses - 1
                        ? null
                        : () => store.moveBibleVerse(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (store.bibleContent.verses[verse.key] case final String text)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!completed && store.hasReadBibleToday)
                Text('오늘 읽기 완료', style: Theme.of(context).textTheme.labelSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    key: const Key('verse-read'),
                    style: TextButton.styleFrom(
                      disabledForegroundColor: Theme.of(
                        context,
                      ).colorScheme.primary,
                    ),
                    onPressed: completed ? null : store.toggleBibleRead,
                    icon: Icon(
                      completed ? Icons.check_circle_outline : Icons.check,
                      size: 18,
                    ),
                    label: Text(completed ? '오늘 읽기 완료' : '읽음'),
                  ),
                  if (completed)
                    IconButton(
                      tooltip: '읽음 취소',
                      onPressed: store.toggleBibleRead,
                      icon: const Icon(Icons.undo, size: 18),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
