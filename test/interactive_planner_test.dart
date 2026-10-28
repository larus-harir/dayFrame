import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/core/models.dart';
import 'package:dayframe/widgets/verse_card.dart';
import 'package:dayframe/lock_overlay.dart';
import 'package:dayframe/screens/today_screen.dart';
import 'test_support.dart';

void main() {
  Future<void> showTasks(WidgetTester tester) async {
    for (
      var i = 0;
      i < 5 && find.byType(CheckboxListTile).evaluate().isEmpty;
      i++
    ) {
      await tester.tap(find.byTooltip('다음 페이지'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('home checklist toggles directly and persists', (tester) async {
    final prefs = memoryPreferences();
    final store = PlannerStore(prefs);
    store.tasks.add(TaskItem(id: 'home', title: '메인 체크'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: store,
            builder: (_, _) => TodayScreen(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await showTasks(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(store.tasks.single.isDone(DateTime.now()), isTrue);
    await store.flush();
    final reloaded = PlannerStore(prefs);
    await tester.runAsync(reloaded.load);
    expect(reloaded.tasks.single.isDone(DateTime.now()), isTrue);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    reloaded.dispose();
  });
  testWidgets(
    'verse card supports swipe, previous, read, undo and persistence',
    (tester) async {
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: store,
              builder: (_, _) => VerseCard(store: store),
            ),
          ),
        ),
      );
      await tester.fling(
        find.byKey(const Key('verse-swipe')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(store.selectedVerse.verse, 2);
      await tester.tap(find.byTooltip('이전 절'));
      await tester.pumpAndSettle();
      expect(store.selectedVerse.verse, 1);
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(store.totalReadCount, 1);
      expect(store.selectedVerse.verse, 2);
      await tester.tap(find.byTooltip('이전 절'));
      await tester.pumpAndSettle();
      expect(find.text('읽음 취소'), findsOneWidget);
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(store.totalReadCount, 0);
      await store.flush();
      final reloaded = PlannerStore(prefs);
      await tester.runAsync(reloaded.load);
      expect(reloaded.totalReadCount, 0);
      expect(reloaded.biblePage, 0);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      reloaded.dispose();
    },
  );
  testWidgets(
    'actual overlay checks tasks and marks verses in shared storage',
    (tester) async {
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      store.display.hidePrivateDetails = false;
      store.tasks.add(TaskItem(id: 'task', title: '운동하기'));
      await tester.pumpWidget(LockOverlayApp(store: store));
      await tester.pumpAndSettle();
      await showTasks(tester);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(store.tasks.single.isDone(DateTime.now()), isTrue);
      while (tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (w) => w is IconButton && w.tooltip == '이전 페이지',
                ),
              )
              .onPressed !=
          null) {
        await tester.tap(find.byTooltip('이전 페이지'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(store.totalReadCount, 1);
      await store.flush();
      final reloaded = PlannerStore(prefs);
      await tester.runAsync(reloaded.load);
      expect(reloaded.tasks.single.isDone(DateTime.now()), isTrue);
      expect(reloaded.totalReadCount, 1);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      reloaded.dispose();
    },
  );
  testWidgets('overlay respects hidden private task details', (tester) async {
    final store = PlannerStore(memoryPreferences());
    store.tasks.add(TaskItem(id: 'task', title: 'PRIVATE TASK'));
    await tester.pumpWidget(LockOverlayApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('PRIVATE TASK'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
