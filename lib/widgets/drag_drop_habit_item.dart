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

  void _showHabitDetailPopup() {
    final color = _getColorFromString(widget.habit.color);
    final icon = _getIconFromString(widget.habit.icon);
    
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Habit Details'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Habit Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                // Habit Name
                Text(
                  widget.habit.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Habit Description
                if (widget.habit.description != null && widget.habit.description!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.habit.description!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    'No description provided.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 40),
                // Info Rows
                _buildInfoRow(
                  context,
                  Icons.calendar_today_outlined,
                  'Frequency',
                  'Daily',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromString(widget.habit.color);
    final icon = _getIconFromString(widget.habit.icon);

    return LayoutBuilder(
      builder: (context, constraints) {
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
      child: InkWell(
        onTap: _showHabitDetailPopup,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsets.only(right: gapAfterHandle),
                child: Icon(
                  Icons.drag_handle,
                  color: Colors.grey.shade400,
                  size: handleSize,
                ),
              ),

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
