import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/store.dart';
import '../widgets/planner_board.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) =>
      PlannerBoard(store: store, onClose: SystemNavigator.pop);
}
