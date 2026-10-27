import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/store.dart';
import 'widgets/planner_board.dart';

@pragma('vm:entry-point')
Future<void> lockOverlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PlannerStore(SharedPreferencesAsync());
  try {
    await store.load();
    runApp(LockOverlayApp(store: store));
  } catch (_) {
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
    scheduleDateRefresh();
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
        theme: ThemeData(
          useMaterial3: true,
          brightness: store.display.darkMode
              ? Brightness.dark
              : Brightness.light,
          colorSchemeSeed: const Color(0xFF58796C),
        ),
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
