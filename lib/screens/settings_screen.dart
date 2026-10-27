import 'package:flutter/material.dart';
import '../core/store.dart';
import '../widgets/overlay_settings_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => ListView(
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
            title: const Text('메모'),
            value: store.display.notes,
            onChanged: (v) => store.updateDisplay((p) => p.notes = v),
          ),
        ],
      ),
    ],
  );
}
