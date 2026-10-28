import 'verse_counts.dart';
export 'verse_counts.dart';

// 개신교 66권의 장 수.
const bibleBookNames = <String>[
  '창세기',
  '출애굽기',
  '레위기',
  '민수기',
  '신명기',
  '여호수아',
  '사사기',
  '룻기',
  '사무엘상',
  '사무엘하',
  '열왕기상',
  '열왕기하',
  '역대상',
  '역대하',
  '에스라',
  '느헤미야',
  '에스더',
  '욥기',
  '시편',
  '잠언',
  '전도서',
  '아가',
  '이사야',
  '예레미야',
  '예레미야애가',
  '에스겔',
  '다니엘',
  '호세아',
  '요엘',
  '아모스',
  '오바댜',
  '요나',
  '미가',
  '나훔',
  '하박국',
  '스바냐',
  '학개',
  '스가랴',
  '말라기',
  '마태복음',
  '마가복음',
  '누가복음',
  '요한복음',
  '사도행전',
  '로마서',
  '고린도전서',
  '고린도후서',
  '갈라디아서',
  '에베소서',
  '빌립보서',
  '골로새서',
  '데살로니가전서',
  '데살로니가후서',
  '디모데전서',
  '디모데후서',
  '디도서',
  '빌레몬서',
  '히브리서',
  '야고보서',
  '베드로전서',
  '베드로후서',
  '요한일서',
  '요한이서',
  '요한삼서',
  '유다서',
  '요한계시록',
];
const bibleChapters = <int>[
  50,
  40,
  27,
  36,
  34,
  24,
  21,
  4,
  31,
  24,
  22,
  25,
  29,
  36,
  10,
  13,
  10,
  42,
  150,
  31,
  12,
  8,
  66,
  52,
  5,
  48,
  12,
  14,
  3,
  9,
  1,
  4,
  7,
  3,
  3,
  3,
  2,
  14,
  4,
  28,
  16,
  24,
  21,
  28,
  16,
  16,
  13,
  6,
  6,
  4,
  4,
  5,
  3,
  6,
  4,
  3,
  1,
  13,
  5,
  5,
  3,
  5,
  1,
  1,
  1,
  22,
];

class BibleLocation {
  const BibleLocation(this.book, this.chapter, this.index);
  final int book;
  final int chapter;
  final int index;
  String get reference => '${bibleBookNames[book]} $chapter장';
  String get key => '$book:$chapter';
}

BibleLocation bibleAt(int index) {
  var offset = index.clamp(0, 1188).toInt();
  for (var book = 0; book < bibleChapters.length; book++) {
    if (offset < bibleChapters[book]) {
      return BibleLocation(book, offset + 1, index.clamp(0, 1188).toInt());
    }
    offset -= bibleChapters[book];
  }
  return const BibleLocation(65, 22, 1188);
}

int bibleIndex(int book, int chapter) {
  var result = 0;
  for (var i = 0; i < book; i++) {
    result += bibleChapters[i];
  }
  return result + chapter - 1;
}

final totalBibleVerses = bibleVerseCounts
    .expand((v) => v)
    .fold<int>(0, (a, b) => a + b);

class BibleVerse {
  const BibleVerse(this.book, this.chapter, this.verse, this.index);
  final int book, chapter, verse, index;
  String get reference => '${bibleBookNames[book]} $chapter장 $verse절';
  String get key => '$book:$chapter:$verse';
}

// 절 위치는 한 번만 계산해 둔다.
final _verses = <BibleVerse>[
  for (var b = 0, index = 0; b < bibleVerseCounts.length; b++)
    for (var c = 0; c < bibleVerseCounts[b].length; c++)
      for (var v = 1; v <= bibleVerseCounts[b][c]; v++)
        BibleVerse(b, c + 1, v, index++),
];
BibleVerse bibleVerseAt(int index) =>
    _verses[index.clamp(0, totalBibleVerses - 1).toInt()];
int bibleVerseIndex(int book, int chapter, [int verse = 1]) {
  RangeError.checkValidIndex(book, bibleVerseCounts, 'book');
  RangeError.checkValueInInterval(
    chapter,
    1,
    bibleVerseCounts[book].length,
    'chapter',
  );
  RangeError.checkValueInInterval(
    verse,
    1,
    bibleVerseCounts[book][chapter - 1],
    'verse',
  );
  var index = verse - 1;
  for (var b = 0; b < book; b++) {
    for (final count in bibleVerseCounts[b]) {
      index += count;
    }
  }
  for (var c = 0; c < chapter - 1; c++) {
    index += bibleVerseCounts[book][c];
  }
  return index;
}

BibleVerse? bibleVerseFromKey(String key) {
  final parts = key.split(':').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) return null;
  try {
    return bibleVerseAt(bibleVerseIndex(parts[0]!, parts[1]!, parts[2]!));
  } on RangeError {
    return null;
  }
}

// 장 단위 기록의 날짜를 각 절에 그대로 옮긴다.
Map<String, String> migrateChapterDates(Map<String, String> chapters) {
  final result = <String, String>{};
  for (final entry in chapters.entries) {
    final parts = entry.key.split(':');
    if (parts.length != 2) continue;
    final b = int.tryParse(parts[0]), c = int.tryParse(parts[1]);
    if (b == null ||
        c == null ||
        b < 0 ||
        b >= 66 ||
        c < 1 ||
        c > bibleChapters[b]) {
      continue;
    }
    for (var v = 1; v <= bibleVerseCounts[b][c - 1]; v++) {
      result['$b:$c:$v'] = entry.value;
    }
  }
  return result;
}
