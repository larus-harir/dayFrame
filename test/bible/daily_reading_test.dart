import 'dart:convert';
import 'package:dayframe/core/bible/content.dart';
import 'package:dayframe/core/bible/reference.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/lock_overlay.dart';
import 'package:dayframe/widgets/daily_verse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'read completes today in place; reopening advances without resetting today',
    () async {
      final prefs = memoryPreferences();
      final now = DateTime(2026, 10, 28, 12);
      final store = PlannerStore(prefs, clock: () => now);
      await store.load(startBibleSession: true);
      store.toggleBibleRead();
      expect(store.selectedVerse.key, '0:1:1');
      expect(store.hasReadBibleToday, isTrue);
      expect(store.isBibleReadToday(store.selectedVerse), isTrue);
      await store.flush();
      final reopened = PlannerStore(prefs, clock: () => now);
      await reopened.load(startBibleSession: true);
      expect(reopened.selectedVerse.key, '0:1:2');
      expect(reopened.hasReadBibleToday, isTrue);
      expect(reopened.isBibleReadToday(reopened.selectedVerse), isFalse);
      await reopened.flush();
      store.dispose();
      reopened.dispose();
    },
  );

  test(
    'extra reading, undo, and the day boundary retain independent daily records',
    () async {
      var now = DateTime(2026, 10, 28, 23, 59);
      final store = PlannerStore(memoryPreferences(), clock: () => now);
      await store.load(startBibleSession: true);
      store.toggleBibleRead();
      store.moveBibleVerse(1);
      expect(store.hasReadBibleToday, isTrue);
      store.toggleBibleRead();
      expect(store.todayReadCount, 2);
      store.toggleBibleRead();
      expect(store.todayReadCount, 1);
      store.toggleBibleRead();
      now = DateTime(2026, 10, 29);
      store.refreshBibleDay();
      expect(store.selectedVerse.key, '0:1:3');
      expect(store.hasReadBibleToday, isFalse);
      expect(store.todayReadCount, 0);
      expect(store.totalReadCount, 2);
      store.refreshBibleDay();
      expect(store.selectedVerse.key, '0:1:3');
      store.moveBibleVerse(-1);
      store.toggleBibleRead();
      expect(store.todayReadCount, 1);
      expect(store.totalReadCount, 2);
      store.toggleBibleRead();
      expect(store.totalReadCount, 2);
      expect(store.bibleReadDates['0:1:2'], '2026-10-28');
      expect(store.bibleReadingDays['2026-10-28'], {'0:1:1', '0:1:2'});
      await store.flush();
      store.dispose();
    },
  );

  test('an unread verse does not move on reopen or on a new day', () async {
    var now = DateTime(2026, 10, 28);
    final store = PlannerStore(memoryPreferences(), clock: () => now);
    await store.load(startBibleSession: true);
    store.goToBiblePage(100);
    store.openBibleSession();
    expect(store.biblePage, 100);
    now = DateTime(2026, 11, 2);
    store.refreshBibleDay();
    expect(store.biblePage, 100);
    expect(store.bibleReadDates, isEmpty);
    await store.flush();
    store.dispose();
  });

  test(
    'v3 dates migrate to daily history and survive subsequent reloads',
    () async {
      final prefs = memoryPreferences();
      final old = jsonEncode({
        'schemaVersion': 3,
        'bibleCursorKey': '0:1:1',
        'bibleReadDates': {'0:1:1': '2026-10-27'},
        'bibleNotes': {'0:1:1': '기존 메모'},
        'bibleBookmarks': ['0:1:1'],
      });
      await prefs.setString('dayframe_data_v1', old);
      final store = PlannerStore(prefs, clock: () => DateTime(2026, 10, 28));
      await store.load(startBibleSession: true);
      expect(store.bibleReadingDays['2026-10-27'], {'0:1:1'});
      expect(store.selectedVerse.key, '0:1:2');
      store.toggleBibleRead();
      await store.flush();
      await store.load();
      expect(store.bibleReadingDays['2026-10-28'], {'0:1:2'});
      expect(store.bibleNotes['0:1:1'], '기존 메모');
      expect(store.bibleBookmarks, {'0:1:1'});
      expect(store.selectedVerse.key, '0:1:2');
      store.dispose();
    },
  );

  test(
    'Acts 24:7 is excluded from navigation, chapters and progress',
    () async {
      final content = await BibleContent.load();
      final six = bibleVerseAt(bibleVerseIndex(43, 24, 6));
      final eight = bibleVerseAt(bibleVerseIndex(43, 24, 8));
      expect(content.adjacentPage(six, 1), eight.index);
      expect(content.adjacentPage(eight, -1), six.index);
      expect(content.availablePage(six.index + 1), eight.index);
      expect(
        content.chapterPassages(43, 24).any((p) => p.first.verse == 7),
        isFalse,
      );
      expect(content.countForChapter(43, 24), 26);
    },
  );

  test(
    'daily history includes rereads and counts a range once per date',
    () async {
      var now = DateTime(2026, 10, 28);
      final store = PlannerStore(memoryPreferences(), clock: () => now);
      await store.load(startBibleSession: true);
      store.goToBiblePage(bibleVerseIndex(4, 6, 18));
      store.toggleBibleRead();
      expect(store.bibleReadHistory.length, 1);
      expect(store.bibleReadingStreak, 1);
      now = DateTime(2026, 10, 29);
      store.refreshBibleDay();
      store.moveBibleVerse(-1);
      store.toggleBibleRead();
      expect(store.bibleReadHistory.length, 2);
      expect(store.bibleReadHistory.first.date, '2026-10-29');
      expect(store.bibleReadHistory.first.verse.key, '4:6:18');
      expect(store.bibleReadingStreak, 2);
      expect(store.bibleReadDayCount, 2);
      store.toggleBibleRead();
      expect(store.bibleReadHistory.length, 1);
      expect(store.bibleReadingStreak, 1);
      expect(store.totalReadCount, 2);
      now = DateTime(2026, 11, 1);
      expect(store.bibleReadingStreak, 0);
      await store.flush();
      store.dispose();
    },
  );

  testWidgets(
    'collapse reduces card height, keeps controls and persists to lock screen',
    (tester) async {
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      store.bibleContent = (await tester.runAsync(BibleContent.load))!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: store,
                builder: (_, _) => DailyVerseCard(store: store),
              ),
            ),
          ),
        ),
      );
      final before = tester.getSize(find.byType(Card)).height;
      await tester.tap(find.byTooltip('본문 접기'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Card)).height, lessThan(before));
      expect(find.text('태초에 하나님이 천지를 창조하시니라'), findsNothing);
      expect(find.text('창세기 1장 1절'), findsOneWidget);
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(find.text('오늘 읽기 완료'), findsOneWidget);
      expect(store.selectedVerse.key, '0:1:1');
      await store.flush();
      final loaded = PlannerStore(prefs);
      await tester.runAsync(loaded.load);
      expect(loaded.display.bibleCollapsed, isTrue);
      await tester.pumpWidget(LockOverlayApp(store: loaded));
      await tester.pumpAndSettle();
      expect(find.text('태초에 하나님이 천지를 창조하시니라'), findsNothing);
      await tester.tap(find.byTooltip('본문 펼치기'));
      await tester.pumpAndSettle();
      expect(find.text('태초에 하나님이 천지를 창조하시니라'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await loaded.flush();
      store.dispose();
      loaded.dispose();
    },
  );

  testWidgets(
    'lock screen advances at midnight and on native reopen, not on read',
    (tester) async {
      var now = DateTime(2026, 10, 28, 23, 59, 59);
      final store = PlannerStore(memoryPreferences(), clock: () => now);
      store.bibleContent = (await tester.runAsync(BibleContent.load))!;
      store.openBibleSession();
      await tester.pumpWidget(LockOverlayApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(store.selectedVerse.key, '0:1:1');
      now = DateTime(2026, 10, 29);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(store.selectedVerse.key, '0:1:2');
      expect(find.text('오늘 읽기 완료'), findsNothing);
      await tester.tap(find.byKey(const Key('verse-read')));
      await tester.pumpAndSettle();
      expect(store.selectedVerse.key, '0:1:2');
      await store.flush();
      Future<void> reload({required bool startSession}) async {
        var reloaded = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'dev.dayframe/overlay',
              const StandardMethodCodec().encodeMethodCall(
                MethodCall('reload', {'startBibleSession': startSession}),
              ),
              (_) => reloaded = true,
            );
        for (var attempt = 0; attempt < 20 && !reloaded; attempt++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 1)),
          );
        }
        await tester.pumpAndSettle();
        expect(reloaded, isTrue);
      }

      await reload(startSession: false);
      expect(store.selectedVerse.key, '0:1:2');
      await reload(startSession: true);
      expect(store.selectedVerse.key, '0:1:3');
      expect(store.hasReadBibleToday, isTrue);
      await tester.pumpWidget(const SizedBox());
      await store.flush();
      store.dispose();
    },
  );
}
