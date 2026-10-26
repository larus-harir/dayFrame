import 'package:flutter/material.dart';
import '../core/bible_data.dart';
import '../core/format.dart';
import '../core/store.dart';
import '../widgets/common.dart';

/// 이 화면은 잠금화면 UX 미리보기입니다. 실제 OS 잠금화면 자동 실행 기능은 아닙니다.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key,required this.store});
  final PlannerStore store;
  @override Widget build(BuildContext context){
    final now=DateTime.now();
    final theme=Theme.of(context);
    final preferences=store.display;
    final due=store.eventsOn(now);
    final tasks=store.tasksOn(now);
    return Scaffold(backgroundColor:theme.colorScheme.surface,
      body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,28,20,34),children:[
        Row(children:[Expanded(child:Text('DAYFRAME  ·  잠금화면 프리뷰',style:theme.textTheme.labelMedium)),
          IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close),tooltip:'닫기')]),
        const SizedBox(height:22),
        Text('${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
          textAlign:TextAlign.center,style:theme.textTheme.displayLarge?.copyWith(fontWeight:FontWeight.w300,fontSize:66)),
        Text(formatDateFull(now),textAlign:TextAlign.center,style:theme.textTheme.titleMedium),
        const SizedBox(height:28),
        if(preferences.events)...[
          const SectionHeading('오늘의 일정'),
          if(preferences.hidePrivateDetails)const Panel(child:Text('잠금화면 미리보기: 일정 내용 숨김'))
          else if(due.isEmpty)const Panel(child:Text('오늘 일정 없음'))
          else Panel(child:Column(children:[for(final event in due.take(4))ListTile(dense:true,contentPadding:EdgeInsets.zero,title:Text('${event.clock}  ${event.title}'))])),
          const SizedBox(height:20),
        ],
        if(preferences.bible)...[
          const SectionHeading('오늘의 성경'),
          Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(bibleAt(store.nextUnreadPage).reference,style:theme.textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
            const SizedBox(height:6),Text('오늘 ${store.todayReadCount}장 완료 · 전체 ${store.totalReadCount}/1189장'),
          ])),const SizedBox(height:20),
        ],
        if(preferences.tasks)...[
          const SectionHeading('오늘 체크리스트'),
          Panel(child:tasks.isEmpty?const Text('오늘 반복 항목 없음'):Column(children:[
            for(final task in tasks)CheckboxListTile(
              value:task.isDone(now),onChanged:(_)=>store.toggleTask(task,now),
              controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero,dense:true,title:Text(task.title)),
          ])),const SizedBox(height:20),
        ],
        if(preferences.goals)...[
          const SectionHeading('장기 플랜'),
          for(final goal in store.pinnedGoals.take(2))Padding(padding:const EdgeInsets.only(bottom:8),child:Panel(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[Text(goal.title,style:const TextStyle(fontWeight:FontWeight.w700)),
              const SizedBox(height:10),ProgressPill(value:goal.progress)]))),
          const SizedBox(height:12),
        ],
        if(preferences.notes)...[
          const SectionHeading('고정 메모'),
          Panel(child:preferences.hidePrivateDetails?const Text('잠금 상태에서 메모 숨김'):
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              for(final event in due.where((e)=>e.pinned).take(2))Padding(padding:const EdgeInsets.only(bottom:8),child:Text('📌 ${event.clock} ${event.title}')),
              for(final note in store.sortedNotes.where((n)=>n.pinned).take(2))Padding(padding:const EdgeInsets.only(bottom:8),child:Text('• ${note.text}')),
              if(!due.any((e)=>e.pinned)&&!store.notes.any((n)=>n.pinned))const Text('고정된 메모가 없어요.'),
            ])),
          const SizedBox(height:20),
        ],
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.keyboard_arrow_down),label:const Text('해제 / 닫기')),
        const SizedBox(height:8),Text('실제 시스템 잠금화면이 아닌 앱 내부 프리뷰입니다.',
          style:theme.textTheme.bodySmall,textAlign:TextAlign.center),
      ])),
    );
  }
}
