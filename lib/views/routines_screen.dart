import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/routines_viewmodel.dart';
import '../widgets/routine_card.dart';
import '../widgets/add_routine_dialog.dart';
import '../widgets/edit_routine_dialog.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Routine Builder',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Group habits into focused routines',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Routines Grid
              Expanded(
                child: state.routines.isEmpty
                    ? const Center(
                        child: Text(
                          'No routines yet. Create your first routine!',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          if (constraints.maxWidth > 1024) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth > 768) {
                            crossAxisCount = 2;
                          }

                          return RefreshIndicator(
                            onRefresh: () => viewModel.loadRoutines(),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: state.routines.length,
                              itemBuilder: (context, index) {
                                final routineWithHabits = state.routines[index];
                                final routine = routineWithHabits.routine;
                                
                                return RoutineCard(
                                  routine: routine,
                                  onDelete: () => _deleteRoutine(
                                    routine.id,
                                    routine.name,
                                  ),
                                  onEdit: () => _showEditDialog(routine.id),
                                  onToggleActive: () => _toggleActiveRoutine(routine.id),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              // Create Button
              FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Text('➕', style: TextStyle(fontSize: 16)),
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
        ),
      ),
    );
  }
}