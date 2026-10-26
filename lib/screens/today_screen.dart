import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/store.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';
import 'bible_screen.dart';
import '../widgets/verse_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key,required this.store,required this.openGoals,required this.openCalendar,required this.openNotes,required this.openPreview});
  final PlannerStore store;
  final VoidCallback openGoals,openCalendar,openNotes,openPreview;

  @override Widget build(BuildContext context) {
    final today=DateTime.now();
    final daily=store.tasksOn(today);
    final completed=daily.where((x)=>x.isDone(today)).length;
    final due=store.eventsOn(today);
    final pinnedEvents=due.where((e)=>e.pinned).toList();
    final pinnedNotes=store.sortedNotes.where((e)=>e.pinned).toList();
    return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,110),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(formatDateFull(today),style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:Theme.of(context).colorScheme.primary)),
        const SizedBox(height:3),Text('오늘도 하나씩, 천천히.',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
      ])),IconButton.filledTonal(onPressed:openPreview,tooltip:'잠금 플래너 열기 / 설정',icon:const Icon(Icons.phone_android_rounded))]),
      const SizedBox(height:22),
      if(store.display.events) ...[
        SectionHeading('오늘의 일정',subtitle:'오늘 등록된 일정 ${due.length}개',onAdd:()=>editEventDialog(context,store,initialDate:today)),
        if(due.isEmpty) const EmptyHint('등록된 일정이 없어요.',icon:Icons.calendar_month_outlined)
        else Panel(child:Column(children:[for(var i=0;i<due.length;i++) ...[
          if(i>0) const Divider(height:18),
          InkWell(onTap:()=>editEventDialog(context,store,event:due[i]),borderRadius:BorderRadius.circular(12),child:Row(children:[
            SizedBox(width:55,child:Text(due[i].clock,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w700))),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(due[i].title,style:const TextStyle(fontWeight:FontWeight.w600)),
              if(due[i].memo.isNotEmpty) Text(due[i].memo,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),
            ])),Icon(due[i].pinned?Icons.push_pin_rounded:Icons.chevron_right_rounded,size:18,color:Theme.of(context).colorScheme.outline),
          ])),
        ]])),
        const SizedBox(height:24),
      ],
      if(store.display.bible) ...[
        SectionHeading('성경 일독',subtitle:'오늘 ${store.todayReadCount}절 · 전체 ${store.totalReadCount}/31102절'),
        VerseCard(store:store),
        TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>BibleScreen(store:store))),child:const Text('성경 전체 기록 / 메모')),
        const SizedBox(height:24),
      ],
      if(store.display.tasks) ...[
        SectionHeading('데일리 체크리스트',subtitle:'$completed / ${daily.length} 완료',onAdd:()=>editTaskDialog(context,store)),
        if(daily.isEmpty) const EmptyHint('오늘 반복되는 체크리스트가 없어요.',icon:Icons.check_box_outlined)
        else Panel(child:Column(children:[for(final task in daily)
          CheckboxListTile(value:task.isDone(today),onChanged:(_)=>store.toggleTask(task,today),
            title:Text(task.title,style:TextStyle(decoration:task.isDone(today)?TextDecoration.lineThrough:null)),
            controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero,dense:true),
        ])),
        const SizedBox(height:24),
      ],
      if(store.display.goals) ...[
        SectionHeading('장기 플랜',subtitle:'고정해 둔 목표',onAdd:openGoals,addIcon:Icons.arrow_forward_rounded),
        if(store.pinnedGoals.isEmpty) const EmptyHint('고정한 장기 플랜이 없어요.',icon:Icons.flag_outlined)
        else ...store.pinnedGoals.take(3).map((goal)=>Padding(padding:const EdgeInsets.only(bottom:10),child:
          InkWell(onTap:openGoals,borderRadius:BorderRadius.circular(19),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(goal.title,style:const TextStyle(fontWeight:FontWeight.w700))),
              Text('${(goal.progress*100).round()}%',style:Theme.of(context).textTheme.labelMedium)]),
            if(goal.description.isNotEmpty) ...[const SizedBox(height:5),Text(goal.description,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall)],
            const SizedBox(height:12),ProgressPill(value:goal.progress),
            if(goal.deadline.isNotEmpty)...[const SizedBox(height:8),Text('목표일 ${goal.deadline}',style:Theme.of(context).textTheme.bodySmall)],
          ]))))),
        const SizedBox(height:14),
      ],
      if(store.display.notes) ...[
        SectionHeading('메모',subtitle:'당일 고정 일정 + 고정 메모',onAdd:()=>editNoteDialog(context,store)),
        if(pinnedEvents.isEmpty&&pinnedNotes.isEmpty) const EmptyHint('고정된 내용이 없어요. 메모를 추가해보세요.',icon:Icons.sticky_note_2_outlined)
        else Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          for(final event in pinnedEvents) ListTile(contentPadding:EdgeInsets.zero,dense:true,
            leading:const Icon(Icons.event_note_rounded),title:Text('${event.clock} ${event.title}'),
            subtitle:event.memo.isEmpty?null:Text(event.memo,maxLines:1,overflow:TextOverflow.ellipsis),
            trailing:IconButton(icon:const Icon(Icons.push_pin_rounded,size:18),tooltip:'상단 고정 해제',onPressed:()=>store.toggleEventPin(event)),
            onTap:()=>editEventDialog(context,store,event:event)),
          for(final note in pinnedNotes) ListTile(contentPadding:EdgeInsets.zero,dense:true,
            leading:const Icon(Icons.sticky_note_2_outlined),title:Text(note.text,maxLines:3,overflow:TextOverflow.ellipsis),
            trailing:IconButton(icon:const Icon(Icons.push_pin_rounded,size:18),tooltip:'고정 해제',onPressed:()=>store.toggleNotePin(note)),
            onTap:()=>editNoteDialog(context,store,note:note)),
        ])),
        const SizedBox(height:10),TextButton(onPressed:openNotes,child:const Text('모든 메모 보기')),
      ],
    ]);
  }
}
