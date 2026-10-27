import 'dart:convert';
import 'package:dayframe/core/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/bible_data.dart';
import 'package:dayframe/core/store.dart';
import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('new task completion can be added and removed', () async {
    final store = PlannerStore(memoryPreferences());
    store.addTask('read', [1,2,3,4,5,6,7]);
    final task = store.tasks.single;
    final date = DateTime(2026,10,26);
    store.toggleTask(task,date);
    expect(task.isDone(date),isTrue);
    store.toggleTask(task,date);
    expect(task.isDone(date),isFalse);
    await store.flush();
    store.dispose();
  });
  test('legacy data upgrades once without losing dates, notes or cursor', () async {
    final prefs = memoryPreferences();
    final old = jsonEncode({
      'bibleReadDates':{'0:1':'2026-10-25'},
      'bibleNotes':{'0:1':'legacy reflection'},'biblePage':50,
      'notes':[PlannerNote(id:'n',text:'keep',createdAt:'2026-10-25').toJson()],
    });
    await prefs.setString('dayframe_data_v1',old);
    final store = PlannerStore(prefs);
    await store.load();
    expect(store.totalReadCount,31);
    expect(store.bibleReadDates['0:1:31'],'2026-10-25');
    expect(store.selectedVerse.reference,'출애굽기 1장 1절');
    expect(store.legacyBibleNotes['0:1'],'legacy reflection');
    expect(store.notes.single.text,'keep');
    expect(await prefs.getString('dayframe_data_v1_pre_verse_backup'),old);
    final reloaded = PlannerStore(prefs);
    await reloaded.load();
    expect(reloaded.bibleReadDates,store.bibleReadDates);
    expect(reloaded.biblePage,store.biblePage);
    store.dispose();reloaded.dispose();
  });
  test('verse progress crosses chapters, persists and supports undo', () async {
    final prefs = memoryPreferences();
    final store = PlannerStore(prefs);
    store.goToBiblePage(bibleVerseIndex(0,1,31));
    store.toggleBibleRead();
    expect(store.selectedVerse.reference,'창세기 2장 1절');
    expect(store.todayReadCount,1);
    store.toggleBibleRead();
    expect(store.totalReadCount,2);
    await store.flush();
    final other = PlannerStore(prefs);
    await other.load();
    expect(other.selectedVerse.reference,'창세기 2장 2절');
    other.goToBiblePage(bibleVerseIndex(0,1,31));other.toggleBibleRead();
    expect(other.totalReadCount,1);
    await other.flush();
    store.dispose();other.dispose();
  });
  test('task edit survives store refresh after returning from lock screen', () async {
    final prefs=memoryPreferences();
    final store=PlannerStore(prefs);
    store.addTask('before',[1,2,3,4,5,6,7]);await store.flush();
    final editing=store.tasks.single;
    await store.load();
    store.editTask(editing,'after',[1]);
    store.toggleTask(editing,DateTime(2026,10,26));await store.flush();
    expect(store.tasks.single.title,'after');
    expect(store.tasks.single.isDone(DateTime(2026,10,26)),isTrue);
    store.dispose();
  });
}
