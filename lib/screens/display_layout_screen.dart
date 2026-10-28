import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';

class DisplayLayoutScreen extends StatelessWidget {
  const DisplayLayoutScreen({super.key, required this.store});
  final PlannerStore store;
  static const labels = {
    'bible': '성경',
    'calendar-memo': '캘린더·메모',
    'tasks': '체크리스트',
    'goals': '장기 플랜',
  };
  static const icons = {
    'bible': Icons.menu_book_outlined,
    'calendar-memo': Icons.calendar_month_outlined,
    'tasks': Icons.checklist_rounded,
    'goals': Icons.flag_outlined,
  };

  bool visible(String id) => switch (id) {
    'bible' => store.display.bible,
    'tasks' => store.display.tasks,
    'goals' => store.display.goals,
    _ => true,
  };

  void setVisible(String id, bool value) => store.updateDisplay((p) {
    switch (id) {
      case 'bible':
        p.bible = value;
      case 'tasks':
        p.tasks = value;
      case 'goals':
        p.goals = value;
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('표시 항목·순서'),
      actions: [
        IconButton(
          tooltip: '순서 초기화',
          onPressed: () => store.updateDisplay(
            (p) => p.sectionOrder = List.of(
              DisplayPreferences.defaultSectionOrder,
            ),
          ),
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          header: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '표시 여부를 고르고, 손잡이를 끌어 순서를 바꾸세요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          buildDefaultDragHandles: false,
          itemCount: store.display.sectionOrder.length,
          onReorderItem: (oldIndex, newIndex) => store.updateDisplay((p) {
            final items = List.of(p.sectionOrder);
            items.insert(newIndex, items.removeAt(oldIndex));
            p.sectionOrder = items;
          }),
          proxyDecorator: (child, _, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Material(
              color: Colors.transparent,
              elevation: 4 * animation.value,
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
          itemBuilder: (context, index) {
            final id = store.display.sectionOrder[index];
            final enabled = visible(id);
            return Card.outlined(
              key: ValueKey('order-$id'),
              margin: const EdgeInsets.only(bottom: 12),
              color: enabled ? scheme.surface : scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .6),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    leading: Icon(
                      icons[id],
                      color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    title: Text(labels[id]!),
                    subtitle: id == 'calendar-memo'
                        ? const Text('달력과 메모는 함께 이동해요')
                        : Text(enabled ? '표시' : '숨김'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (id != 'calendar-memo')
                          Semantics(
                            label: '${labels[id]} 표시',
                            child: Switch(
                              key: ValueKey('show-$id'),
                              value: enabled,
                              onChanged: (value) => setVisible(id, value),
                            ),
                          ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Semantics(
                            label: '${labels[id]} 순서 변경',
                            child: const SizedBox(
                              width: 48,
                              height: 56,
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (id == 'calendar-memo') ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      key: const Key('show-events'),
                      contentPadding: const EdgeInsets.only(
                        left: 56,
                        right: 16,
                      ),
                      title: const Text('일정 표시'),
                      value: store.display.events,
                      onChanged: (value) =>
                          store.updateDisplay((p) => p.events = value),
                    ),
                    SwitchListTile(
                      key: const Key('show-notes'),
                      contentPadding: const EdgeInsets.only(
                        left: 56,
                        right: 16,
                      ),
                      title: const Text('메모 표시'),
                      value: store.display.notes,
                      onChanged: (value) =>
                          store.updateDisplay((p) => p.notes = value),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
