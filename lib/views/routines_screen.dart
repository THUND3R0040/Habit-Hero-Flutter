import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/routines_viewmodel.dart';
import '../widgets/habit_card.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  final _routineNameController = TextEditingController();

  @override
  void dispose() {
    _routineNameController.dispose();
    super.dispose();
  }

  void _showCreateRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Routine'),
        content: TextField(
          controller: _routineNameController,
          decoration: const InputDecoration(
            labelText: 'Routine Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _routineNameController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _routineNameController.text.trim();
              if (name.isNotEmpty) {
                _routineNameController.clear();
                Navigator.of(context).pop();
                await ref
                    .read(routinesViewModelProvider.notifier)
                    .createRoutine(name: name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(String routineId) {
    final state = ref.read(routinesViewModelProvider);
    final availableHabits = state.allHabits.where((habit) {
      return !state.routines.any((routine) =>
          routine.routine.id == routineId &&
          routine.habits.any((h) => h.id == habit.id));
    }).toList();

    if (availableHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available habits to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Habit to Routine'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableHabits.length,
            itemBuilder: (context, index) {
              final habit = availableHabits[index];
              return ListTile(
                title: Text(habit.name),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(routinesViewModelProvider.notifier)
                      .addHabitToRoutine(
                        routineId: routineId,
                        habitId: habit.id,
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routinesViewModelProvider);
    final viewModel = ref.read(routinesViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routines')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => viewModel.loadRoutines(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateRoutineDialog,
          ),
        ],
      ),
      body: state.routines.isEmpty
          ? const Center(
              child: Text('No routines yet. Create your first routine!'),
            )
          : RefreshIndicator(
              onRefresh: () => viewModel.loadRoutines(),
              child: ListView.builder(
                itemCount: state.routines.length,
                itemBuilder: (context, index) {
                  final routineWithHabits = state.routines[index];
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: ExpansionTile(
                      leading: Switch(
                        value: routineWithHabits.routine.active,
                        onChanged: (value) async {
                          await viewModel.updateRoutine(
                            id: routineWithHabits.routine.id,
                            active: value,
                          );
                        },
                      ),
                      title: Text(routineWithHabits.routine.name),
                      subtitle: Text(
                          '${routineWithHabits.habits.length} habits'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Routine'),
                              content: Text(
                                  'Are you sure you want to delete "${routineWithHabits.routine.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await viewModel.deleteRoutine(
                                        routineWithHabits.routine.id);
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
                      ),
                      children: [
                        ...routineWithHabits.habits.map((habit) {
                          return ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(habit.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () async {
                                await viewModel.removeHabitFromRoutine(
                                  routineId: routineWithHabits.routine.id,
                                  habitId: habit.id,
                                );
                              },
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Habit'),
                          onTap: () =>
                              _showAddHabitDialog(routineWithHabits.routine.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

