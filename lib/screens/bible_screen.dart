import 'package:flutter/material.dart';
import '../core/bible_data.dart';
import '../core/store.dart';
import '../widgets/common.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key,required this.store});
  final PlannerStore store;
  @override State<BibleScreen> createState()=>_BibleScreenState();
}
class _BibleScreenState extends State<BibleScreen> {
  late final TextEditingController memo;
  late String editingKey;
  @override void initState(){super.initState();editingKey=widget.store.selectedVerse.key;memo=TextEditingController(text:widget.store.bibleNotes[editingKey]??'');widget.store.addListener(refresh);}
  void refresh(){if(!mounted)return;final key=widget.store.selectedVerse.key;
    if(key!=editingKey){editingKey=key;memo.text=widget.store.bibleNotes[key]??'';}
    setState((){});
  }
  @override void dispose(){widget.store.removeListener(refresh);memo.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final store=widget.store;
    final chapter=store.selectedVerse;
    final read=store.isBibleRead(chapter);
    return Scaffold(appBar:AppBar(title:const Text('성경 일독')),
      body:ListView(padding:const EdgeInsets.fromLTRB(18,10,18,110),children:[
        Row(children:[Expanded(child:Text('읽기 진행',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700))),
          Text('${store.totalReadCount} / 31,102절')]),
        const SizedBox(height:10),ProgressPill(value:store.totalReadCount/totalBibleVerses),
        const SizedBox(height:10),Text('오늘 읽은 분량 ${store.todayReadCount}절 · 하루 목표 1절',style:Theme.of(context).textTheme.bodySmall),
        const SizedBox(height:24),
        Panel(child:Column(children:[
          const Icon(Icons.auto_stories_rounded,size:34),const SizedBox(height:12),
          Text(chapter.reference,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:7),Text('${chapter.index+1} / 31,102절',style:Theme.of(context).textTheme.labelMedium),
          const SizedBox(height:18),
          Text('이 버전은 성경 본문이 아닌 읽기 순서와 완료 기록을 관리합니다.\n본문은 가지고 있는 성경이나 성경 앱에서 읽어주세요.',
            textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height:18),
          Row(children:[
            Expanded(child:OutlinedButton.icon(onPressed:chapter.index==0?null:()=>store.goToBiblePage(chapter.index-1),
              icon:const Icon(Icons.chevron_left),label:const Text('이전 절'))),const SizedBox(width:9),
            Expanded(child:OutlinedButton.icon(onPressed:chapter.index==totalBibleVerses-1?null:()=>store.goToBiblePage(chapter.index+1),
              icon:const Icon(Icons.chevron_right),label:const Text('다음 절'))),
          ]),
          const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:()=>store.toggleBibleRead(),icon:Icon(read?Icons.undo:Icons.check_circle_outline),
            label:Text(read?'완료 취소':'읽기 완료 · 다음 절로'))),
          const SizedBox(height:8),TextButton.icon(onPressed:store.goToNextUnreadBible,
            icon:const Icon(Icons.bookmark_outline),label:const Text('다음 미완료 절로 이동')),
        ])),
        const SizedBox(height:24),
        SectionHeading('읽은 내용 메모',subtitle:'${chapter.reference}에 대한 간단한 메모'),
        TextField(controller:memo,minLines:3,maxLines:7,decoration:inputStyle('느낀 점 / 기록')),
        const SizedBox(height:9),Align(alignment:Alignment.centerRight,
          child:FilledButton.tonal(onPressed:(){store.saveBibleNote(memo.text);showMessage(context,'메모를 저장했어요.');},child:const Text('메모 저장'))),
        const SizedBox(height:22),
        SectionHeading('다른 성경으로 이동'),
        Panel(child:Column(children:[
          DropdownButtonFormField<int>(key:ValueKey(chapter.book),initialValue:chapter.book,isExpanded:true,decoration:inputStyle('성경'),
            items:[for(var i=0;i<bibleBookNames.length;i++)DropdownMenuItem(value:i,child:Text(bibleBookNames[i]))],
            onChanged:(book){if(book!=null)store.goToBiblePage(bibleVerseIndex(book,1));}),
          const SizedBox(height:10),
          DropdownButtonFormField<int>(key:ValueKey(chapter.key),initialValue:chapter.chapter,decoration:inputStyle('장'),
            items:[for(var i=1;i<=bibleChapters[chapter.book];i++)DropdownMenuItem(value:i,child:Text('$i장'))],
            onChanged:(value){if(value!=null)store.goToBiblePage(bibleVerseIndex(chapter.book,value));}),
          const SizedBox(height:10),
          DropdownButtonFormField<int>(key:ValueKey('verse-${chapter.key}'),initialValue:chapter.verse,decoration:inputStyle('절'),
            items:[for(var v=1;v<=bibleVerseCounts[chapter.book][chapter.chapter-1];v++)DropdownMenuItem(value:v,child:Text('$v절'))],
            onChanged:(v){if(v!=null)store.goToBiblePage(bibleVerseIndex(chapter.book,chapter.chapter,v));}),
        ])),
        if(store.legacyBibleNotes['${chapter.book}:${chapter.chapter}'] case final String oldNote)
          Panel(child:Text('이전 장 메모: $oldNote')),
        const SizedBox(height:24),
        SectionHeading('최근 읽은 절'),
        if(store.bibleReadDates.isEmpty)const EmptyHint('아직 완료한 절이 없어요.',icon:Icons.menu_book_outlined)
        else Panel(child:Column(children:[for(final entry in (store.bibleReadDates.entries.toList()..sort((a,b)=>b.value.compareTo(a.value))).take(12))
          ListTile(dense:true,leading:const Icon(Icons.check_circle_outline),
            title:Text(_label(entry.key)),subtitle:Text(entry.value),contentPadding:EdgeInsets.zero),
        ])),
      ]),
    );
  }
  String _label(String key){
    final parts=key.split(':');if(parts.length!=3)return key;
    final book=int.tryParse(parts[0])??0;
    final chapter=int.tryParse(parts[1])??1;
    if(book<0||book>=bibleBookNames.length)return key;
    return '${bibleBookNames[book]} $chapter장 ${parts[2]}절';
  }
}
