import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_data.dart';
import 'format.dart';
import 'models.dart';
import 'bible_content.dart';

class PlannerStore extends ChangeNotifier {
  PlannerStore(this._prefs);
  static const _storageKey = 'dayframe_data_v1';
  final SharedPreferencesAsync _prefs;
  Future<void> _lastSave = Future<void>.value();

  List<TaskItem> tasks = [];
  List<PlannerEvent> events = [];
  List<PlannerNote> notes = [];
  List<GoalItem> goals = [];
  Map<String, String> bibleReadDates = {};
  Map<String, String> bibleNotes = {};
  Map<String, String> legacyBibleNotes = {};
  Set<String> bibleBookmarks = {};
  BibleContent bibleContent = const BibleContent();
  Future<void> flush() => _lastSave;
  DisplayPreferences display = DisplayPreferences();
  int biblePage = 0;

  Future<void> load() async {
    bibleContent = await BibleContent.load();
    final raw = await _prefs.getString(_storageKey);
    if (raw == null) {
      _seedDemo();
      _changed();
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (((data['schemaVersion'] as num?)?.toInt() ?? 1) > 3) {
        throw StateError('더 최신 버전의 저장 데이터입니다. 앱을 업데이트하세요.');
      }
      tasks = (data['tasks'] as List? ?? [])
          .map((v) => TaskItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      events = (data['events'] as List? ?? [])
          .map(
            (v) => PlannerEvent.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      notes = (data['notes'] as List? ?? [])
          .map((v) => PlannerNote.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      goals = (data['goals'] as List? ?? [])
          .map((v) => GoalItem.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      bibleReadDates = (data['bibleReadDates'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      bibleNotes = (data['bibleNotes'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      bibleBookmarks = (data['bibleBookmarks'] as List? ?? [])
          .whereType<String>()
          .toSet();
      display = DisplayPreferences.fromJson(
        Map<String, dynamic>.from(data['display'] as Map? ?? {}),
      );
      biblePage = ((data['biblePage'] as num?)?.toInt() ?? 0)
          .clamp(0, 1188)
          .toInt();
      if (((data['schemaVersion'] as num?)?.toInt() ?? 1) < 2) {
        // 이전 전 원본을 한 번 보관한다.
        if (await _prefs.getString('dayframe_data_v1_pre_verse_backup') ==
            null) {
          await _prefs.setString('dayframe_data_v1_pre_verse_backup', raw);
        }
        legacyBibleNotes = Map.of(bibleNotes);
        bibleNotes = {};
        bibleReadDates = migrateChapterDates(bibleReadDates);
        final old = bibleAt(biblePage);
        biblePage = bibleVerseIndex(old.book, old.chapter);
        _changed();
        await flush();
      } else {
        legacyBibleNotes = (data['legacyBibleNotes'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
        if (data['schemaVersion'] == 2) {
          if (await _prefs.getString('dayframe_data_v1_pre_bundled_backup') ==
              null) {
            await _prefs.setString('dayframe_data_v1_pre_bundled_backup', raw);
          }
          const oldKey = '46:13:14';
          const newKey = '46:13:13';
          final date = bibleReadDates.remove(oldKey);
          if (date != null) bibleReadDates.putIfAbsent(newKey, () => date);
          final oldNote = bibleNotes.remove(oldKey);
          if (oldNote != null && oldNote.isNotEmpty) {
            final current = bibleNotes[newKey];
            bibleNotes[newKey] = current == null || current.isEmpty
                ? oldNote
                : '$current\n\n이전 13장 14절 기록: $oldNote';
          }
          if (bibleBookmarks.remove(oldKey)) bibleBookmarks.add(newKey);
          final legacyKey = legacyBibleVerseKeyAt(
            (data['biblePage'] as num?)?.toInt() ?? 0,
          );
          final location = bibleVerseFromKey(
            legacyKey == oldKey ? newKey : legacyKey,
          )!;
          biblePage = location.index;
          _changed();
          await flush();
        } else {
          final cursor = bibleVerseFromKey(
            data['bibleCursorKey']?.toString() ?? '',
          );
          biblePage =
              cursor?.index ??
              ((data['biblePage'] as num?)?.toInt() ?? 0)
                  .clamp(0, totalBibleVerses - 1)
                  .toInt();
        }
        notifyListeners();
      }
    } catch (error) {
      debugPrint('저장 데이터 읽기 실패: $error');
      rethrow; // 손상된 저장 데이터를 덮어쓰지 않도록 중단
    }
  }

  void _seedDemo() {
    final now = DateTime.now();
    final today = dayKey(now);
    tasks = [
      TaskItem(id: generateId(), title: '성경 1절 읽기'),
      TaskItem(id: 'demo-study', title: '자격증 공부 30분', days: [1, 2, 3, 4, 5, 6]),
      TaskItem(id: 'demo-exercise', title: '운동하기', days: [1, 3, 5]),
    ];
    events = [
      PlannerEvent(
        id: 'demo-event',
        title: '일정 등록 예시 (수정하거나 삭제하세요)',
        date: today,
        hour: 19,
        minute: 0,
      ),
    ];
    notes = [
      PlannerNote(
        id: 'demo-note',
        text: '여기에 생각나는 일을 자유롭게 기록해보세요.',
        createdAt: now.toIso8601String(),
      ),
    ];
    goals = [
      GoalItem(
        id: 'demo-goal1',
        title: '자격증 공부 계획',
        description: '시험 준비 단계를 나누어 관리하기',
        steps: ['학습 순서 정리', '기본 이론 공부', '기출문제 풀이'],
        finishedSteps: [true, false, false],
      ),
      GoalItem(
        id: 'demo-goal2',
        title: '개인 앱 개발',
        description: 'Flutter 프로젝트 만들기',
        steps: ['기본 UI', '로컬 저장', '잠금화면 연동 검토'],
        finishedSteps: [true, true, false],
      ),
    ];
  }

  Map<String, dynamic> _serialize() => {
    'schemaVersion': 3,
    'bibleCursorKey': selectedVerse.key,
    'legacyBibleNotes': legacyBibleNotes,
    'tasks': tasks.map((x) => x.toJson()).toList(),
    'events': events.map((x) => x.toJson()).toList(),
    'notes': notes.map((x) => x.toJson()).toList(),
    'goals': goals.map((x) => x.toJson()).toList(),
    'bibleReadDates': bibleReadDates,
    'bibleNotes': bibleNotes,
    'biblePage': biblePage,
    'display': display.toJson(),
    'bibleBookmarks': bibleBookmarks.toList(),
  };

  void _changed() {
    final content = jsonEncode(_serialize());
    _lastSave = _lastSave
        .catchError((Object e) {
          debugPrint('이전 저장 실패: $e');
        })
        .then((_) => _prefs.setString(_storageKey, content));
    _lastSave.catchError((Object e) {
      debugPrint('저장 실패: $e');
    });
    notifyListeners();
  }

  List<TaskItem> tasksOn(DateTime date) =>
      tasks.where((x) => x.isScheduled(date)).toList();
  List<PlannerEvent> eventsOn(DateTime date) =>
      events.where((x) => x.date == dayKey(date)).toList()..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
  List<PlannerNote> get sortedNotes => [...notes]
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  List<GoalItem> get pinnedGoals => goals.where((x) => x.pinned).toList();

  void addTask(String title, List<int> days) {
    tasks.add(TaskItem(id: generateId(), title: title, days: days));
    _changed();
  }

  void editTask(TaskItem task, String title, List<int> days) {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    tasks[index].title = title;
    tasks[index].days = days;
    _changed();
  }

  void deleteTask(TaskItem task) {
    tasks.removeWhere((x) => x.id == task.id);
    _changed();
  }

  void toggleTask(TaskItem task, DateTime date) {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    task = tasks[index];
    final key = dayKey(date);
    if (task.completedDates.contains(key)) {
      task.completedDates.remove(key);
    } else {
      task.completedDates.add(key);
    }
    _changed();
  }

  void upsertEvent(PlannerEvent event) {
    final index = events.indexWhere((x) => x.id == event.id);
    if (index == -1) {
      events.add(event);
    } else {
      events[index] = event;
    }
    _changed();
  }

  void deleteEvent(PlannerEvent event) {
    events.removeWhere((x) => x.id == event.id);
    _changed();
  }

  void toggleEventPin(PlannerEvent event) {
    event.pinned = !event.pinned;
    _changed();
  }

  void upsertNote(PlannerNote note) {
    final index = notes.indexWhere((x) => x.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    _changed();
  }

  void deleteNote(PlannerNote note) {
    notes.removeWhere((x) => x.id == note.id);
    _changed();
  }

  void toggleNotePin(PlannerNote note) {
    note.pinned = !note.pinned;
    _changed();
  }

  void upsertGoal(GoalItem goal) {
    final index = goals.indexWhere((x) => x.id == goal.id);
    if (index == -1) {
      goals.add(goal);
    } else {
      goals[index] = goal;
    }
    _changed();
  }

  void deleteGoal(GoalItem goal) {
    goals.removeWhere((x) => x.id == goal.id);
    _changed();
  }

  void toggleGoalPin(GoalItem goal) {
    goal.pinned = !goal.pinned;
    _changed();
  }

  void toggleStep(GoalItem goal, int step) {
    goal.finishedSteps[step] = !goal.finishedSteps[step];
    _changed();
  }

  BibleVerse get selectedVerse => bibleVerseAt(biblePage);
  bool isBibleRead(BibleVerse verse) {
    final keys = bibleContent.keysFor(verse);
    return keys.isNotEmpty && keys.every(bibleReadDates.containsKey);
  }

  bool _counted(String key) =>
      bibleContent.verses.isEmpty || bibleContent.verses.containsKey(key);
  int get bibleReadingTotal => bibleContent.verses.isEmpty
      ? totalBibleVerses
      : bibleContent.verses.length;
  int get todayReadCount => bibleReadDates.entries
      .where((v) => v.value == dayKey(DateTime.now()) && _counted(v.key))
      .length;
  int get totalReadCount => bibleReadDates.keys.where(_counted).length;
  int get nextUnreadPage {
    for (var i = 0; i < totalBibleVerses; i++) {
      final verse = bibleVerseAt(i);
      if (_counted(verse.key) && !bibleReadDates.containsKey(verse.key)) {
        return i;
      }
    }
    return totalBibleVerses - 1;
  }

  void goToBiblePage(int value) {
    biblePage = value.clamp(0, totalBibleVerses - 1).toInt();
    _changed();
  }

  void goToNextUnreadBible() {
    biblePage = nextUnreadPage;
    _changed();
  }

  void moveBibleVerse(int direction) =>
      goToBiblePage(bibleContent.adjacentPage(selectedVerse, direction));
  void toggleBibleRead() {
    final verse = selectedVerse;
    final keys = bibleContent.keysFor(verse);
    if (keys.isEmpty) {
      moveBibleVerse(1);
      return;
    }
    if (isBibleRead(verse)) {
      for (final key in keys) {
        bibleReadDates.remove(key);
      }
    } else {
      for (final key in keys) {
        bibleReadDates.putIfAbsent(key, () => dayKey(DateTime.now()));
      }
      biblePage = bibleContent.adjacentPage(verse, 1);
    }
    _changed();
  }

  void saveBibleNote(String value) => saveBibleNoteAt(selectedVerse.key, value);
  void saveBibleNoteAt(String key, String value) {
    if (bibleVerseFromKey(key) == null) return;
    if (value.trim().isEmpty) {
      bibleNotes.remove(key);
    } else {
      bibleNotes[key] = value.trim();
    }
    _changed();
  }

  void toggleBibleBookmark(BibleVerse verse) {
    if (!bibleBookmarks.remove(verse.key)) bibleBookmarks.add(verse.key);
    _changed();
  }

  void toggleReviewedBibleRead(BibleVerse verse) {
    final keys = bibleContent.keysFor(verse);
    if (isBibleRead(verse)) {
      for (final key in keys) {
        bibleReadDates.remove(key);
      }
    } else {
      for (final key in keys) {
        bibleReadDates.putIfAbsent(key, () => dayKey(DateTime.now()));
      }
    }
    _changed();
  }

  void updateDisplay(void Function(DisplayPreferences) change) {
    change(display);
    _changed();
  }
}
