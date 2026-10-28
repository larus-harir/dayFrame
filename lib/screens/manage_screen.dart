import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/format.dart';
import '../widgets/common.dart';
import '../widgets/editors.dart';
import 'bible_journal_screen.dart';
import 'calendar_screen.dart';
import 'goals_screen.dart';
import 'notes_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _link(
        context,
        '일정',
        Icons.calendar_month,
        () => CalendarScreen(store: store),
      ),
      _link(
        context,
        '체크리스트',
        Icons.checklist,
        () => _TaskManager(store: store),
      ),
      _link(context, '메모', Icons.notes, () => NotesScreen(store: store)),
      _link(
        context,
        '장기 목표',
        Icons.flag_outlined,
        () => GoalsScreen(store: store),
      ),
      ListTile(
        leading: const Icon(Icons.menu_book),
        title: const Text('성경 기록'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BibleJournalScreen(store: store),
          ),
        ),
      ),
    ],
  );
  Widget _link(
    BuildContext context,
    String title,
    IconData icon,
    Widget Function() page,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: AnimatedBuilder(animation: store, builder: (_, _) => page()),
          ),
        ),
      ),
    ),
  );
}

class _TaskManager extends StatelessWidget {
  const _TaskManager({required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => editTaskDialog(context, store),
          icon: const Icon(Icons.add),
          label: const Text('추가'),
        ),
      ),
      for (final task in store.tasks)
        ListTile(
          title: Text(task.title),
          subtitle: Text(
            task.days.map((day) => koreanWeekdays[day - 1]).join(' · '),
          ),
          onTap: () => editTaskDialog(context, store, task: task),
          trailing: IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDelete(context, task.title)) {
                store.deleteTask(task);
              }
            },
          ),
        ),
      if (store.tasks.isEmpty) const Text('등록된 항목이 없습니다.'),
    ],
  );
}
