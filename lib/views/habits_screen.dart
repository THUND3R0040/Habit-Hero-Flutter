import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/habits_viewmodel.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_dialog.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsViewModelProvider);
    final viewModel = ref.read(habitsViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habits')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => viewModel.loadHabits(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => const HabitFormDialog(),
              );

              if (result != null) {
                await viewModel.createHabit(
                  name: result['name'] as String,
                  description: result['description'] as String?,
                  icon: result['icon'] as String,
                  color: result['color'] as String,
                );
              }
            },
          ),
        ],
      ),
      body: state.habits.isEmpty
          ? const Center(
              child: Text('No habits yet. Create your first habit!'),
            )
          : RefreshIndicator(
              onRefresh: () => viewModel.loadHabits(),
              child: ListView.builder(
                itemCount: state.habits.length,
                itemBuilder: (context, index) {
                  final habitWithStats = state.habits[index];
                  return HabitCard(
                    habit: habitWithStats.habit,
                    completionPercentage: habitWithStats.completionPercentage,
                    onTap: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => HabitFormDialog(
                          initialName: habitWithStats.habit.name,
                          initialDescription: habitWithStats.habit.description,
                          initialIcon: habitWithStats.habit.icon,
                          initialColor: habitWithStats.habit.color,
                        ),
                      );

                      if (result != null) {
                        await viewModel.updateHabit(
                          id: habitWithStats.habit.id,
                          name: result['name'] as String,
                          description: result['description'] as String?,
                          icon: result['icon'] as String,
                          color: result['color'] as String,
                        );
                      }
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Habit'),
                          content: Text(
                              'Are you sure you want to delete "${habitWithStats.habit.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await viewModel.deleteHabit(
                                    habitWithStats.habit.id);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

