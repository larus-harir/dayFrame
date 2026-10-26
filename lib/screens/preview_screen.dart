import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/lock_summary.dart';
import '../core/store.dart';

/// Compact app preview; Android uses a separate native, read-only Activity.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final now = DateTime.now();
      final summary = lockSummary(store, now);
      return Scaffold(
        appBar: AppBar(title: const Text('DAYFRAME · 요약 프리뷰'), actions: [
          IconButton(tooltip: '닫기', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('${formatDateFull(now)} · ${formatTime(now.hour, now.minute)}', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          for (final entry in summary.entries) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.key, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(entry.value, maxLines: 3, overflow: TextOverflow.ellipsis),
            ]),
          )),
          if (summary.isEmpty) const Text('설정에서 표시할 항목을 선택하세요.'),
          const SizedBox(height: 8),
          const Text('앱 내부 프리뷰입니다. 상세 편집과 완료 체크는 오늘 화면에서 진행하세요.'),
        ])),
      );
    },
  );
}
