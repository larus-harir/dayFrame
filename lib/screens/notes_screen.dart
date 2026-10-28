import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/store.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final notes = store.sortedNotes;
    final todayPinned = store
        .eventsOn(DateTime.now())
        .where((e) => e.pinned)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '메모',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => editNoteDialog(context, store),
              icon: const Icon(Icons.add),
              tooltip: '메모 추가',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '오늘의 고정 일정과 메모를 한곳에서 확인하세요.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 26),
        if (todayPinned.isNotEmpty) ...[
          SectionHeading('오늘 일정 · 상단 고정'),
          for (final event in todayPinned)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Panel(
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.clock} ${event.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (event.memo.isNotEmpty)
                            Text(
                              event.memo,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => store.toggleEventPin(event),
                      icon: const Icon(Icons.close),
                      tooltip: '고정 해제',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],
        SectionHeading(
          '전체 메모',
          subtitle: '${notes.length}개',
          onAdd: () => editNoteDialog(context, store),
        ),
        if (notes.isEmpty)
          const EmptyHint('아직 작성된 메모가 없어요.', icon: Icons.note_add_outlined),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => editNoteDialog(context, store, note: note),
              borderRadius: BorderRadius.circular(19),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.pinned) ...[
                          Icon(
                            Icons.push_pin_rounded,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: Text(note.text)),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value == 'edit' && context.mounted) {
                              await editNoteDialog(context, store, note: note);
                            }
                            if (value == 'pin') {
                              store.toggleNotePin(note);
                            }
                            if (value == 'delete' &&
                                context.mounted &&
                                await confirmDelete(context, '이 메모')) {
                              store.deleteNote(note);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(note.pinned ? '고정 해제' : '상단에 고정'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      dayKey(parseDate(note.createdAt)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
