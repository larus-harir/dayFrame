import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/store.dart';
import 'core/lock_summary.dart';
import 'widgets/verse_card.dart';

/// Launched by the foreground service, in its own Flutter engine.
@pragma('vm:entry-point')
Future<void> lockOverlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PlannerStore(SharedPreferencesAsync());
  try {
    await store.load();
    runApp(LockOverlayApp(store:store));
  } catch (_) {
    runApp(const MaterialApp(home:Scaffold(body:Center(child:Text('저장 데이터 확인이 필요합니다. 잠금을 해제하고 앱을 열어주세요.')))));
  }
}

class LockOverlayApp extends StatefulWidget {
  const LockOverlayApp({super.key,required this.store});
  final PlannerStore store;
  @override State<LockOverlayApp> createState()=>_LockOverlayAppState();
}
class _LockOverlayAppState extends State<LockOverlayApp> {
  static const channel=MethodChannel('dev.dayframe/overlay');
  Timer? midnight;
  @override void initState() {
    super.initState();
    channel.setMethodCallHandler((call) async {
      if(call.method=='reload') {await widget.store.flush();await widget.store.load();}
      if(call.method=='flush') await widget.store.flush();
    });
    // Dates are evaluated at local midnight, not after a fixed 24-hour interval.
    scheduleDateRefresh();
  }
  void scheduleDateRefresh() {
    final now=DateTime.now();
    midnight=Timer(DateTime(now.year,now.month,now.day+1).difference(now),() async {
      await widget.store.flush();
      await widget.store.load();
      if(mounted){setState((){});scheduleDateRefresh();}
    });
  }
  @override void dispose(){midnight?.cancel();channel.setMethodCallHandler(null);super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_) {
    final store=widget.store;
    final now=DateTime.now();
    final hidden=store.display.hidePrivateDetails;
    final summary=lockSummary(store,now);
    return MaterialApp(debugShowCheckedModeBanner:false,
      locale:const Locale('ko','KR'),supportedLocales:const [Locale('ko','KR')],
      localizationsDelegates:GlobalMaterialLocalizations.delegates,
      theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,colorSchemeSeed:const Color(0xFF58796C)),
      home:Scaffold(appBar:AppBar(title:const Text('DAYFRAME'),actions:[
        IconButton(tooltip:'닫기 · 휴대폰 잠금 유지',onPressed:() async {
          await store.flush();await channel.invokeMethod<void>('hide');
        },icon:const Icon(Icons.close)),
      ]),body:SafeArea(child:ListView(padding:const EdgeInsets.all(12),children:[
        const Text('잠금 위 플래너 · 닫아도 휴대폰 잠금은 유지됩니다.'),
        if(store.display.tasks) ...[
          const SizedBox(height:12),const Text('오늘 체크리스트'),
          if(hidden) Text(summary['체크리스트'] ?? '')
          else if(store.tasksOn(now).isEmpty) const Text('오늘 항목 없음')
          else for(final task in store.tasksOn(now)) CheckboxListTile(
            title:Text(task.title),value:task.isDone(now),
            onChanged:(_) async {store.toggleTask(task,DateTime.now());await store.flush();},
          ),
        ],
        if(store.display.bible) VerseCard(store:store),
        for(final entry in summary.entries.where((e)=>e.key!='체크리스트' && e.key!='성경 읽기'))
          Card(child:ListTile(title:Text(entry.key),subtitle:Text(entry.value))),
        if(hidden) const Text('개인 내용 숨김 사용 중입니다. 체크 항목을 표시하려면 앱 설정에서 변경하세요.'),
      ]))),
    );
  });
}
