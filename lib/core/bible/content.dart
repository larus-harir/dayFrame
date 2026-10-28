import 'dart:convert';
import 'package:flutter/services.dart';
import 'reference.dart';

class BiblePassage {
  const BiblePassage(this.first, this.last, this.text);
  final BibleVerse first;
  final BibleVerse last;
  final String text;
  String get reference => first.index == last.index
      ? first.reference
      : '${bibleBookNames[first.book]} ${first.chapter}장 ${first.verse}–${last.verse}절';
  Iterable<String> get keys sync* {
    for (var i = first.index; i <= last.index; i++) {
      yield bibleVerseAt(i).key;
    }
  }
}

class BibleContent {
  const BibleContent({
    this.verses = const {},
    this.passages = const {},
    this.excluded = const {},
  });
  final Map<String, String> verses;
  final Map<String, BiblePassage> passages;
  final Set<String> excluded;
  static Future<BibleContent>? _bundled;
  static Future<BibleContent> load() => _bundled ??= rootBundle
      .loadString('assets/bible/korean_revised.json')
      .then(BibleContent.parse);

  BiblePassage? passageFor(BibleVerse verse) => passages[verse.key];
  String referenceFor(BibleVerse verse) =>
      passageFor(verse)?.reference ?? verse.reference;
  List<String> keysFor(BibleVerse verse) =>
      passages.isEmpty ? [verse.key] : passageFor(verse)?.keys.toList() ?? [];
  int adjacentPage(BibleVerse verse, int direction) {
    if (direction == 0) return verse.index;
    final passage = passageFor(verse);
    var index = direction < 0
        ? passage?.first.index ?? verse.index
        : passage?.last.index ?? verse.index;
    do {
      final next = index + direction.sign;
      if (next < 0 || next >= totalBibleVerses) return index;
      index = next;
    } while (excluded.contains(bibleVerseAt(index).key));
    return index;
  }

  int availablePage(int index) {
    final verse = bibleVerseAt(index);
    return excluded.contains(verse.key) ? adjacentPage(verse, 1) : verse.index;
  }

  Iterable<BiblePassage> chapterPassages(int book, int chapter) sync* {
    for (var v = 1; v <= bibleVerseCounts[book][chapter - 1]; v++) {
      final verse = bibleVerseAt(bibleVerseIndex(book, chapter, v));
      if (excluded.contains(verse.key)) continue;
      final passage = passageFor(verse);
      if (passage == null) {
        yield BiblePassage(verse, verse, '');
      } else if (passage.first.verse == v) {
        yield passage;
      }
    }
  }

  int countForChapter(int book, int chapter) => passages.isEmpty
      ? bibleVerseCounts[book][chapter - 1]
      : List.generate(
          bibleVerseCounts[book][chapter - 1],
          (v) => '$book:$chapter:${v + 1}',
        ).where(verses.containsKey).length;
  int countForBook(int book) => List.generate(
    bibleChapters[book],
    (c) => countForChapter(book, c + 1),
  ).fold(0, (a, b) => a + b);

  factory BibleContent.parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final metadata = data['metadata'] as Map<String, dynamic>;
    if (metadata['translation'] != '개역개정') {
      throw const FormatException('내장 성경 번역명이 다릅니다.');
    }
    final texts = Map<String, String>.from(data['verses'] as Map);
    final ranges = Map<String, dynamic>.from(data['ranges'] as Map);
    final declaredMissing = (metadata['excluded'] as List)
        .cast<String>()
        .toSet();
    final verses = <String, String>{};
    final passages = <String, BiblePassage>{};
    final invalidControls = RegExp(
      r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFD]',
    );
    for (final entry in texts.entries) {
      final first = bibleVerseFromKey(entry.key);
      if (first == null ||
          first.key != entry.key ||
          entry.value.trim().isEmpty ||
          invalidControls.hasMatch(entry.value)) {
        throw FormatException('내장 성경의 절 번호나 본문을 확인해주세요: ${entry.key}');
      }
      final end = ranges[entry.key] ?? first.verse;
      if (end is! int ||
          end < first.verse ||
          end > bibleVerseCounts[first.book][first.chapter - 1]) {
        throw FormatException('합절 범위가 잘못되었습니다: ${entry.key}');
      }
      final passage = BiblePassage(
        first,
        bibleVerseAt(bibleVerseIndex(first.book, first.chapter, end)),
        entry.value,
      );
      for (final key in passage.keys) {
        if (verses.containsKey(key)) throw FormatException('중복된 절입니다: $key');
        verses[key] = entry.value;
        passages[key] = passage;
      }
    }
    final actualMissing = {
      for (var i = 0; i < totalBibleVerses; i++)
        if (!verses.containsKey(bibleVerseAt(i).key)) bibleVerseAt(i).key,
    };
    if (ranges.keys.any((key) => !texts.containsKey(key)) ||
        metadata['passages'] != texts.length ||
        metadata['coveredPositions'] != verses.length ||
        actualMissing.length != declaredMissing.length ||
        !actualMissing.containsAll(declaredMissing)) {
      throw const FormatException('내장 성경의 전체 절 검증에 실패했습니다.');
    }
    return BibleContent(
      verses: Map.unmodifiable(verses),
      passages: Map.unmodifiable(passages),
      excluded: Set.unmodifiable(actualMissing),
    );
  }
}
