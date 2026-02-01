import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../viewmodels/routines_viewmodel.dart';

class DragDropHabitItem extends ConsumerStatefulWidget {
  final Habit habit;
  final bool isInRoutine;
  final String? routineId;

  const DragDropHabitItem({
    super.key,
    required this.habit,
    this.isInRoutine = false,
    this.routineId,
  });

  @override
  ConsumerState<DragDropHabitItem> createState() => _DragDropHabitItemState();
}

class _DragDropHabitItemState extends ConsumerState<DragDropHabitItem> {
  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconFromString(String iconString) {
    try {
      return IconData(
        int.parse(iconString),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromString(widget.habit.color);
    final icon = _getIconFromString(widget.habit.icon);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale thresholds based on available width.
        // A half-screen card on a 360px phone is ~164px after padding.
        final bool isNarrow = constraints.maxWidth < 180;

        final double iconSize = isNarrow ? 28 : 40;
        final double iconInnerSize = isNarrow ? 14 : 20;
        final double handleSize = isNarrow ? 16 : 18;
        final double gapAfterHandle = isNarrow ? 6 : 8;
        final double gapAfterIcon = isNarrow ? 6 : 10;
        final double cardPadding = isNarrow ? 8 : 12;

        return Draggable<String>(
          data: widget.habit.id,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: constraints.maxWidth,
              child: _buildHabitCard(
                context, color, icon,
                iconSize: iconSize,
                iconInnerSize: iconInnerSize,
                handleSize: handleSize,
                gapAfterHandle: gapAfterHandle,
                gapAfterIcon: gapAfterIcon,
                cardPadding: cardPadding,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildHabitCard(
              context, color, icon,
              iconSize: iconSize,
              iconInnerSize: iconInnerSize,
              handleSize: handleSize,
              gapAfterHandle: gapAfterHandle,
              gapAfterIcon: gapAfterIcon,
              cardPadding: cardPadding,
            ),
          ),
          onDragStarted: () {
            if (!mounted) return;
            ref.read(routinesViewModelProvider.notifier).startDragging(
              widget.habit.id,
              sourceRoutineId: widget.routineId,
            );
          },
          onDragEnd: (details) {
            if (!mounted) return;
            ref.read(routinesViewModelProvider.notifier).stopDragging();
          },
          onDraggableCanceled: (velocity, offset) {
            if (!mounted) return;
            ref.read(routinesViewModelProvider.notifier).stopDragging();
          },
          child: _buildHabitCard(
            context, color, icon,
            iconSize: iconSize,
            iconInnerSize: iconInnerSize,
            handleSize: handleSize,
            gapAfterHandle: gapAfterHandle,
            gapAfterIcon: gapAfterIcon,
            cardPadding: cardPadding,
          ),
        );
      },
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    Color color,
    IconData icon, {
    required double iconSize,
    required double iconInnerSize,
    required double handleSize,
    required double gapAfterHandle,
    required double gapAfterIcon,
    required double cardPadding,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          // mainAxisSize.max so Expanded text column fills all remaining
          // space and text truncates at exactly the right point instead
          // of the Row collapsing to intrinsic width.
          mainAxisSize: MainAxisSize.max,
          children: [
            // Drag handle
            Padding(
              padding: EdgeInsets.only(right: gapAfterHandle),
              child: Icon(
                Icons.drag_handle,
                color: Colors.grey.shade400,
                size: handleSize,
              ),
            ),

            // Habit icon circle
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconSize * 0.25),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: iconInnerSize,
                  ),
                ),
              ),
            ),

            SizedBox(width: gapAfterIcon),

            // Text — fills remaining width, truncates cleanly
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.habit.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.habit.description != null &&
                      widget.habit.description!.isNotEmpty)
                    Text(
                      widget.habit.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Remove button — only inside a routine
            if (widget.isInRoutine && widget.routineId != null)
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _removeFromRoutine(context, widget.routineId!);
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
        content: Text('Remove "${widget.habit.name}" from this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                ref
                    .read(routinesViewModelProvider.notifier)
                    .removeHabitFromRoutine(
                      routineId: routineId,
                      habitId: widget.habit.id,
                    );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}