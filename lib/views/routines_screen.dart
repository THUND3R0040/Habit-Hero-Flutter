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
      builder: (context) =>
          EditRoutineDialog(routine: routineWithHabits.routine),
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
      await ref
          .read(routinesViewModelProvider.notifier)
          .toggleActiveRoutine(id);
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

    // KEY FIX: The entire screen is now a single scrollable ListView.
    // This eliminates all the competing Expanded/flex layout that caused
    // overflow on smaller screens. Each section is sized to its content.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.loadRoutines(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routine Builder',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Long press habits to drag them into routines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // Available Habits Section
              if (state.unassignedHabits.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Available Habits (Long press to drag)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${state.unassignedHabits.length} habits available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                // KEY FIX: no Expanded here. The list uses shrinkWrap so it
                // takes exactly the height it needs within the outer ListView.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.unassignedHabits.length,
                    itemBuilder: (context, index) {
                      final habit = state.unassignedHabits[index];
                      return DragDropHabitItem(
                        habit: habit,
                        isInRoutine: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (state.routines.isEmpty) ...[
                // Empty state when no habits exist at all
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No habits available. Create habits first!',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Routines Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: state.routines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No routines yet. Create your first routine!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Text('➕',
                                  style: TextStyle(fontSize: 16)),
                              label: const Text('Create Routine'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Routines (Drop habits here)',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 16),
                          // KEY FIX: replaced GridView with a simple column of
                          // two-column rows. Each RoutineCard is no longer
                          // forced into a fixed aspect ratio — it sizes itself
                          // to its content. This is the main reason cards were
                          // overflowing on emulator screens.
                          for (int i = 0; i < state.routines.length; i += 2) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: RoutineCard(
                                    routine:
                                        state.routines[i].routine,
                                    habits:
                                        state.routines[i].habits,
                                    onDelete: () => _deleteRoutine(
                                      state.routines[i].routine.id,
                                      state.routines[i].routine.name,
                                    ),
                                    onEdit: () => _showEditDialog(
                                        state.routines[i].routine.id),
                                    onToggleActive: () =>
                                        _toggleActiveRoutine(
                                            state.routines[i].routine.id),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: i + 1 < state.routines.length
                                      ? RoutineCard(
                                          routine:
                                              state.routines[i + 1].routine,
                                          habits:
                                              state.routines[i + 1].habits,
                                          onDelete: () => _deleteRoutine(
                                            state.routines[i + 1].routine.id,
                                            state.routines[i + 1].routine.name,
                                          ),
                                          onEdit: () => _showEditDialog(
                                              state.routines[i + 1].routine.id),
                                          onToggleActive: () =>
                                              _toggleActiveRoutine(
                                                  state.routines[i + 1]
                                                      .routine
                                                      .id),
                                        )
                                      // Placeholder to keep the row balanced
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
              ),

              // Create Button (only shown when there are routines)
              if (state.routines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon:
                        const Text('➕', style: TextStyle(fontSize: 16)),
                    label: const Text('Create Routine'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}