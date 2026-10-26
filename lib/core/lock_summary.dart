import 'bible_data.dart';
import 'format.dart';
import 'store.dart';

/// One privacy policy for both the preview and the Android lock surface.
Map<String, String> lockSummary(PlannerStore store, DateTime date) {
  final p = store.display;
  final hidden = p.hidePrivateDetails;
  final due = store.eventsOn(date);
  final tasks = store.tasksOn(date);
  final goals = store.pinnedGoals;
  final notes = store.sortedNotes.where((n) => n.pinned).toList();
  return {
    if (p.events) '오늘 일정': hidden ? '${due.length}개 · 내용 숨김' : due.isEmpty ? '일정 없음' : due.take(2).map((e) => '${e.clock} ${e.title}').join('\n'),
    if (p.tasks) '체크리스트': hidden ? '${tasks.where((t) => t.isDone(date)).length}/${tasks.length} 완료 · 내용 숨김' : tasks.isEmpty ? '항목 없음' : tasks.take(3).map((t) => '${t.isDone(date) ? '✓' : '□'} ${t.title}').join('\n'),
    if (p.bible) '성경 읽기': store.totalReadCount == totalBibleVerses ? '일독 완료' : '${bibleVerseAt(store.nextUnreadPage).reference} · 오늘 ${store.todayReadCount}절',
    if (p.goals) '장기 목표': hidden ? '${goals.length}개 · 내용 숨김' : goals.isEmpty ? '고정 목표 없음' : goals.take(2).map((g) => '${g.title} ${(g.progress * 100).round()}%').join('\n'),
    if (p.notes) '고정 메모': hidden ? '${notes.length}개 · 내용 숨김' : notes.isEmpty ? '고정 메모 없음' : notes.take(1).map((n) => n.text).join(),
  }.map((key, value) => MapEntry(key, value.length > 240 ? '${value.substring(0, 240)}…' : value));
}

String nativeSummary(PlannerStore store, DateTime date) =>
    '${dayKey(date)}\n${lockSummary(store, date).entries.map((e) => '${e.key}\n${e.value}').join('\n\n')}';
