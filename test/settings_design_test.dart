import 'package:dayframe/core/app_theme.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/lock_overlay.dart';
import 'package:dayframe/screens/display_layout_screen.dart';
import 'package:dayframe/screens/settings_screen.dart';
import 'package:dayframe/widgets/planner_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'one settings entry combines visibility and ordering and preserves hidden positions',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = memoryPreferences();
      final store = PlannerStore(prefs);
      await tester.pumpWidget(
        MaterialApp(
          theme: plannerTheme(false),
          home: Scaffold(
            appBar: AppBar(title: const Text('설정')),
            body: SettingsScreen(store: store),
          ),
        ),
      );
      expect(find.text('표시 항목·순서'), findsOneWidget);
      expect(find.text('표시 항목'), findsNothing);
      expect(find.text('화면 순서'), findsNothing);
      await tester.tap(find.text('표시 항목·순서'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('show-bible')));
      await tester.pumpAndSettle();
      expect(store.display.bible, isFalse);
      expect(store.display.sectionOrder.first, 'bible');
      final handle = find.descendant(
        of: find.byKey(const ValueKey('order-bible')),
        matching: find.byType(ReorderableDragStartListener),
      );
      final target = tester.getBottomRight(
        find.byKey(const ValueKey('order-goals')),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.moveTo(Offset(tester.getCenter(handle).dx, target.dy - 8));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(store.display.sectionOrder, [
        'calendar-memo',
        'tasks',
        'bible',
        'goals',
      ]);
      await tester.tap(find.byKey(const ValueKey('show-bible')));
      await tester.pumpAndSettle();
      expect(store.display.bible, isTrue);
      expect(store.display.sectionOrder[2], 'bible');
      await tester.tap(find.byKey(const Key('show-events')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-notes')));
      await tester.pumpAndSettle();
      expect(store.display.events, isFalse);
      expect(store.display.notes, isFalse);
      await store.flush();
      final loaded = PlannerStore(prefs);
      await tester.runAsync(loaded.load);
      expect(loaded.display.sectionOrder, store.display.sectionOrder);
      expect(loaded.display.bible, isTrue);
      expect(loaded.display.events, isFalse);
      expect(loaded.display.notes, isFalse);
      await tester.pumpWidget(LockOverlayApp(store: loaded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('board-memo')), findsNothing);
      expect(find.byKey(const Key('board-calendar')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      loaded.dispose();
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'settings and layout remain usable at 320px with large text, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PlannerStore(memoryPreferences());
        Widget host(Widget child) => MaterialApp(
          theme: plannerTheme(dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: child,
        );
        await tester.pumpWidget(
          host(
            Scaffold(
              appBar: AppBar(title: const Text('설정')),
              body: SettingsScreen(store: store),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ColoredBox>(find.byKey(const Key('settings-surface')))
              .color,
          plannerTheme(dark).colorScheme.surfaceContainerLow,
        );
        await tester.scrollUntilVisible(find.text('잠금화면에서 작성 허용'), 200);
        await tester.pumpAndSettle();
        await tester.tap(find.text('잠금화면에서 작성 허용'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('일정 등록·수정'), 150);
        await tester.pumpAndSettle();
        await tester.tap(find.text('일정 등록·수정'));
        await tester.pumpAndSettle();
        expect(store.display.lockCreateEvent, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(host(DisplayLayoutScreen(store: store)));
        await tester.pumpAndSettle();
        for (final key in ['show-events', 'show-notes', 'show-goals']) {
          await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 160);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
        }
        expect(store.display.events, isFalse);
        expect(store.display.notes, isFalse);
        expect(store.display.goals, isFalse);
        final hidden = List.of(store.display.sectionOrder);
        await tester.tap(find.byTooltip('순서 초기화'));
        await tester.pumpAndSettle();
        expect(store.display.sectionOrder, hidden);
        expect(store.display.goals, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          host(
            Scaffold(
              body: PlannerBoard(store: store, onClose: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await store.flush();
        store.dispose();
      },
    );
  }
}
