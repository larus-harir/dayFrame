import 'package:flutter/material.dart';
import '../core/bible_data.dart';
import '../core/store.dart';

/// Same controls on the home screen and the actual overlay.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final verse = store.selectedVerse;
    void move(int delta) => store.goToBiblePage(verse.index + delta);
    var distance=0.0;
    return GestureDetector(
      key: const Key('verse-swipe'),
      onHorizontalDragStart:(_)=>distance=0,
      onHorizontalDragUpdate:(details)=>distance+=details.delta.dx,
      onHorizontalDragEnd: (details) {
        final speed = details.primaryVelocity ?? 0;
        if (distance.abs()>48 || speed.abs()>100) move((distance.abs()>48?distance:speed)<0?1:-1);
      },
      child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Text(verse.reference, style: Theme.of(context).textTheme.titleLarge),
        const Text('성경에서 해당 절을 읽어주세요 · 본문 미포함'),
        Row(children: [
          IconButton(tooltip: '이전 절', onPressed: verse.index == 0 ? null : () => move(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(child: Text('오늘 ${store.todayReadCount}절 · ${store.totalReadCount}/$totalBibleVerses절', textAlign: TextAlign.center)),
          IconButton(tooltip: '다음 절', onPressed: verse.index == totalBibleVerses-1 ? null : () => move(1), icon: const Icon(Icons.chevron_right)),
        ]),
        FilledButton.icon(
          key: const Key('verse-read'),
          onPressed: store.toggleBibleRead,
          icon: Icon(store.isBibleRead(verse) ? Icons.undo : Icons.check),
          label: Text(store.isBibleRead(verse) ? '읽음 취소' : '읽음 · 다음 절'),
        ),
      ]))),
    );
  }
}
