import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/widgets/editors.dart';
import 'test_support.dart';

void main() {
  Future<PlannerStore> launch(
    WidgetTester tester, {
    String kind = 'event',
  }) async {
    final store = PlannerStore(memoryPreferences());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                switch (kind) {
                  case 'task':
                    editTaskDialog(context, store);
                  case 'note':
                    editNoteDialog(context, store);
                  case 'goal':
                    editGoalDialog(context, store);
                  default:
                    editEventDialog(
                      context,
                      store,
                      initialDate: DateTime(2026, 10, 26),
                    );
                }
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return store;
  }

  for (final kind in ['event', 'task', 'note', 'goal']) {
    testWidgets('$kind cancel preserves store and survives exit animation', (
      tester,
    ) async {
      final store = await launch(tester, kind: kind);
      await tester.enterText(find.byType(TextField).first, 'draft');
      await tester.tap(find.text('취소'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(store.events, isEmpty);
      expect(store.tasks, isEmpty);
      expect(store.notes, isEmpty);
      expect(store.goals, isEmpty);
      store.dispose();
    });
  }
  testWidgets('barrier and system back dismiss without saving', (tester) async {
    final store = await launch(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    expect(store.events, isEmpty);
    store.dispose();
  });
  testWidgets('picker cancel leaves event open, then saves once', (
    tester,
  ) async {
    final store = await launch(tester);
    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'appointment');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.events.single.title, 'appointment');
    expect(store.events.single.date, '2026-10-26');
    await store.flush();
    store.dispose();
  });
  testWidgets(
    'removing host while picker open does not update disposed state',
    (tester) async {
      final store = await launch(tester);
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(store.events, isEmpty);
      store.dispose();
    },
  );
}
