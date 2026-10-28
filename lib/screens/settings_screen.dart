import 'package:flutter/material.dart';
import '../core/store.dart';
import '../widgets/overlay_settings_card.dart';
import 'bible_journal_screen.dart';
import 'display_layout_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final PlannerStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Theme(
        data: theme.copyWith(
          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: scheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: .45),
              ),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          dividerTheme: DividerThemeData(
            color: scheme.outlineVariant.withValues(alpha: .45),
            space: 1,
            thickness: 1,
          ),
        ),
        child: ColoredBox(
          key: const Key('settings-surface'),
          color: scheme.surfaceContainerLow,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const OverlaySettingsCard(),
              const _SectionLabel('화면 구성'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.dashboard_customize_outlined,
                        color: scheme.primary,
                      ),
                      title: const Text('표시 항목·순서'),
                      subtitle: const Text('보일 항목과 배치를 한 곳에서'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DisplayLayoutScreen(store: store),
                        ),
                      ),
                    ),
                    const Divider(indent: 56),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('다크 모드'),
                      value: store.display.darkMode,
                      onChanged: (value) =>
                          store.updateDisplay((p) => p.darkMode = value),
                    ),
                  ],
                ),
              ),
              const _SectionLabel('잠금화면'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined),
                      title: const Text('잠금화면에서 내용 숨기기'),
                      subtitle: const Text('일정·메모·체크리스트·장기 플랜'),
                      value: store.display.hidePrivateDetails,
                      onChanged: (value) => store.updateDisplay(
                        (p) => p.hidePrivateDetails = value,
                      ),
                    ),
                    const Divider(indent: 56),
                    ExpansionTile(
                      leading: const Icon(Icons.edit_note_outlined),
                      title: const Text('잠금화면에서 작성 허용'),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      children: [
                        SwitchListTile(
                          title: const Text('메모 등록·수정·삭제'),
                          value: store.display.lockCreateNote,
                          onChanged: (value) => store.updateDisplay(
                            (p) => p.lockCreateNote = value,
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('일정 등록·수정'),
                          value: store.display.lockCreateEvent,
                          onChanged: (value) => store.updateDisplay(
                            (p) => p.lockCreateEvent = value,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const _SectionLabel('기록'),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: scheme.primary,
                  ),
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
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
