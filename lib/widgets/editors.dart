import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import 'common.dart';

Future<void> editTaskDialog(BuildContext context,PlannerStore store,{TaskItem? task}) async {
  final controller = TextEditingController(text:task?.title ?? '');
  final days = <int>{...?(task?.days ?? [1,2,3,4,5,6,7])};
  await showDialog<void>(context:context,builder:(ctx) => StatefulBuilder(builder:(ctx,setDialogState) => AlertDialog(
    title:Text(task==null?'체크리스트 추가':'체크리스트 수정'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      TextField(controller:controller,autofocus:true,decoration:inputStyle('할 일',hint:'예: 자격증 공부 30분')),
      const SizedBox(height:18),const Text('반복 요일'),const SizedBox(height:6),
      Wrap(spacing:6,runSpacing:0,children:List.generate(7,(i) {
        final weekday=i+1;
        return FilterChip(label:Text(koreanWeekdays[i]),selected:days.contains(weekday),onSelected:(selected){
          setDialogState(() {if(selected){days.add(weekday);}else{days.remove(weekday);}});
        });
      })),
      const SizedBox(height:6),Text('선택한 요일마다 표시됩니다.',style:Theme.of(ctx).textTheme.bodySmall),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('취소')),
      FilledButton(onPressed:(){
        if(controller.text.trim().isEmpty || days.isEmpty) {showMessage(ctx,'할 일과 반복 요일을 선택해주세요.');return;}
        if(task==null) {store.addTask(controller.text.trim(),days.toList()..sort());}
        else {store.editTask(task,controller.text.trim(),days.toList()..sort());}
        Navigator.pop(ctx);
      },child:const Text('저장'))],
  )));
  controller.dispose();
}

Future<void> editEventDialog(BuildContext context,PlannerStore store,{PlannerEvent? event,DateTime? initialDate}) async {
  final title = TextEditingController(text:event?.title ?? '');
  final memo = TextEditingController(text:event?.memo ?? '');
  var date = event!=null?parseDate(event.date):(initialDate ?? DateTime.now());
  var time = TimeOfDay(hour:event?.hour ?? 9,minute:event?.minute ?? 0);
  var pinned = event?.pinned ?? true;
  await showDialog<void>(context:context,builder:(ctx) => StatefulBuilder(builder:(ctx,update) => AlertDialog(
    title:Text(event==null?'일정 등록':'일정 수정'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,autofocus:true,decoration:inputStyle('일정 이름')),
      const SizedBox(height:12),
      Row(children:[Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.event),label:Text('${date.month}/${date.day}'),onPressed:() async {
        final picked=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));
        if(picked!=null)update(()=>date=picked);
      })),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.schedule),label:Text(time.format(ctx)),onPressed:() async {
        final picked=await showTimePicker(context:ctx,initialTime:time);
        if(picked!=null)update(()=>time=picked);
      }))]),
      const SizedBox(height:12),TextField(controller:memo,maxLines:3,decoration:inputStyle('상세 메모 (선택)')),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('당일 메모 상단에 고정'),value:pinned,onChanged:(value)=>update(()=>pinned=value)),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('취소')),
      FilledButton(onPressed:(){
        if(title.text.trim().isEmpty){showMessage(ctx,'일정 이름을 입력해주세요.');return;}
        store.upsertEvent(PlannerEvent(id:event?.id??generateId(),title:title.text.trim(),date:dayKey(date),hour:time.hour,minute:time.minute,memo:memo.text.trim(),pinned:pinned));
        Navigator.pop(ctx);
      },child:const Text('저장'))],
  )));
  title.dispose();memo.dispose();
}

Future<void> editNoteDialog(BuildContext context,PlannerStore store,{PlannerNote? note}) async {
  final controller=TextEditingController(text:note?.text ?? '');
  var pinned=note?.pinned ?? false;
  await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
    title:Text(note==null?'메모 추가':'메모 수정'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:controller,autofocus:true,minLines:3,maxLines:7,decoration:inputStyle('메모 내용')),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('상단에 고정'),value:pinned,onChanged:(v)=>update(()=>pinned=v)),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('취소')),
      FilledButton(onPressed:(){
        if(controller.text.trim().isEmpty){showMessage(ctx,'메모 내용을 입력해주세요.');return;}
        store.upsertNote(PlannerNote(id:note?.id??generateId(),text:controller.text.trim(),pinned:pinned,createdAt:note?.createdAt??DateTime.now().toIso8601String()));
        Navigator.pop(ctx);
      },child:const Text('저장'))],
  )));
  controller.dispose();
}

Future<void> editGoalDialog(BuildContext context,PlannerStore store,{GoalItem? goal}) async {
  final title=TextEditingController(text:goal?.title ?? '');
  final description=TextEditingController(text:goal?.description ?? '');
  final steps=TextEditingController(text:goal?.steps.join('\n') ?? '');
  DateTime? deadline = goal?.deadline.isNotEmpty==true ? DateTime.tryParse(goal!.deadline):null;
  var pinned=goal?.pinned ?? true;
  await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
    title:Text(goal==null?'장기 플랜 추가':'장기 플랜 수정'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,autofocus:true,decoration:inputStyle('목표 이름',hint:'예: SQLD 취득')),
      const SizedBox(height:12),TextField(controller:description,maxLines:2,decoration:inputStyle('설명 (선택)')),
      const SizedBox(height:12),TextField(controller:steps,minLines:3,maxLines:6,
        decoration:inputStyle('세부 단계 (한 줄에 하나씩)',hint:'이론 공부\n기출문제 풀기\n시험 응시')),
      const SizedBox(height:12),
      Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()async{
        final date=await showDatePicker(context:ctx,initialDate:deadline??DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2100));
        if(date!=null)update(()=>deadline=date);
      },icon:const Icon(Icons.flag_outlined),label:Text(deadline==null?'목표일 선택':'목표일: ${dayKey(deadline!)}'))),
        if(deadline!=null)IconButton(onPressed:()=>update(()=>deadline=null),icon:const Icon(Icons.clear))]),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('오늘 화면에 고정'),value:pinned,onChanged:(v)=>update(()=>pinned=v)),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('취소')),
      FilledButton(onPressed:(){
        if(title.text.trim().isEmpty){showMessage(ctx,'목표 이름을 입력해주세요.');return;}
        final lines=steps.text.split('\n').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
        final oldCompleted=<String,bool>{};
        if(goal!=null){for(var i=0;i<goal.steps.length;i++){oldCompleted[goal.steps[i]]=goal.finishedSteps[i];}}
        store.upsertGoal(GoalItem(id:goal?.id??generateId(),title:title.text.trim(),description:description.text.trim(),
          deadline:deadline==null?'':dayKey(deadline!),pinned:pinned,steps:lines,
          finishedSteps:lines.map((s)=>oldCompleted[s]??false).toList()));
        Navigator.pop(ctx);
      },child:const Text('저장'))],
  )));
  title.dispose();description.dispose();steps.dispose();
}
