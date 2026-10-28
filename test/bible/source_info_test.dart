import 'package:dayframe/core/bible/content.dart';
import 'package:dayframe/core/store.dart';
import 'package:dayframe/screens/bible_journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_support.dart';

void main() {
  testWidgets('source information opens and closes without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PlannerStore(memoryPreferences());
    store.bibleContent = (await tester.runAsync(BibleContent.load))!;
    await tester.pumpWidget(
      MaterialApp(home: BibleJournalScreen(store: store)),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('bible-reader')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('본문 안내'),
      300,
      scrollable: scrollable,
    );
    await tester.tap(find.text('본문 안내'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('개역개정 본문을 오프라인으로 제공합니다. 합절은 묶어서 표시합니다.'),
      100,
      scrollable: scrollable,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('본문 안내'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('본문 안내'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘의 말씀'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
