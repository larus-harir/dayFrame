import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/store.dart';
import 'compact_calendar.dart';
import 'verse_card.dart';
import 'paged_board.dart';
import 'editors.dart';

class PlannerBoard extends StatefulWidget {
  const PlannerBoard({
    super.key,
    required this.store,
    required this.onClose,
    this.locked = false,
  });
  final PlannerStore store;
  final VoidCallback onClose;
  final bool locked;
  @override
  State<PlannerBoard> createState() => _PlannerBoardState();
}

class _PlannerBoardState extends State<PlannerBoard> {
  DateTime selected = dateOnly(DateTime.now());
  late DateTime month = DateTime(selected.year, selected.month);
  late DateTime week = DateTime(
    selected.year,
    selected.month,
    selected.day - selected.weekday + 1,
  );
  String? tappedDay;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final hidden = widget.locked && store.display.hidePrivateDetails;
        final today = DateTime.now();
        final tasks = store.tasksOn(today);
        final events = store.eventsOn(selected);
        final notes = store.sortedNotes;
        final daily = tasks;
        Widget calendarAndMemo(bool weekly) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section(
              '캘린더',
              key: const Key('board-calendar'),
              child: CompactCalendar(
                key: Key(weekly ? 'calendar-week' : 'calendar-month'),
                weekly: weekly,
                weekStart: week,
                month: month,
                selected: selected,
                hasEvents: (date) =>
                    store.display.events && store.eventsOn(date).isNotEmpty,
                onSelect: (date) {
                  final repeated = tappedDay == dayKey(date);
                  setState(() {
                    selected = date;
                    month = DateTime(date.year, date.month);
                    tappedDay = dayKey(date);
                    week = DateTime(
                      date.year,
                      date.month,
                      date.day - date.weekday + 1,
                    );
                  });
                  if (repeated &&
                      (!widget.locked || store.display.lockCreateEvent)) {
                    tappedDay = null;
                    editEventDialog(context, store, initialDate: date);
                  }
                },
                onMonth: (delta) => setState(() {
                  tappedDay = null;
                  if (weekly) {
                    week = DateTime(
                      week.year,
                      week.month,
                      week.day + delta * 7,
                    );
                    selected = DateTime(
                      week.year,
                      week.month,
                      week.day + selected.weekday - 1,
                    );
                    month = DateTime(selected.year, selected.month);
                  } else {
                    month = DateTime(month.year, month.month + delta);
                  }
                }),
              ),
            ),
            if (store.display.events || store.display.notes)
              _section(
                '${formatDate(selected)} · 메모',
                key: const Key('board-memo'),
                onTap: () => openMemo(context),
                child: hidden
                    ? const Text('일정과 메모를 숨겼습니다.')
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 116),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (store.display.events)
                                for (final event in events)
                                  Padding(
                                    key: ValueKey('memo-event-${event.id}'),
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${event.clock}  ${event.title}${event.memo.isEmpty ? '' : '\n${event.memo}'}',
                                    ),
                                  ),
                              if (store.display.notes)
                                for (final note in notes)
                                  Padding(
                                    key: ValueKey('memo-note-${note.id}'),
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(note.text),
                                  ),
                              if ((!store.display.events || events.isEmpty) &&
                                  (!store.display.notes || notes.isEmpty))
                                const Text('일정과 메모가 없습니다.'),
                            ],
                          ),
                        ),
                      ),
              ),
          ],
        );
        return Padding(
          key: const Key('planner-board'),
          padding: EdgeInsets.zero,
          child: PagedBoard(
            onClose: widget.onClose,
            compactSections: {'calendar-memo': calendarAndMemo(true)},
            sections: {
              if (store.display.bible)
                'bible': VerseCard(key: const Key('board-bible'), store: store),
              if (store.display.tasks)
                'tasks': _section(
                  '체크리스트',
                  key: const Key('board-tasks'),
                  child: hidden
                      ? Text('${tasks.length}개 · 내용 숨김')
                      : daily.isEmpty
                      ? const Text('오늘 할 일이 없습니다.')
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 138),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              for (final task in daily)
                                CheckboxListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  value: task.isDone(DateTime.now()),
                                  onChanged: (_) =>
                                      store.toggleTask(task, DateTime.now()),
                                ),
                            ],
                          ),
                        ),
                ),
              'calendar-memo': calendarAndMemo(false),
              if (store.display.goals && (hidden || store.goals.isEmpty))
                'goals': _section(
                  '장기 플랜',
                  key: const Key('board-goals'),
                  child: Text(hidden ? '장기 플랜을 숨겼습니다.' : '등록된 목표가 없습니다.'),
                ),
              if (store.display.goals && !hidden)
                for (final goal
                    in ([...store.goals]..sort(
                      (a, b) => a.pinned == b.pinned
                          ? 0
                          : a.pinned
                          ? -1
                          : 1,
                    )))
                  'goal-${goal.id}': _section(
                    '장기 플랜',
                    key: ValueKey('board-goal-${goal.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (goal.description.isNotEmpty) Text(goal.description),
                        if (goal.deadline.isNotEmpty)
                          Text('목표일 ${goal.deadline}'),
                        Text('${(goal.progress * 100).round()}%'),
                        LinearProgressIndicator(value: goal.progress),
                        for (var step = 0; step < goal.steps.length; step++)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(goal.steps[step]),
                            value: goal.finishedSteps[step],
                            onChanged: (_) => store.toggleStep(goal, step),
                          ),
                      ],
                    ),
                  ),
            },
          ),
        );
      },
    );
  }

  Future<void> openMemo(BuildContext context) async {
    final store = widget.store;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AnimatedBuilder(
        animation: store,
        builder: (ctx, _) {
          final hidden = widget.locked && store.display.hidePrivateDetails;
          final canNote = !widget.locked || store.display.lockCreateNote;
          final canEvent = !widget.locked || store.display.lockCreateEvent;
          return AlertDialog(
            title: const Text('메모'),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (hidden)
                      const Text('잠금화면에서 내용을 숨겼습니다.')
                    else ...[
                      if (store.display.events)
                        for (final event in store.eventsOn(selected))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${event.clock} ${event.title}'),
                            trailing: canEvent
                                ? TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, 'event:${event.id}'),
                                    child: const Text('수정'),
                                  )
                                : null,
                          ),
                      if (store.display.notes)
                        for (final note in store.sortedNotes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(note.text),
                            trailing: canNote
                                ? TextButton(
                                    key: ValueKey('edit-note-${note.id}'),
                                    onPressed: () =>
                                        Navigator.pop(ctx, 'note:${note.id}'),
                                    child: const Text('수정'),
                                  )
                                : null,
                          ),
                      if (store.notes.isEmpty &&
                          store.eventsOn(selected).isEmpty)
                        const Text('등록된 내용이 없습니다.'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
              if (canNote)
                FilledButton(
                  key: const Key('memo-create'),
                  onPressed: () => Navigator.pop(ctx, 'create'),
                  child: const Text('등록'),
                ),
            ],
          );
        },
      ),
    );
    if (!context.mounted || result == null) return;
    if (result == 'create') {
      if (!widget.locked || store.display.lockCreateNote) {
        await editNoteDialog(context, store);
      }
      return;
    }
    if (widget.locked && store.display.hidePrivateDetails) return;
    if (result.startsWith('note:') &&
        (!widget.locked || store.display.lockCreateNote)) {
      for (final note in store.notes) {
        if (note.id == result.substring(5)) {
          await editNoteDialog(context, store, note: note);
          break;
        }
      }
    }
    if (result.startsWith('event:') &&
        (!widget.locked || store.display.lockCreateEvent)) {
      for (final event in store.events) {
        if (event.id == result.substring(6)) {
          await editEventDialog(context, store, event: event);
          break;
        }
      }
    }
  }

  Widget _section(
    String title, {
    required Key key,
    required Widget child,
    VoidCallback? onTap,
  }) => Card(
    key: key,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    ),
  );
}
