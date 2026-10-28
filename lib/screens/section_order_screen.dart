import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';

class SectionOrderScreen extends StatelessWidget {
  const SectionOrderScreen({super.key, required this.store});
  final PlannerStore store;
  static const labels = {
    'bible': '성경',
    'calendar-memo': '캘린더·메모',
    'tasks': '체크리스트',
    'goals': '장기 플랜',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('화면 순서'),
      actions: [
        TextButton(
          onPressed: () => store.updateDisplay(
            (p) => p.sectionOrder = List.of(
              DisplayPreferences.defaultSectionOrder,
            ),
          ),
          child: const Text('초기화'),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('손잡이를 끌어 순서를 바꿔주세요.\n캘린더·메모는 함께 이동하며 메인과 잠금화면에 적용됩니다.'),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: store.display.sectionOrder.length,
              onReorderItem: (oldIndex, newIndex) => store.updateDisplay((p) {
                final items = List.of(p.sectionOrder);
                items.insert(newIndex, items.removeAt(oldIndex));
                p.sectionOrder = items;
              }),
              itemBuilder: (context, index) {
                final id = store.display.sectionOrder[index];
                return ListTile(
                  key: ValueKey('order-$id'),
                  title: Text(labels[id]!),
                  leading: Text('${index + 1}'),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
