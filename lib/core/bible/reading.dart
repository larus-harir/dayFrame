import 'package:flutter/foundation.dart';
import '../format.dart';
import '../models.dart';
import 'content.dart';
import 'reference.dart';

class BibleReadRecord {
  const BibleReadRecord(this.date, this.verse);
  final String date;
  final BibleVerse verse;
}

mixin BibleReading on ChangeNotifier {
  DateTime get now;
  DisplayPreferences get display;
  void saveBibleChanges();

  Map<String, String> bibleReadDates = {};
  Map<String, String> bibleNotes = {};
  Map<String, String> legacyBibleNotes = {};
  Set<String> bibleBookmarks = {};
  Map<String, Set<String>> bibleReadingDays = {};
  BibleContent bibleContent = const BibleContent();
  int biblePage = 0;
  String? _bibleDay;

  BibleVerse get selectedVerse => bibleVerseAt(biblePage);
  Set<String> get _todayKeys => bibleReadingDays[dayKey(now)] ?? const {};
  bool get hasReadBibleToday => _todayKeys.any(_counted);
  bool isBibleRead(BibleVerse verse) {
    final keys = bibleContent.keysFor(verse);
    return keys.isNotEmpty && keys.every(bibleReadDates.containsKey);
  }

  bool isBibleReadToday(BibleVerse verse) {
    final keys = bibleContent.keysFor(verse);
    return keys.isNotEmpty && keys.every(_todayKeys.contains);
  }

  bool _counted(String key) =>
      bibleVerseFromKey(key) != null &&
      (bibleContent.verses.isEmpty || bibleContent.verses.containsKey(key));
  int get bibleReadingTotal => bibleContent.verses.isEmpty
      ? totalBibleVerses
      : bibleContent.verses.length;
  int get todayReadCount => _todayKeys.where(_counted).length;
  int get totalReadCount => bibleReadDates.keys.where(_counted).length;

  Set<String> get bibleReadingDates => {
    ...bibleReadDates.entries
        .where((entry) => _counted(entry.key))
        .map((entry) => entry.value),
    ...bibleReadingDays.entries
        .where((entry) => entry.value.any(_counted))
        .map((entry) => entry.key),
  };
  int get bibleReadDayCount => bibleReadingDates.length;
  int get bibleReadingStreak {
    final dates = bibleReadingDates;
    var date = DateTime(now.year, now.month, now.day);
    if (!dates.contains(dayKey(date))) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var count = 0;
    while (dates.contains(dayKey(date))) {
      count++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return count;
  }

  List<BibleReadRecord> get bibleReadHistory {
    final days = {
      for (final entry in bibleReadingDays.entries)
        entry.key: Set<String>.of(entry.value),
    };
    for (final entry in bibleReadDates.entries) {
      days.putIfAbsent(entry.value, () => {}).add(entry.key);
    }
    final result = <BibleReadRecord>[];
    for (final entry in days.entries) {
      final seen = <String>{};
      for (final key in entry.value.where(_counted)) {
        final verse = bibleVerseFromKey(key)!;
        final first = bibleContent.passageFor(verse)?.first ?? verse;
        if (seen.add(first.key)) result.add(BibleReadRecord(entry.key, first));
      }
    }
    result.sort((a, b) {
      final date = b.date.compareTo(a.date);
      return date != 0 ? date : a.verse.index.compareTo(b.verse.index);
    });
    return result;
  }

  int _nextUnreadFrom(int start) {
    for (var offset = 0; offset < totalBibleVerses; offset++) {
      final page = (start + offset) % totalBibleVerses;
      final key = bibleVerseAt(page).key;
      if (_counted(key) && !bibleReadDates.containsKey(key)) return page;
    }
    return bibleContent.availablePage(biblePage);
  }

  int get nextUnreadPage => _nextUnreadFrom(0);

  void openBibleSession() {
    _bibleDay = dayKey(now);
    final previousPage = biblePage;
    biblePage = isBibleRead(selectedVerse)
        ? _nextUnreadFrom((biblePage + 1) % totalBibleVerses)
        : bibleContent.availablePage(biblePage);
    if (biblePage != previousPage) display.bibleCollapsed = false;
    saveBibleChanges();
  }

  void refreshBibleDay() {
    if (_bibleDay == null) {
      _bibleDay = dayKey(now);
    } else if (_bibleDay != dayKey(now)) {
      openBibleSession();
    }
  }

  void goToBiblePage(int value) {
    biblePage = bibleContent.availablePage(value);
    saveBibleChanges();
  }

  void moveBibleVerse(int direction) =>
      goToBiblePage(bibleContent.adjacentPage(selectedVerse, direction));

  void _markRead(BibleVerse verse) {
    final today = dayKey(now);
    final keys = bibleContent.keysFor(verse);
    if (keys.isEmpty) return;
    display.bibleCollapsed = true;
    bibleReadingDays.putIfAbsent(today, () => {}).addAll(keys);
    for (final key in keys) {
      bibleReadDates.putIfAbsent(key, () => today);
    }
  }

  void _undoToday(BibleVerse verse) {
    final today = dayKey(now);
    for (final key in bibleContent.keysFor(verse)) {
      bibleReadingDays[today]?.remove(key);
      final previousDays =
          bibleReadingDays.entries
              .where((entry) => entry.value.contains(key))
              .map((entry) => entry.key)
              .toList()
            ..sort();
      if (previousDays.isEmpty) {
        if (bibleReadDates[key] == today) bibleReadDates.remove(key);
      } else {
        bibleReadDates[key] = previousDays.first;
      }
    }
    if (bibleReadingDays[today]?.isEmpty ?? false) {
      bibleReadingDays.remove(today);
    }
  }

  void toggleBibleRead() {
    _bibleDay = dayKey(now);
    if (isBibleReadToday(selectedVerse)) {
      _undoToday(selectedVerse);
    } else {
      _markRead(selectedVerse);
    }
    saveBibleChanges();
  }

  void saveBibleNoteAt(String key, String value) {
    if (!_counted(key)) return;
    if (value.trim().isEmpty) {
      bibleNotes.remove(key);
    } else {
      bibleNotes[key] = value.trim();
    }
    saveBibleChanges();
  }

  void toggleBibleBookmark(BibleVerse verse) {
    if (!_counted(verse.key)) return;
    if (!bibleBookmarks.remove(verse.key)) bibleBookmarks.add(verse.key);
    saveBibleChanges();
  }

  void toggleReviewedBibleRead(BibleVerse verse) {
    if (isBibleReadToday(verse)) {
      _undoToday(verse);
    } else {
      _markRead(verse);
    }
    saveBibleChanges();
  }
}
