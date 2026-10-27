import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/format.dart';
import 'package:dayframe/core/models.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/widgets/planner_board.dart';
import 'package:dayframe/widgets/paged_board.dart';
import 'package:dayframe/main.dart';
import 'test_support.dart';

void main() {
  void size(WidgetTester tester, Size value) {
    tester.view.physicalSize = value; tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
  }
  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byTooltip('다음 페이지')); await tester.pumpAndSettle();
  }
  testWidgets('overflow uses horizontal pages while close stays at bottom', (tester) async {
    size(tester,const Size(360,600));
    var closed=false;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PagedBoard(onClose:()=>closed=true,sections:{
      'a':const SizedBox(height:300,child:Text('first')),
      'b':const SizedBox(height:300,child:Text('second')),
    })))); await tester.pumpAndSettle();
    final before=tester.getRect(find.byKey(const Key('board-close')));
    expect(before.bottom,600);
    expect(find.text('1 / 2'),findsOneWidget);
    await next(tester);
    expect(find.text('2 / 2'),findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('board-close'))),before);
    await tester.tap(find.byKey(const Key('board-close'))); expect(closed,isTrue);
  });
  testWidgets('short flicks on empty space and edges change pages', (tester) async {
    size(tester,const Size(360,600));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PagedBoard(onClose:(){},sections:{
      'a':const SizedBox(height:300,child:Text('first')),
      'b':const SizedBox(height:300,child:Text('second')),
    }))));await tester.pumpAndSettle();
    await tester.flingFrom(const Offset(350,450),const Offset(-80,0),500);await tester.pumpAndSettle();
    expect(find.text('2 / 2'),findsOneWidget);
    await tester.flingFrom(const Offset(10,450),const Offset(80,0),500);await tester.pumpAndSettle();
    expect(find.text('1 / 2'),findsOneWidget);
  });
  testWidgets('calendar tap registers the tapped date and memo text opens a blank note', (tester) async {
    size(tester,const Size(400,1200));
    final store=PlannerStore(memoryPreferences());
    final now=DateTime.now();final date=DateTime(now.year,now.month,now.day==1?2:1);
    store.notes.add(PlannerNote(id:'old',text:'기존 메모',createdAt:''));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlannerBoard(store:store,onClose:(){}))));await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('day-${dayKey(date)}')));await tester.pumpAndSettle();
    expect(find.byType(AlertDialog),findsOneWidget);
    await tester.enterText(find.byType(TextField).first,'날짜 일정');await tester.tap(find.text('저장'));await tester.pumpAndSettle();
    expect(store.events.single.date,dayKey(date));
    await tester.tap(find.text('기존 메모'));await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,isEmpty);
    await tester.enterText(find.byType(TextField),'새 메모');await tester.tap(find.text('저장'));await tester.pumpAndSettle();
    expect(store.notes.map((n)=>n.text),containsAll(['기존 메모','새 메모']));
    await store.flush();store.dispose();
  });
  testWidgets('calendar events precede notes', (tester) async {
    size(tester,const Size(400,1200));
    final store=PlannerStore(memoryPreferences());
    final now=DateTime.now();
    store.events.add(PlannerEvent(id:'e',title:'일정',date:dayKey(now),hour:9,minute:0));
    store.notes.add(PlannerNote(id:'n',text:'메모',createdAt:''));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlannerBoard(store:store,onClose:(){}))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const ValueKey('memo-event-e'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('memo-note-n'))).dy));
    store.dispose();
  });
  testWidgets('settings toggles update in the actual route and persist', (tester) async {
    final prefs=memoryPreferences(); final store=PlannerStore(prefs);
    await tester.pumpWidget(DayframeApp(store:store)); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('설정')); await tester.pumpAndSettle();
    final hidden=find.widgetWithText(SwitchListTile,'잠금화면에서 내용 숨기기');
    await tester.tap(hidden); await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(hidden).value,isFalse);
    await tester.tap(hidden); await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(hidden).value,isTrue);
    final dark=find.widgetWithText(SwitchListTile,'다크 모드');
    await tester.tap(dark); await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(dark).value,isTrue);
    expect(Theme.of(tester.element(dark)).brightness,Brightness.dark);
    await store.flush(); final reloaded=PlannerStore(prefs);await reloaded.load();
    expect(reloaded.display.darkMode,isTrue);expect(reloaded.display.hidePrivateDetails,isTrue);
    await tester.tap(dark);await tester.pumpAndSettle();
    expect(Theme.of(tester.element(dark)).brightness,Brightness.light);
    await store.flush();await tester.pumpWidget(const SizedBox());store.dispose();reloaded.dispose();
  });
  testWidgets('goals remain accessible on small screens and steps save', (tester) async {
    size(tester,const Size(320,568));
    final store=PlannerStore(memoryPreferences());
    store.goals.add(GoalItem(id:'g',title:'자격증',steps:['기출 풀이'],finishedSteps:[false]));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlannerBoard(store:store,onClose:(){}))));
    await tester.pumpAndSettle();
    for(var i=0;i<8 && find.text('기출 풀이').hitTestable().evaluate().isEmpty;i++){await next(tester);}
    await tester.tap(find.text('기출 풀이').hitTestable());await tester.pumpAndSettle();
    expect(store.goals.single.finishedSteps.single,isTrue);await store.flush();
    expect(tester.takeException(),isNull);store.dispose();
  });
  testWidgets('lock creation requires opt-in and saves a new note', (tester) async {
    size(tester,const Size(400,1200));
    final store=PlannerStore(memoryPreferences());
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlannerBoard(store:store,locked:true,onClose:(){}))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-note')),findsNothing);
    await tester.tap(find.byKey(const Key('board-memo')));await tester.pumpAndSettle();
    expect(find.byType(AlertDialog),findsNothing);
    await tester.tap(find.byKey(ValueKey('day-${dayKey(DateTime.now())}')));await tester.pumpAndSettle();
    expect(find.byType(AlertDialog),findsNothing);
    store.updateDisplay((p){p.lockCreateNote=true;p.lockCreateEvent=true;});await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-event')),findsNothing);
    await tester.tap(find.byKey(const Key('board-memo')));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),'잠금 메모');
    await tester.tap(find.text('저장'));await tester.pumpAndSettle();
    expect(store.notes.single.text,'잠금 메모');
    await tester.tap(find.byKey(ValueKey('day-${dayKey(DateTime.now())}')));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first,'새 일정');
    await tester.tap(find.text('저장'));await tester.pumpAndSettle();
    expect(store.events.single.title,'새 일정');
    expect(store.events.single.date,dayKey(DateTime.now()));
    await store.flush();store.dispose();
  });
  testWidgets('hidden mode also hides goal titles', (tester) async {
    size(tester,const Size(400,1200));
    final store=PlannerStore(memoryPreferences());
    store.goals.add(GoalItem(id:'g',title:'PRIVATE GOAL',steps:[],finishedSteps:[]));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PlannerBoard(store:store,locked:true,onClose:(){}))));
    await tester.pumpAndSettle();expect(find.text('PRIVATE GOAL'),findsNothing);store.dispose();
  });
}
