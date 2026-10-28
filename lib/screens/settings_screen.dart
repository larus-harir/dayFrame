import 'package:flutter/material.dart';
import '../core/store.dart';
import '../widgets/overlay_settings_card.dart';
import 'bible_journal_screen.dart';
import 'section_order_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const OverlaySettingsCard(),
        SwitchListTile(
          title: const Text('잠금화면에서 내용 숨기기'),
          subtitle: const Text('체크리스트, 일정, 메모'),
          value: store.display.hidePrivateDetails,
          onChanged: (value) =>
              store.updateDisplay((p) => p.hidePrivateDetails = value),
        ),
        SwitchListTile(
          title: const Text('다크 모드'),
          value: store.display.darkMode,
          onChanged: (value) => store.updateDisplay((p) => p.darkMode = value),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('말씀과 기록'),
          subtitle: Text(
            '${store.hasReadBibleToday ? '오늘 읽기 완료' : '하루 한 절'} · 연속 ${store.bibleReadingStreak}일',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => BibleJournalScreen(store: store),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.reorder),
          title: const Text('화면 순서'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SectionOrderScreen(store: store),
            ),
          ),
        ),
        ExpansionTile(
          title: const Text('잠금화면에서 작성 허용'),
          children: [
            SwitchListTile(
              title: const Text('메모 등록·수정·삭제'),
              value: store.display.lockCreateNote,
              onChanged: (v) =>
                  store.updateDisplay((p) => p.lockCreateNote = v),
            ),
            SwitchListTile(
              title: const Text('일정 등록·수정'),
              value: store.display.lockCreateEvent,
              onChanged: (v) =>
                  store.updateDisplay((p) => p.lockCreateEvent = v),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('표시 항목'),
          children: [
            SwitchListTile(
              title: const Text('성경'),
              value: store.display.bible,
              onChanged: (v) => store.updateDisplay((p) => p.bible = v),
            ),
            SwitchListTile(
              title: const Text('체크리스트'),
              value: store.display.tasks,
              onChanged: (v) => store.updateDisplay((p) => p.tasks = v),
            ),
            SwitchListTile(
              title: const Text('일정'),
              value: store.display.events,
              onChanged: (v) => store.updateDisplay((p) => p.events = v),
            ),
            SwitchListTile(
              title: const Text('장기 플랜'),
              value: store.display.goals,
              onChanged: (v) => store.updateDisplay((p) => p.goals = v),
            ),
            SwitchListTile(
              title: const Text('메모'),
              value: store.display.notes,
              onChanged: (v) => store.updateDisplay((p) => p.notes = v),
            ),
          ],
        ),
      ],
    ),
  );
}
