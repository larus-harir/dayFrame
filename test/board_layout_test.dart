import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/format.dart';
import 'package:dayframe/core/models.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/widgets/planner_board.dart';
import 'package:dayframe/screens/settings_screen.dart';
import 'test_support.dart';

void main() {
  testWidgets('board follows the verse, checklist, calendar, memo, close order', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PlannerStore(memoryPreferences());
    var closed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlannerBoard(store: store, onClose: () => closed = true))));
    final keys = ['board-bible', 'board-tasks', 'board-calendar', 'board-memo', 'board-close'];
    final positions = keys.map((key) => tester.getTopLeft(find.byKey(Key(key))).dy).toList();
    expect(positions, orderedEquals([...positions]..sort()));
    await tester.tap(find.byKey(const Key('board-close')));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
    store.dispose();
  });

  testWidgets('selected calendar events appear above notes, including unpinned notes', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PlannerStore(memoryPreferences());
    final now = DateTime.now();
    final next = now.day == 1 ? DateTime(now.year, now.month, 2) : DateTime(now.year, now.month, 1);
    store.events.add(PlannerEvent(id: 'event', title: '선택한 일정', date: dayKey(next), hour: 9, minute: 0));
    store.notes.add(PlannerNote(id: 'note', text: '새 메모', createdAt: now.toIso8601String()));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlannerBoard(store: store, onClose: () {}))));
    expect(find.textContaining('선택한 일정'), findsNothing);
    await tester.tap(find.byKey(ValueKey('day-${dayKey(next)}')));
    await tester.pumpAndSettle();
    final event = find.byKey(const ValueKey('memo-event-event'));
    final note = find.byKey(const ValueKey('memo-note-note'));
    expect(event, findsOneWidget);
    expect(tester.getTopLeft(event).dy, lessThan(tester.getTopLeft(note).dy));
    expect(find.text('새 메모'), findsOneWidget);
    store.dispose();
  });

  testWidgets('small screen and large text can scroll to close without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PlannerStore(memoryPreferences());
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: Scaffold(body: PlannerBoard(store: store, onClose: () {})))));
    await tester.scrollUntilVisible(find.byKey(const Key('board-close')), 180,
      scrollable: find.descendant(of: find.byKey(const Key('planner-board')), matching: find.byType(Scrollable)).first);
    expect(tester.takeException(), isNull);
    store.dispose();
  });

  testWidgets('settings shows three main controls and hides display options until expanded', (tester) async {
    final store = PlannerStore(memoryPreferences());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsScreen(store: store))));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    expect(find.text('프리뷰 실행'), findsNothing);
    expect(find.text('수동 요약 타일 사용'), findsNothing);
    await tester.tap(find.text('표시 항목')); await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(7));
    store.dispose();
  });

  testWidgets('lock privacy hides tasks, events and notes but retains the calendar', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PlannerStore(memoryPreferences());
    store.tasks.add(TaskItem(id: 'task', title: 'PRIVATE TASK'));
    store.events.add(PlannerEvent(id: 'event', title: 'PRIVATE EVENT', date: dayKey(DateTime.now()), hour: 9, minute: 0));
    store.notes.add(PlannerNote(id: 'note', text: 'PRIVATE NOTE', createdAt: ''));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PlannerBoard(store: store, locked: true, onClose: () {}))));
    expect(find.textContaining('PRIVATE'), findsNothing);
    expect(find.byKey(const Key('board-calendar')), findsOneWidget);
    store.dispose();
  });
}
