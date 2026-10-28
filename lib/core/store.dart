import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible/reference.dart';
import 'format.dart';
import 'models.dart';
import 'bible/content.dart';
import 'bible/reading.dart';

class PlannerStore extends ChangeNotifier with BibleReading {
  PlannerStore(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  @override
  DateTime get now => _clock();
  @override
  void saveBibleChanges() => _changed();
  static const _storageKey = 'dayframe_data_v1';
  final SharedPreferencesAsync _prefs;
  Future<void> _lastSave = Future<void>.value();

  List<TaskItem> tasks = [];
  List<PlannerEvent> events = [];
  List<PlannerNote> notes = [];
  List<GoalItem> goals = [];
  Future<void> flush() => _lastSave;
  @override
  DisplayPreferences display = DisplayPreferences();

  Future<void> load({bool startBibleSession = false}) async {
    bibleContent = await BibleContent.load();
    final raw = await _prefs.getString(_storageKey);
    if (raw == null) {
      _changed();
      if (startBibleSession) openBibleSession();
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (((data['schemaVersion'] as num?)?.toInt() ?? 1) > 4) {
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
      bibleReadingDays = {
        for (final entry in (data['bibleReadingDays'] as Map? ?? {}).entries)
          entry.key.toString(): (entry.value as List)
              .whereType<String>()
              .toSet(),
      };
      if ((data['schemaVersion'] as num? ?? 1) < 4) {
        for (final entry in bibleReadDates.entries) {
          bibleReadingDays.putIfAbsent(entry.value, () => {}).add(entry.key);
        }
      }
      display = DisplayPreferences.fromJson(
        Map<String, dynamic>.from(data['display'] as Map? ?? {}),
      );
      biblePage = ((data['biblePage'] as num?)?.toInt() ?? 0)
          .clamp(0, 1188)
          .toInt();
      if (((data['schemaVersion'] as num?)?.toInt() ?? 1) < 2) {
        // 장 단위 기록은 원본을 보관한 뒤 절 단위로 옮긴다.
        if (await _prefs.getString('dayframe_data_v1_pre_verse_backup') ==
            null) {
          await _prefs.setString('dayframe_data_v1_pre_verse_backup', raw);
        }
        legacyBibleNotes = Map.of(bibleNotes);
        bibleNotes = {};
        bibleReadDates = migrateChapterDates(bibleReadDates);
        bibleReadingDays = {};
        for (final entry in bibleReadDates.entries) {
          bibleReadingDays.putIfAbsent(entry.value, () => {}).add(entry.key);
        }
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
          for (final keys in bibleReadingDays.values) {
            if (keys.remove(oldKey)) keys.add(newKey);
          }
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
        biblePage = bibleContent.availablePage(biblePage);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('저장 데이터 읽기 실패: $error');
      rethrow;
    }
    if (startBibleSession) openBibleSession();
  }

  Map<String, dynamic> _serialize() => {
    'schemaVersion': 4,
    'bibleReadingDays': bibleReadingDays.map(
      (day, keys) => MapEntry(day, keys.toList()),
    ),
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

  void updateDisplay(void Function(DisplayPreferences) change) {
    change(display);
    _changed();
  }
}
