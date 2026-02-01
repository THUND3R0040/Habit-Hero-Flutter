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
