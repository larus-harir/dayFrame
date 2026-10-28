import 'dart:convert';
import 'package:dayframe/core/bible_content.dart';
import 'package:dayframe/core/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'CSV round-trip preserves Korean, comma, quotes, newlines and attribution',
    () {
      const content = BibleContent(
        verses: {'0:1:1': '검증용, "인용"\n다음 줄', '65:22:21': '마지막 검증 문장'},
        source: '제공처, 출처',
        copyright: '권리 표시',
      );
      final loaded = BibleContent.parse('\uFEFF${content.toCsv()}');
      expect(loaded.verses, content.verses);
      expect(loaded.source, content.source);
      expect(loaded.copyright, content.copyright);
      expect(BibleContent.parse(loaded.toJson()).verses, content.verses);
    },
  );
  test(
    'CSV accepts reordered headers, LF, zero-based books and shared metadata',
    () {
      final content = BibleContent.parse(
        'translation,text,verse,chapter,book\n개역개정,첫 검증 문장,1,1,0\n,둘째 검증 문장,2,1,창세기\n',
      );
      expect(content.verses, {'0:1:1': '첫 검증 문장', '0:1:2': '둘째 검증 문장'});
    },
  );
  test(
    'CSV rejects duplicates, invalid positions, missing metadata and another translation',
    () {
      for (final raw in [
        'book,chapter,verse,text,translation\n창세기,1,1,문장,개역개정\n0,1,1,다른 문장,',
        'book,chapter,verse,text,translation\n창세기,1,999,문장,개역개정',
        'book,chapter,verse,text,translation\n창세기,1,1,,개역개정',
        'book,chapter,verse,text\n창세기,1,1,문장',
        'book,chapter,verse,text,translation\n창세기,1,1,문장,개역한글',
        'book,chapter,verse,text,translation\n창세기,1,1,문장,개역개정\n창세기,1,2,문장,다른 번역',
        'book,chapter,verse,text,translation\n창세기,1,1,문장',
        'book,book,chapter,verse,text,translation\n창세기,창세기,1,1,문장,개역개정',
      ]) {
        expect(
          () => BibleContent.parse(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    },
  );
  test(
    'CSV import persists without changing notes or the reading position',
    () async {
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      store.goToBiblePage(10);
      store.saveBibleNote('기록 유지');
      await store.importBibleContent(
        'book,chapter,verse,text,translation\n창세기,1,1,검증 문장,개역개정',
      );
      await store.flush();
      final loaded = PlannerStore(prefs);
      await loaded.load();
      expect(loaded.bibleContent.verses['0:1:1'], '검증 문장');
      expect(loaded.biblePage, 10);
      expect(loaded.bibleNotes, store.bibleNotes);
      await expectLater(
        loaded.importBibleContent('not,a,bible'),
        throwsFormatException,
      );
      final again = PlannerStore(prefs);
      await again.load();
      expect(again.bibleContent.verses, loaded.bibleContent.verses);
      store.dispose();
      loaded.dispose();
      again.dispose();
    },
  );
  test('existing JSON, including UTF-8 BOM, remains supported', () {
    final raw = jsonEncode({
      'translation': '개역개정',
      'verses': {'0:1:1': '검증 문장'},
    });
    expect(BibleContent.parse('\uFEFF$raw').verses['0:1:1'], '검증 문장');
  });
}
