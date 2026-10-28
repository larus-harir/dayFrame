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
          error = switch (status) {
            'blocked' => '자동 실행이 완료되지 않았습니다. 알림의 열기 또는 아래 화면 열기를 눌러 확인해주세요.',
            'engine_error' => '잠금화면 데이터를 읽지 못했습니다. 앱의 기록을 확인해주세요.',
            'permission_missing' => '다른 앱 위에 표시 권한이 해제되었습니다.',
            'not_locked' => '화면 켜짐은 감지했지만 잠금 상태가 아니어서 자동 표시를 건너뛰었습니다.',
            'starting' => '잠금화면을 준비하고 있습니다.',
            _ => null,
          };
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: .65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.lock_outline,
              color: scheme.onSecondaryContainer,
            ),
            title: const Text('잠금화면 사용'),
            subtitle: Text(
              !permission
                  ? '표시 권한이 필요해요'
                  : running
                  ? '사용 중'
                  : '사용 안 함',
            ),
            value: running,
            onChanged:
                busy || !LockSurface.supported || (!permission && !running)
                ? null
                : (_) => act(
                    running
                        ? LockSurface.stopOverlay
                        : LockSurface.startOverlay,
                  ),
          ),
          if (!permission || running)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!permission)
                    FilledButton.tonalIcon(
                      onPressed: busy || !LockSurface.supported
                          ? null
                          : () => act(LockSurface.requestOverlayPermission),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('표시 권한 허용'),
                    ),
                  if (running)
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => act(LockSurface.showOverlay),
                      icon: const Icon(Icons.preview_outlined, size: 16),
                      label: const Text('화면 열기'),
                    ),
                ],
              ),
            ),
          if (busy) const LinearProgressIndicator(minHeight: 2),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                error!,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}
