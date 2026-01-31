import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../viewmodels/routines_viewmodel.dart';

class DragDropHabitItem extends ConsumerWidget {
  final Habit habit;
  final bool isInRoutine;
  final String? routineId; // For removing from routine

  const DragDropHabitItem({
    super.key,
    required this.habit,
    this.isInRoutine = false,
    this.routineId,
  });

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconFromString(String iconString) {
    try {
      return IconData(int.parse(iconString), fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getColorFromString(habit.color);
    final icon = _getIconFromString(habit.icon);

    return Draggable<String>(
      data: habit.id,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          child: _buildHabitCard(context, color, icon),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildHabitCard(context, color, icon),
      ),
      onDragStarted: () {
        ref.read(routinesViewModelProvider.notifier).startDragging(habit.id);
      },
      onDragEnd: (details) {
        ref.read(routinesViewModelProvider.notifier).stopDragging();
      },
      onDraggableCanceled: (velocity, offset) {
        ref.read(routinesViewModelProvider.notifier).stopDragging();
      },
      child: GestureDetector(
        onLongPress: () {
          // Optional: Provide haptic feedback
          // HapticFeedback.selectionClick();
        },
        child: _buildHabitCard(context, color, icon),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.drag_handle,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),

            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            // In the _buildHabitCard method, wrap the Column with ConstrainedBox:
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 0, // Allow shrinking
                  maxWidth: double.infinity, // Allow expanding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2, // Limit to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty)
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // Remove button for habits in routines
            if (isInRoutine && routineId != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _removeFromRoutine(context, routineId!);
                },
                tooltip: 'Remove from routine',
              ),
          ],
        ),
      ),
    );
  }

  void _removeFromRoutine(BuildContext context, String routineId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Habit'),
        content: Text('Remove "${habit.name}" from this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performRemove(context, routineId);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _performRemove(BuildContext context, String routineId) {
    final ref = ProviderScope.containerOf(context);
    ref
        .read(routinesViewModelProvider.notifier)
        .removeHabitFromRoutine(routineId: routineId, habitId: habit.id);
  }
}
