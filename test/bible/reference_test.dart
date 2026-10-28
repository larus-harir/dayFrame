import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/bible/reference.dart';

void main() {
  test('all 31,102 verses map both ways, including chapter boundaries', () {
    expect(totalBibleVerses, 31102);
    expect(bibleVerseCounts.length, 66);
    for (var b = 0; b < 66; b++) {
      expect(bibleVerseCounts[b].length, bibleChapters[b]);
    }
    for (var i = 0; i < totalBibleVerses; i++) {
      final v = bibleVerseAt(i);
      expect(bibleVerseIndex(v.book, v.chapter, v.verse), i);
    }
    expect(bibleVerseAt(0).reference, '창세기 1장 1절');
    expect(bibleVerseAt(30).reference, '창세기 1장 31절');
    expect(bibleVerseAt(31).reference, '창세기 2장 1절');
    expect(bibleVerseAt(totalBibleVerses - 1).reference, '요한계시록 22장 21절');
    expect(() => bibleVerseIndex(0, 1, 32), throwsRangeError);
  });
  test('개신교 성경 66권 총 1189장', () {
    expect(bibleBookNames.length, 66);
    expect(bibleChapters.length, 66);
    expect(bibleChapters.reduce((a, b) => a + b), 1189);
  });
  test('장 번호의 처음과 끝 매핑', () {
    expect(bibleAt(0).reference, '창세기 1장');
    expect(bibleAt(49).reference, '창세기 50장');
    expect(bibleAt(50).reference, '출애굽기 1장');
    expect(bibleAt(1188).reference, '요한계시록 22장');
    expect(bibleIndex(65, 22), 1188);
  });
}
