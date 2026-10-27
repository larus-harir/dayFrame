import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/store.dart';
import 'core/app_theme.dart';
import 'widgets/planner_board.dart';

@pragma('vm:entry-point')
Future<void> lockOverlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final store = PlannerStore(SharedPreferencesAsync());
  try {
    await store.load();
    runApp(LockOverlayApp(store: store));
    await const MethodChannel(
      'dev.dayframe/overlay',
    ).invokeMethod<void>('ready');
  } catch (_) {
    await const MethodChannel(
      'dev.dayframe/overlay',
    ).invokeMethod<void>('loadError');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('저장 데이터 확인이 필요합니다. 잠금을 해제하고 앱을 열어주세요.')),
        ),
      ),
    );
  }
}

class LockOverlayApp extends StatefulWidget {
  const LockOverlayApp({super.key, required this.store});
  final PlannerStore store;
  @override
  State<LockOverlayApp> createState() => _LockOverlayAppState();
}

class _LockOverlayAppState extends State<LockOverlayApp> {
  static const channel = MethodChannel('dev.dayframe/overlay');
  Timer? midnight;
  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((call) async {
      if (call.method == 'reload') {
        await widget.store.flush();
        await widget.store.load();
      }
      if (call.method == 'flush') await widget.store.flush();
    });
    widget.store.addListener(syncAppearance);
    syncAppearance();
    scheduleDateRefresh();
  }

  void syncAppearance() {
    channel
        .invokeMethod<void>('appearance', {
          'dark': widget.store.display.darkMode,
        })
        .catchError((Object error) {
          debugPrint('시스템 바 갱신 실패: $error');
        });
  }

  void scheduleDateRefresh() {
    final now = DateTime.now();
    midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () async {
        await widget.store.flush();
        await widget.store.load();
        if (mounted) {
          setState(() {});
          scheduleDateRefresh();
        }
      },
    );
  }

  @override
  void dispose() {
    widget.store.removeListener(syncAppearance);
    midnight?.cancel();
    channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: plannerTheme(store.display.darkMode),
        builder: systemBarRegion,
        home: Scaffold(
          body: SafeArea(
            child: PlannerBoard(
              store: store,
              locked: true,
              onClose: () async {
                await store.flush();
                await channel.invokeMethod<void>('hide');
              },
            ),
          ),
        ),
      );
    },
  );
}
