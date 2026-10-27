import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'store.dart';

class LockSurface {
  static const _channel = MethodChannel('dev.dayframe/lock_surface');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static Future<void> sync(PlannerStore store) async {
    if (!supported) return;
    await store.flush();
    await _channel.invokeMethod<void>('refresh');
  }

  static Future<bool> overlayPermission() async =>
      supported &&
      (await _channel.invokeMethod<bool>('overlayPermission') ?? false);
  static Future<bool> overlayRunning() async =>
      supported &&
      (await _channel.invokeMethod<bool>('overlayRunning') ?? false);
  static Future<String?> displayStatus() =>
      _channel.invokeMethod<String>('displayStatus');
  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod<void>('requestOverlayPermission');
  static Future<void> showOverlay() =>
      _channel.invokeMethod<void>('showOverlay');
  static Future<void> startOverlay() =>
      _channel.invokeMethod<void>('startOverlay');
  static Future<void> stopOverlay() =>
      _channel.invokeMethod<void>('stopOverlay');
  static Future<void> flushOverlay() async {
    if (supported) await _channel.invokeMethod<void>('flushOverlay');
  }
}
