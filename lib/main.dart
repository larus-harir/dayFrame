import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/store.dart';
import 'core/lock_surface.dart';
export 'lock_overlay.dart' show lockOverlayMain;
import 'screens/manage_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final store = PlannerStore(SharedPreferencesAsync());
  try {
    await store.load(startBibleSession: true);
    runApp(DayframeApp(store: store));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '저장된 데이터를 읽을 수 없습니다.\n앱 데이터를 백업한 뒤 확인해주세요.\n\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DayframeApp extends StatelessWidget {
  const DayframeApp({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      return MaterialApp(
        title: 'DAYFRAME',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: plannerTheme(store.display.darkMode),
        builder: systemBarRegion,
        home: MainShell(store: store),
      );
    },
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final PlannerStore store;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int resumeTick = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(syncLock);
    syncLock();
  }

  @override
  void dispose() {
    widget.store.removeListener(syncLock);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> reloadAfterLock() async {
    try {
      await LockSurface.flushOverlay();
      await widget.store.flush();
      await widget.store.load(startBibleSession: true);
      if (mounted) {
        syncLock();
        setState(() => resumeTick++);
      }
    } catch (error) {
      debugPrint('기록 동기화 실패: $error');
    }
  }

  void syncLock() {
    LockSurface.sync(widget.store).catchError((Object error) {
      debugPrint('화면 갱신 실패: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) reloadAfterLock();
  }

  void openPage(String title, WidgetBuilder page) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.store,
            builder: (context, _) => page(context),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DAYFRAME'),
      actions: [
        IconButton(
          tooltip: '관리',
          icon: const Icon(Icons.edit_note),
          onPressed: () =>
              openPage('관리', (_) => ManageScreen(store: widget.store)),
        ),
        IconButton(
          tooltip: '설정',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () =>
              openPage('설정', (_) => SettingsScreen(store: widget.store)),
        ),
      ],
    ),
    body: SafeArea(
      child: TodayScreen(key: ValueKey(resumeTick), store: widget.store),
    ),
  );
}
