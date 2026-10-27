import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/lock_overlay.dart';
import 'test_support.dart';

void main() {
  testWidgets('service engine starts without an Activity platform handler', (tester) async {
    memoryPreferences();
    final calls = <String>[];
    final platformReply = Completer<Object?>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode') return platformReply.future;
      return null;
    });
    const channel = MethodChannel('dev.dayframe/overlay');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    var completed = false;
    unawaited(lockOverlayMain().then((_) => completed = true));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(calls, contains('ready'));
    expect(calls, isNot(contains('loadError')));
    expect(find.byKey(const Key('planner-board')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
