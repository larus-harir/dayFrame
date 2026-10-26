import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/store.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key,required this.store});
  final PlannerStore store;
  @override State<CalendarScreen> createState()=>_CalendarScreenState();
}
class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime selected=dateOnly(DateTime.now());
  late DateTime displayed=DateTime(selected.year,selected.month,1);
  void month(int n) => setState(()=> displayed=DateTime(displayed.year,displayed.month+n,1));
  @override Widget build(BuildContext context) {
    final firstWeekday=displayed.weekday-1;
    final daysInMonth=DateTime(displayed.year,displayed.month+1,0).day;
    final count=((firstWeekday+daysInMonth+6)~/7)*7;
    final events=widget.store.eventsOn(selected);
    final today=dateOnly(DateTime.now());
    return ListView(padding:const EdgeInsets.fromLTRB(18,12,18,110),children:[
      Row(children:[Expanded(child:Text('캘린더',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800))),
        IconButton.filledTonal(onPressed:()=>editEventDialog(context,widget.store,initialDate:selected),icon:const Icon(Icons.add),tooltip:'일정 추가')]),
      const SizedBox(height:22),
      Panel(child:Column(children:[
        Row(children:[IconButton(onPressed:()=>month(-1),icon:const Icon(Icons.chevron_left_rounded)),
          Expanded(child:Text('${displayed.year}년 ${displayed.month}월',textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700))),
          IconButton(onPressed:()=>month(1),icon:const Icon(Icons.chevron_right_rounded))]),
        const SizedBox(height:10),
        Row(children:[for(var i=0;i<7;i++)Expanded(child:Center(child:Text(koreanWeekdays[i],style:TextStyle(fontWeight:FontWeight.w600,color:i>=5?Theme.of(context).colorScheme.primary:null))))]),
        const SizedBox(height:8),
        GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,mainAxisSpacing:6,crossAxisSpacing:2,childAspectRatio:.86),
          itemCount:count,itemBuilder:(ctx,index){
            final dayNumber=index-firstWeekday+1;
            if(dayNumber<1||dayNumber>daysInMonth)return const SizedBox.shrink();
            final date=DateTime(displayed.year,displayed.month,dayNumber);
            final active=dayKey(date)==dayKey(selected);
            final isToday=dayKey(date)==dayKey(today);
            final hasEvents=widget.store.eventsOn(date).isNotEmpty;
            return InkWell(onTap:()=>setState(()=>selected=date),borderRadius:BorderRadius.circular(12),child:Container(
              decoration:BoxDecoration(color:active?Theme.of(context).colorScheme.primaryContainer:null,borderRadius:BorderRadius.circular(12),
                border:isToday?Border.all(color:Theme.of(context).colorScheme.primary):null),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('$dayNumber',style:TextStyle(fontWeight:active?FontWeight.w900:FontWeight.w500)),
                const SizedBox(height:4),CircleAvatar(radius:2.5,backgroundColor:hasEvents?Theme.of(context).colorScheme.primary:Colors.transparent)]),
            ));
          }),
      ])),
      const SizedBox(height:24),
      SectionHeading('${formatDate(selected)} 일정',subtitle:'${events.length}개',onAdd:()=>editEventDialog(context,widget.store,initialDate:selected)),
      if(events.isEmpty) const EmptyHint('선택한 날짜에 일정이 없어요.',icon:Icons.event_available_outlined),
      for(final event in events) Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Row(children:[
        Container(width:4,height:45,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(5))),
        const SizedBox(width:12),SizedBox(width:54,child:Text(event.clock,style:const TextStyle(fontWeight:FontWeight.w700))),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(event.title,style:const TextStyle(fontWeight:FontWeight.w600)),if(event.memo.isNotEmpty)Text(event.memo,style:Theme.of(context).textTheme.bodySmall),
        ])),
        PopupMenuButton<String>(onSelected:(value)async{
          if(value=='edit'&&context.mounted){await editEventDialog(context,widget.store,event:event);}
          if(value=='pin'){widget.store.toggleEventPin(event);}
          if(value=='delete'&&context.mounted&&await confirmDelete(context,event.title)){widget.store.deleteEvent(event);}
        },itemBuilder:(ctx)=>[
          const PopupMenuItem(value:'edit',child:Text('수정')),
          PopupMenuItem(value:'pin',child:Text(event.pinned?'상단 고정 해제':'상단 고정')),
          const PopupMenuItem(value:'delete',child:Text('삭제')),
        ]),
      ]))),
      const SizedBox(height:12),Center(child:TextButton(onPressed:()=>setState((){selected=today;displayed=DateTime(today.year,today.month);}),child:const Text('오늘로 이동'))),
    ]);
  }
}
