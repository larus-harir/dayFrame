import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'package:dayframe/main.dart';
import 'package:dayframe/core/store.dart';

void main() {
  testWidgets('오늘 화면 및 내비게이션 표시', (tester) async {
    final store = PlannerStore(memoryPreferences());
    await tester.pumpWidget(DayframeApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('DAYFRAME'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);
  });
}
