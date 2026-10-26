import 'package:flutter/material.dart';
import '../core/store.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key,required this.store});
  final PlannerStore store;
  @override Widget build(BuildContext context) => ListView(
    padding:const EdgeInsets.fromLTRB(18,12,18,110),children:[
      Row(children:[Expanded(child:Text('장기 플랜',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800))),
        IconButton.filledTonal(onPressed:()=>editGoalDialog(context,store),icon:const Icon(Icons.add),tooltip:'목표 추가')]),
      const SizedBox(height:10),Text('큰 목표를 작은 단계로 나눠서 관리해요.',style:Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height:24),
      if(store.goals.isEmpty) const EmptyHint('등록한 목표가 없어요. 첫 목표를 만들어보세요.',icon:Icons.flag_outlined),
      for(final goal in store.goals) Padding(padding:const EdgeInsets.only(bottom:14),child:Panel(child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(Icons.outlined_flag,color:Theme.of(context).colorScheme.primary),const SizedBox(width:8),
            Expanded(child:Text(goal.title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700))),
            PopupMenuButton<String>(onSelected:(value)async{
              if(value=='edit'&&context.mounted){await editGoalDialog(context,store,goal:goal);}
              if(value=='pin'){store.toggleGoalPin(goal);}
              if(value=='delete'&&context.mounted&&await confirmDelete(context,goal.title)){store.deleteGoal(goal);}
            },itemBuilder:(ctx)=>[
              const PopupMenuItem(value:'edit',child:Text('수정')),
              PopupMenuItem(value:'pin',child:Text(goal.pinned?'오늘 화면 고정 해제':'오늘 화면에 고정')),
              const PopupMenuItem(value:'delete',child:Text('삭제')),
            ]),
          ]),
          if(goal.description.isNotEmpty)...[const SizedBox(height:4),Text(goal.description,style:Theme.of(context).textTheme.bodySmall)],
          if(goal.deadline.isNotEmpty)...[const SizedBox(height:7),Text('목표일 ${goal.deadline}',style:Theme.of(context).textTheme.labelMedium)],
          const SizedBox(height:15),ProgressPill(value:goal.progress),const SizedBox(height:8),
          Text('진행률 ${(goal.progress*100).round()}%  ·  ${goal.finishedSteps.where((v)=>v).length}/${goal.steps.length}단계',
            style:Theme.of(context).textTheme.bodySmall),
          if(goal.steps.isNotEmpty)...[const Divider(height:27),
            for(var i=0;i<goal.steps.length;i++)CheckboxListTile(
              value:goal.finishedSteps[i],onChanged:(_)=>store.toggleStep(goal,i),
              title:Text(goal.steps[i],style:TextStyle(decoration:goal.finishedSteps[i]?TextDecoration.lineThrough:null)),
              dense:true,contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading),
          ],
          if(goal.pinned) ...[const SizedBox(height:7),Row(children:[Icon(Icons.push_pin_outlined,size:13,color:Theme.of(context).colorScheme.primary),
            const SizedBox(width:4),Text('오늘 화면에 고정됨',style:Theme.of(context).textTheme.labelSmall)])],
        ]))),
    ],
  );
}
