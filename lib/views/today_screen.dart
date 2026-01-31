import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/today_viewmodel.dart';
import '../widgets/today_habit_item.dart';
import '../widgets/routine_section.dart';
import 'settings_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayViewModelProvider);
    final viewModel = ref.read(todayViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Today')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => viewModel.loadTodayHabits(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final routines = viewModel.getActiveRoutines();
    final ungroupedHabits = viewModel.getHabitsByRoutine(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadTodayHabits(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadTodayHabits(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.totalCount > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: state.totalCount > 0
                                ? state.completedCount / state.totalCount
                                : 0,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.completedCount} / ${state.totalCount} completed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (routines.isNotEmpty)
                ...routines.map((routine) {
                  final habits = viewModel.getHabitsByRoutine(routine);
                  return RoutineSection(
                    routine: routine,
                    habits: habits,
                    onToggleHabit: (habitId) => viewModel.toggleHabit(habitId),
                  );
                }),
              if (ungroupedHabits.isNotEmpty)
                RoutineSection(
                  routine: null,
                  habits: ungroupedHabits,
                  onToggleHabit: (habitId) => viewModel.toggleHabit(habitId),
                ),
              if (state.habits.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No habits for today'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

