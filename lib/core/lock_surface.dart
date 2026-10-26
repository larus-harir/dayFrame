import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'lock_summary.dart';
import 'store.dart';

class LockSurface {
  static const _channel = MethodChannel('dev.dayframe/lock_surface');
  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<void> sync(PlannerStore store) async {
    if (!supported) return;
    await _channel.invokeMethod<void>('sync', {
      'enabled': store.display.lockSurfaceEnabled,
      'summary': store.display.lockSurfaceEnabled ? nativeSummary(store, DateTime.now()) : '',
    });
  }
  static Future<void> open(PlannerStore store) async {
    if (!supported) throw UnsupportedError('Android에서만 지원합니다.');
    await sync(store);
    await _channel.invokeMethod<void>('open');
  }
}
