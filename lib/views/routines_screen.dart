import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/routines_viewmodel.dart';
import '../widgets/routine_card.dart';
import '../widgets/add_routine_dialog.dart';
import '../widgets/edit_routine_dialog.dart';
import '../widgets/drag_drop_habit_item.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddRoutineDialog(),
    );
  }

  void _showEditDialog(String routineId) {
    final state = ref.read(routinesViewModelProvider);
    final routineWithHabits = state.routines.firstWhere(
      (r) => r.routine.id == routineId,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditRoutineDialog(routine: routineWithHabits.routine),
    );
  }

  Future<void> _deleteRoutine(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(routinesViewModelProvider.notifier).deleteRoutine(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete routine: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActiveRoutine(String id) async {
    try {
      await ref.read(routinesViewModelProvider.notifier).toggleActiveRoutine(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle routine: $e')),
        );
      }
    }
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
              const SizedBox(height: 16),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fixed height
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Routine Builder',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Long press habits to drag them into routines',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

            // Available Habits Section - Limited height
            if (state.unassignedHabits.isNotEmpty)
              Container(
                height: 180, // Fixed height to prevent overflow
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Available Habits (${state.unassignedHabits.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.unassignedHabits.length,
                        itemBuilder: (context, index) {
                          final habit = state.unassignedHabits[index];
                          return SizedBox(
                            width: 300, // Fixed width
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: DragDropHabitItem(
                                habit: habit,
                                isInRoutine: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Divider
            if (state.unassignedHabits.isNotEmpty && state.routines.isNotEmpty)
              const Divider(height: 32, thickness: 1),

            // Routines Section - Takes remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: state.routines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No routines yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a routine to start organizing habits',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create Routine'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Your Routines (${state.routines.length})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () => viewModel.loadRoutines(),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: state.routines.length,
                                itemBuilder: (context, index) {
                                  final routineWithHabits = state.routines[index];
                                  final routine = routineWithHabits.routine;
                                  
                                  return RoutineCard(
                                    routine: routine,
                                    habits: routineWithHabits.habits,
                                    onDelete: () => _deleteRoutine(
                                      routine.id,
                                      routine.name,
                                    ),
                                    onEdit: () => _showEditDialog(routine.id),
                                    onToggleActive: () => _toggleActiveRoutine(routine.id),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Create Button - Fixed at bottom
            if (state.routines.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Routine'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}