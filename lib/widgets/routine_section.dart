import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../viewmodels/today_viewmodel.dart';
import 'today_habit_item.dart';

class RoutineSection extends StatelessWidget {
  final Routine? routine;
  final List<TodayHabit> habits;
  final Function(String) onToggleHabit;

  const RoutineSection({
    super.key,
    this.routine,
    required this.habits,
    required this.onToggleHabit,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // KEY FIX: mainAxisSize.min so the Column only takes what it needs
      // and doesn't try to expand beyond its parent's bounds
      mainAxisSize: MainAxisSize.min,
      children: [
        if (routine != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              routine!.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        // KEY FIX: wrap the habit list in a ListView so if there are
        // many habits they scroll instead of overflowing, and use
        // shrinkWrap + physics to let it sit inside the parent Column
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final todayHabit = habits[index];
            return TodayHabitItem(
              habit: todayHabit.habit,
              completed: todayHabit.completed,
              onToggle: () => onToggleHabit(todayHabit.habit.id),
            );
          },
        ),
      ],
    );
  }
}