import 'package:dayframe/widgets/paged_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'checklist and goals overflow without shrinking a fitting monthly calendar',
    (tester) async {
      size(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PagedBoard(
              onClose: () {},
              sections: {
                'bible': const SizedBox(height: 80),
                'calendar-memo': const SizedBox(
                  height: 330,
                  child: Text('월간+메모'),
                ),
                'tasks': const SizedBox(height: 200, child: Text('체크리스트')),
                'goals': const SizedBox(height: 200, child: Text('장기 플랜')),
              },
              compactSections: {
                'calendar-memo': const SizedBox(
                  height: 180,
                  child: Text('주간+메모'),
                ),
              },
              compactTriggers: {'calendar-memo': const SizedBox(height: 250)},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('월간+메모'), findsOneWidget);
      expect(find.text('주간+메모'), findsNothing);
      await tester.tap(find.byTooltip('다음 페이지'));
      await tester.pumpAndSettle();
      expect(find.text('체크리스트'), findsOneWidget);
      expect(find.text('장기 플랜'), findsOneWidget);
    },
  );
  testWidgets('week is used only when the month fits but its memo does not', (
    tester,
  ) async {
    size(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PagedBoard(
            onClose: () {},
            sections: {
              'bible': const SizedBox(height: 80),
              'calendar-memo': const SizedBox(
                height: 480,
                child: Text('월간+메모'),
              ),
            },
            compactSections: {
              'calendar-memo': const SizedBox(
                height: 280,
                child: Text('주간+메모'),
              ),
            },
            compactTriggers: {'calendar-memo': const SizedBox(height: 400)},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('주간+메모'), findsOneWidget);
    expect(find.text('월간+메모'), findsNothing);
  });
  testWidgets(
    'a calendar that cannot fit moves with its memo instead of shrinking into a gap',
    (tester) async {
      size(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PagedBoard(
              onClose: () {},
              sections: {
                'bible': const SizedBox(height: 300, child: Text('성경')),
                'calendar-memo': const SizedBox(
                  height: 330,
                  child: Text('월간+메모'),
                ),
              },
              compactSections: {
                'calendar-memo': const SizedBox(
                  height: 180,
                  child: Text('주간+메모'),
                ),
              },
              compactTriggers: {'calendar-memo': const SizedBox(height: 250)},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('주간+메모'), findsNothing);
      await tester.tap(find.byTooltip('다음 페이지'));
      await tester.pumpAndSettle();
      expect(find.text('월간+메모'), findsOneWidget);
      expect(find.text('주간+메모'), findsNothing);
    },
  );
}
