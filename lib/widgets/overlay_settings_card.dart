import 'package:flutter/material.dart';
import '../core/lock_surface.dart';

class OverlaySettingsCard extends StatefulWidget {
  const OverlaySettingsCard({super.key});
  @override
  State<OverlaySettingsCard> createState() => _OverlaySettingsCardState();
}

class _OverlaySettingsCardState extends State<OverlaySettingsCard>
    with WidgetsBindingObserver {
  bool permission = false, running = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    if (!LockSurface.supported) return;
    try {
      final allowed = await LockSurface.overlayPermission();
      final active = await LockSurface.overlayRunning();
      final status = await LockSurface.displayStatus();
      if (mounted) {
        setState(() {
          permission = allowed;
          running = active;
          error = status == 'blocked'
              ? '자동 표시가 제한되었습니다. 알림의 열기를 이용해주세요.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '표시 상태를 확인할 수 없습니다.');
    }
  }

  Future<void> act(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = '표시 권한을 확인한 뒤 다시 켜주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        SwitchListTile(
          title: const Text('잠금화면 사용'),
          subtitle: Text(running ? '켜짐' : '꺼짐'),
          value: running,
          onChanged: busy || !LockSurface.supported || (!permission && !running)
              ? null
              : (_) => act(
                  running ? LockSurface.stopOverlay : LockSurface.startOverlay,
                ),
        ),
        if (!permission)
          TextButton(
            onPressed: busy || !LockSurface.supported
                ? null
                : () => act(LockSurface.requestOverlayPermission),
            child: const Text('표시 권한 허용'),
          ),
        if (running)
          TextButton(
            onPressed: busy ? null : () => act(LockSurface.showOverlay),
            child: const Text('화면 열기'),
          ),
        if (error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
      ],
    ),
  );
}
