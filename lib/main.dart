import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/store.dart';
import 'core/lock_surface.dart';
export 'lock_overlay.dart' show lockOverlayMain;
import 'screens/calendar_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store=PlannerStore(SharedPreferencesAsync());
  try {
    await store.load();
    runApp(DayframeApp(store:store));
  } catch (error) {
    runApp(MaterialApp(home:Scaffold(body:Center(child:Padding(
      padding:const EdgeInsets.all(24),child:Text('저장된 데이터를 읽을 수 없습니다.\n앱 데이터를 백업한 뒤 확인해주세요.\n\n$error',textAlign:TextAlign.center),
    )))));
  }
}

class DayframeApp extends StatelessWidget {
  const DayframeApp({super.key,required this.store});
  final PlannerStore store;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_) {
    final scheme=ColorScheme.fromSeed(seedColor:const Color(0xFF58796C),brightness:store.display.darkMode?Brightness.dark:Brightness.light);
    return MaterialApp(title:'DAYFRAME',debugShowCheckedModeBanner:false,
      locale:const Locale('ko','KR'),
      supportedLocales:const [Locale('ko','KR')],
      localizationsDelegates:const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme:ThemeData(useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:scheme.surface,
        appBarTheme:const AppBarTheme(scrolledUnderElevation:0)),
      home:MainShell(store:store));
  });
}

class MainShell extends StatefulWidget {
  const MainShell({super.key,required this.store});
  final PlannerStore store;
  @override State<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int selected=0;
  int resumeTick=0;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);widget.store.addListener(syncLock);syncLock();}
  @override void dispose(){widget.store.removeListener(syncLock);WidgetsBinding.instance.removeObserver(this);super.dispose();}
  Future<void> reloadAfterLock() async {
    try {
      await LockSurface.flushOverlay();
      await widget.store.flush();
      await widget.store.load();
      if(mounted){syncLock();setState(()=>resumeTick++);}
    } catch(error){debugPrint('잠금 기록 동기화 실패: $error');}
  }
  Future<void> openLockPlanner() async {
    try {
      if(LockSurface.supported && await LockSurface.overlayRunning()) {
        await LockSurface.showOverlay();
      } else if(mounted) {setState(()=>selected=4);}
    } catch(_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('설정에서 잠금 플래너 권한과 실행 상태를 확인해주세요.')));
    }
  }
  void syncLock(){LockSurface.sync(widget.store).catchError((Object error){debugPrint('잠금 요약 갱신 실패: $error');});}
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed && mounted){reloadAfterLock();}
  }
  @override Widget build(BuildContext context){
    final store=widget.store;
    final pages=<Widget>[
      TodayScreen(key:ValueKey('today-$resumeTick'),store:store,openGoals:()=>setState(()=>selected=2),
        openCalendar:()=>setState(()=>selected=1),openNotes:()=>setState(()=>selected=3),
        openPreview:openLockPlanner),
      CalendarScreen(store:store),GoalsScreen(store:store),NotesScreen(store:store),SettingsScreen(store:store),
    ];
    return Scaffold(
      appBar:AppBar(title:const Text('DAYFRAME',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.4)),centerTitle:false,
        actions:[if(selected==0)IconButton(onPressed:()=>setState(()=>selected=4),icon:const Icon(Icons.tune_rounded),tooltip:'설정'),const SizedBox(width:10)]),
      body:SafeArea(child:IndexedStack(index:selected,children:pages)),
      bottomNavigationBar:NavigationBar(height:72,selectedIndex:selected,
        onDestinationSelected:(index)=>setState(()=>selected=index),destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'오늘'),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'일정'),
          NavigationDestination(icon:Icon(Icons.flag_outlined),selectedIcon:Icon(Icons.flag_rounded),label:'플랜'),
          NavigationDestination(icon:Icon(Icons.sticky_note_2_outlined),selectedIcon:Icon(Icons.sticky_note_2_rounded),label:'메모'),
          NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings_rounded),label:'설정'),
        ]),
    );
  }
}
