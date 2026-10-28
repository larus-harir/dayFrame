import 'package:dayframe/core/bible/reference.dart';
import 'package:dayframe/core/models.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/screens/bible_journal_screen.dart';
import 'package:dayframe/screens/display_layout_screen.dart';
import 'package:dayframe/widgets/planner_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('old and malformed order settings retain each group once', () {
    expect(
      DisplayPreferences.fromJson({}).sectionOrder,
      DisplayPreferences.defaultSectionOrder,
    );
    expect(
      DisplayPreferences.fromJson({
        'sectionOrder': ['goals', 'goals', 'removed', 7, 'bible'],
      }).sectionOrder,
      ['goals', 'bible', 'calendar-memo', 'tasks'],
    );
  });
  testWidgets(
    'history review edits the right verse without moving the reading cursor',
    (tester) async {
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      store.goToBiblePage(bibleVerseIndex(39, 1, 2));
      final cursor = store.biblePage;
      store.bibleReadDates['0:1:1'] = '2026-10-27';
      store.saveBibleNoteAt('0:1:1', '지난 기록');
      await tester.pumpWidget(
        MaterialApp(home: BibleJournalScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('bible-history-0:1:1-2026-10-27')),
      );
      await tester.pumpAndSettle();
      expect(store.biblePage, cursor);
      await tester.tap(find.byKey(const Key('bible-bookmark')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('bible-reader')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(find.byType(TextField), '수정한 기록');
      await tester.ensureVisible(find.text('기록 저장'));
      await tester.tap(find.text('기록 저장'));
      await tester.pumpAndSettle();
      expect(store.bibleNotes['0:1:1'], '수정한 기록');
      expect(store.bibleNotes.containsKey(bibleVerseAt(cursor).key), isFalse);
      await store.flush();
      final other = PlannerStore(prefs);
      await tester.runAsync(other.load);
      expect(other.bibleBookmarks, contains('0:1:1'));
      expect(other.biblePage, cursor);
      expect(other.bibleNotes['0:1:1'], '수정한 기록');
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      other.dispose();
    },
  );
  testWidgets(
    'chapter progress opens a review without changing the reading position',
    (tester) async {
      final store = PlannerStore(memoryPreferences());
      store.goToBiblePage(99);
      store.bibleReadDates.addAll({
        '0:1:1': '2026-10-27',
        '0:1:2': '2026-10-27',
      });
      await tester.pumpWidget(
        MaterialApp(home: BibleJournalScreen(store: store)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('진행도'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('progress-book-0')));
      await tester.pumpAndSettle();
      expect(find.text('1장 · 2/31'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('progress-0-1')));
      await tester.pumpAndSettle();
      expect(find.text('창세기 1장 1절'), findsOneWidget);
      expect(store.biblePage, 99);
      expect(find.text('지난 구절 돌아보기'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await store.flush();
      store.dispose();
    },
  );
  testWidgets(
    'the board applies reordered groups while keeping calendar and memo adjacent',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PlannerStore(memoryPreferences());
      store.display.sectionOrder = ['tasks', 'goals', 'calendar-memo', 'bible'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlannerBoard(store: store, onClose: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tasks = tester.getRect(find.byKey(const Key('board-tasks')));
      final goals = tester.getRect(find.byKey(const Key('board-goals')));
      final calendar = tester.getRect(find.byKey(const Key('board-calendar')));
      final memo = tester.getRect(find.byKey(const Key('board-memo')));
      final bible = tester.getRect(find.byKey(const Key('board-bible')));
      expect(tasks.bottom, lessThanOrEqualTo(goals.top));
      expect(goals.bottom, lessThanOrEqualTo(calendar.top));
      expect(calendar.bottom, lessThanOrEqualTo(memo.top));
      expect(memo.bottom, lessThanOrEqualTo(bible.top));
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
  testWidgets('dragging a section changes and saves the shared order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = memoryPreferences();
    final store = PlannerStore(prefs);
    await tester.pumpWidget(
      MaterialApp(home: DisplayLayoutScreen(store: store)),
    );
    await tester.pumpAndSettle();
    final handle = find.byType(ReorderableDragStartListener).last;
    final first = tester.getTopLeft(find.byKey(const ValueKey('order-bible')));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(Offset(tester.getCenter(handle).dx, first.dy - 60));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(store.display.sectionOrder, [
      'goals',
      'bible',
      'calendar-memo',
      'tasks',
    ]);
    await store.flush();
    final loaded = PlannerStore(prefs);
    await tester.runAsync(loaded.load);
    expect(loaded.display.sectionOrder, store.display.sectionOrder);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    loaded.dispose();
  });
}
