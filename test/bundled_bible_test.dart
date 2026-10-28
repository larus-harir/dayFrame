import 'dart:convert';
import 'package:dayframe/core/bible_content.dart';
import 'package:dayframe/core/bible_data.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/lock_overlay.dart';
import 'package:dayframe/screens/bible_screen.dart';
import 'package:dayframe/widgets/verse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled text covers every declared position and preserves all eleven ranges',
    () async {
      final content = await BibleContent.load();
      expect(content.verses.length, 31101);
      expect(content.missing, {'43:24:7'});
      final unique = content.passages.values.toSet();
      expect(unique.length, 31088);
      expect(unique.where((p) => p.first.index != p.last.index).length, 11);
      for (var i = 0; i < totalBibleVerses; i++) {
        final v = bibleVerseAt(i);
        expect(
          content.verses.containsKey(v.key) || content.missing.contains(v.key),
          isTrue,
          reason: v.key,
        );
      }
      expect(bibleVerseCounts[46][12], 13);
      expect(bibleVerseCounts[63][0], 15);
    },
  );
  test(
    'John continuation is repaired and invisible corruption is removed',
    () async {
      final content = await BibleContent.load();
      expect(
        content.verses['42:18:38'],
        '빌라도가 이르되 진리가 무엇이냐 하더라 이 말을 하고 다시 유대인들에게 나가서 이르되 나는 그에게서 아무 죄도 찾지 못하였노라',
      );
      expect(
        content.verses.values.any(
          (v) => v.contains('\u0000') || v.contains('\uFFFD'),
        ),
        isFalse,
      );
      expect(content.verses.keys.any((key) => key.contains('이')), isFalse);
    },
  );
  test(
    'range read and undo update every covered verse and navigate once',
    () async {
      final store = PlannerStore(memoryPreferences());
      await store.load();
      store.goToBiblePage(bibleVerseIndex(4, 6, 18));
      store.toggleBibleRead();
      expect(store.bibleReadDates.keys, containsAll(['4:6:18', '4:6:19']));
      expect(store.totalReadCount, 2);
      expect(store.selectedVerse.key, '4:6:20');
      store.moveBibleVerse(-1);
      expect(store.selectedVerse.key, '4:6:19');
      expect(
        store.bibleContent.referenceFor(store.selectedVerse),
        '신명기 6장 18–19절',
      );
      store.toggleBibleRead();
      expect(store.totalReadCount, 0);
      await store.flush();
      store.dispose();
    },
  );
  test(
    'a partial old range completion can be completed without deleting it',
    () async {
      final store = PlannerStore(memoryPreferences());
      await store.load();
      store.bibleReadDates['4:6:18'] = '2026-10-27';
      store.goToBiblePage(bibleVerseIndex(4, 6, 19));
      expect(store.isBibleRead(store.selectedVerse), isFalse);
      store.toggleBibleRead();
      expect(store.totalReadCount, 2);
      expect(store.selectedVerse.key, '4:6:20');
      await store.flush();
      store.dispose();
    },
  );
  test(
    'missing source position is not fabricated or counted as read',
    () async {
      final store = PlannerStore(memoryPreferences());
      await store.load();
      expect(store.bibleReadingTotal, 31101);
      store.goToBiblePage(bibleVerseIndex(43, 24, 7));
      store.toggleBibleRead();
      expect(store.selectedVerse.key, '43:24:8');
      expect(store.bibleReadDates, isEmpty);
      for (var i = 0; i <= bibleVerseIndex(43, 24, 7); i++) {
        store.bibleReadDates[bibleVerseAt(i).key] = '2026-10-27';
      }
      expect(store.nextUnreadPage, bibleVerseIndex(43, 24, 8));
      expect(store.totalReadCount, store.bibleReadDates.length - 1);
      await store.flush();
      store.dispose();
    },
  );
  test(
    'old cursor and removed reference migrate once with a full backup',
    () async {
      final prefs = memoryPreferences();
      final oldCursor = legacyKjvVerseCounts
          .take(47)
          .expand((c) => c)
          .fold(0, (a, b) => a + b);
      final raw = jsonEncode({
        'schemaVersion': 2,
        'biblePage': oldCursor,
        'bibleReadDates': {'46:13:14': '2026-10-27'},
        'bibleNotes': {'46:13:13': '기존 기록', '46:13:14': '이전 마지막 절 기록'},
        'bibleBookmarks': ['46:13:14'],
      });
      await prefs.setString('dayframe_data_v1', raw);
      final store = PlannerStore(prefs);
      await store.load();
      expect(store.selectedVerse.key, '47:1:1');
      expect(store.bibleReadDates['46:13:13'], '2026-10-27');
      expect(store.bibleReadDates.containsKey('46:13:14'), isFalse);
      expect(store.bibleNotes['46:13:13'], contains('기존 기록'));
      expect(store.bibleNotes['46:13:13'], contains('이전 마지막 절 기록'));
      expect(store.bibleBookmarks, contains('46:13:13'));
      expect(await prefs.getString('dayframe_data_v1_pre_bundled_backup'), raw);
      final reloaded = PlannerStore(prefs);
      await reloaded.load();
      expect(reloaded.bibleNotes, store.bibleNotes);
      expect(reloaded.selectedVerse.key, '47:1:1');
      store.dispose();
      reloaded.dispose();
    },
  );
  test('new saves prefer the stable verse key to a numeric offset', () async {
    final prefs = memoryPreferences();
    await prefs.setString(
      'dayframe_data_v1',
      jsonEncode({
        'schemaVersion': 3,
        'biblePage': 0,
        'bibleCursorKey': '63:1:15',
      }),
    );
    final store = PlannerStore(prefs);
    await store.load();
    expect(store.selectedVerse.key, '63:1:15');
    store.saveBibleNote('위치 유지');
    await store.flush();
    final reloaded = PlannerStore(prefs);
    await reloaded.load();
    expect(reloaded.selectedVerse.key, '63:1:15');
    expect(reloaded.bibleNotes['63:1:15'], '위치 유지');
    store.dispose();
    reloaded.dispose();
  });
  test(
    'bundle validation rejects a lost position and overlapping range',
    () async {
      final raw = await rootBundle.loadString('assets/bible/gae.json');
      final missing = jsonDecode(raw) as Map<String, dynamic>;
      (missing['verses'] as Map).remove('0:1:1');
      expect(
        () => BibleContent.parse(jsonEncode(missing)),
        throwsFormatException,
      );
      final overlap = jsonDecode(raw) as Map<String, dynamic>;
      (overlap['verses'] as Map)['4:6:19'] = '중복 검사';
      expect(
        () => BibleContent.parse(jsonEncode(overlap)),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'a fresh install shows the supplied text without a file or network setup',
    (tester) async {
      final store = PlannerStore(memoryPreferences());
      store.bibleContent = (await tester.runAsync(BibleContent.load))!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VerseCard(store: store)),
        ),
      );
      expect(find.text('태초에 하나님이 천지를 창조하시니라'), findsOneWidget);
      await tester.pumpWidget(LockOverlayApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('태초에 하나님이 천지를 창조하시니라'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
  testWidgets('reader renders a merged passage once in the full chapter', (
    tester,
  ) async {
    final store = PlannerStore(memoryPreferences());
    store.bibleContent = (await tester.runAsync(BibleContent.load))!;
    store.goToBiblePage(bibleVerseIndex(4, 6, 18));
    await tester.pumpWidget(MaterialApp(home: BibleScreen(store: store)));
    await tester.pumpAndSettle();
    expect(find.text('신명기 6장 18–19절'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const PageStorageKey('bible-chapter-full')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('bible-reader')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('이 장 전체 읽기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('chapter-verse-4-6-18')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('bible-reader')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const ValueKey('chapter-verse-4-6-18')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-verse-4-6-19')), findsNothing);
    expect(find.text('본문 파일 불러오기'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
