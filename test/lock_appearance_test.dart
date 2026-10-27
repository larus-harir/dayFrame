import 'package:dayframe/core/store.dart';
import 'package:dayframe/lock_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  testWidgets('lock window receives the visible surface on theme changes', (
    tester,
  ) async {
    final store = PlannerStore(memoryPreferences());
    const channel = MethodChannel('dev.dayframe/overlay');
    final appearances = <Map<dynamic, dynamic>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'appearance') appearances.add(call.arguments as Map);
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      store.dispose();
    });
    await tester.pumpWidget(LockOverlayApp(store: store));
    await tester.pumpAndSettle();
    for (final dark in [false, true, false]) {
      store.updateDisplay((display) => display.darkMode = dark);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .byWidgetPredicate(
              (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
            )
            .first,
      );
      expect(
        appearances.last['surfaceColor'],
        theme.scaffoldBackgroundColor.toARGB32(),
      );
      expect(appearances.last['dark'], dark);
      expect(
        region.value.statusBarIconBrightness,
        dark ? Brightness.light : Brightness.dark,
      );
      expect(
        region.value.systemNavigationBarIconBrightness,
        dark ? Brightness.light : Brightness.dark,
      );
    }
    await store.flush();
    await tester.pumpWidget(const SizedBox());
  });
}
