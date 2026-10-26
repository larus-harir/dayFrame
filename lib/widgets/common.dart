import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title,{super.key,this.subtitle,this.onAdd,this.addIcon=Icons.add_rounded});
  final String title;
  final String? subtitle;
  final VoidCallback? onAdd;
  final IconData addIcon;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom:12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700)),
        if(subtitle!=null) Text(subtitle!,style:Theme.of(context).textTheme.bodySmall),
      ])),
      if (onAdd!=null) IconButton.filledTonal(onPressed:onAdd, icon:Icon(addIcon), tooltip:'추가'),
    ]),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key,required this.child,this.padding=const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius:BorderRadius.circular(19),
      border:Border.all(color:Theme.of(context).colorScheme.outlineVariant.withValues(alpha:.45)),
    ),
    child:child,
  );
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.message,{super.key,this.icon=Icons.inbox_outlined});
  final String message;
  final IconData icon;
  @override Widget build(BuildContext context) => Panel(child:Padding(
    padding:const EdgeInsets.symmetric(vertical:12),
    child:Column(children:[Icon(icon,color:Theme.of(context).colorScheme.outline),const SizedBox(height:8),
      Text(message,textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodyMedium)]),
  ));
}

class ProgressPill extends StatelessWidget {
  const ProgressPill({super.key,required this.value});
  final double value;
  @override Widget build(BuildContext context) => ClipRRect(borderRadius:BorderRadius.circular(6),
    child:LinearProgressIndicator(value:value.clamp(0.0,1.0).toDouble(),minHeight:7,backgroundColor:Theme.of(context).colorScheme.surfaceContainerHighest));
}

Future<bool> confirmDelete(BuildContext context,String name) async => await showDialog<bool>(
  context:context,builder:(ctx) => AlertDialog(
    title:const Text('삭제할까요?'),content:Text('"$name" 항목을 삭제합니다.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('취소')),
      FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('삭제'))],
  ),
) ?? false;

InputDecoration inputStyle(String label,{String? hint}) => InputDecoration(labelText:label,hintText:hint,
  border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)));

Widget actionFooter(BuildContext context,VoidCallback onSubmit,{String submitText='저장'}) =>
  Row(mainAxisAlignment:MainAxisAlignment.end,children:[
    TextButton(onPressed:()=>Navigator.pop(context),child:const Text('취소')),
    const SizedBox(width:8),FilledButton(onPressed:onSubmit,child:Text(submitText)),
  ]);

void showMessage(BuildContext context,String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
}
