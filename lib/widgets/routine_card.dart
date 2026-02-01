import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';
import '../models/habit.dart';
import '../viewmodels/routines_viewmodel.dart';
import 'drag_drop_habit_item.dart';

class RoutineCard extends StatefulWidget {
  final Routine routine;
  final List<Habit> habits;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.habits,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  bool _showMenu = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDragOver = false;

  void _toggleMenu() {
    if (_showMenu) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showMenu = true;
    });
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _showMenu = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Stack(
          children: [
            Positioned(
              width: 192,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(size.width - 192, 48),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuButton(
                          icon: '✏️',
                          label: 'Edit Routine',
                          onTap: () {
                            _closeMenu();
                            widget.onEdit();
                          },
                        ),
                        _MenuButton(
                          icon: '🗑️',
                          label: 'Delete Routine',
                          onTap: () {
                            _closeMenu();
                            widget.onDelete();
                          },
                          isDestructive: true,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoutineTypeDisplay() {
    if (widget.routine.type == RoutineType.custom &&
        widget.routine.customTimeText != null &&
        widget.routine.customTimeText!.isNotEmpty) {
      return widget.routine.customTimeText!;
    }
    return widget.routine.type.displayName;
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(routinesViewModelProvider);
        final isDragTarget =
            state.routineDragTargets[widget.routine.id] ?? false;

        return DragTarget<String>(
          onAccept: (habitId) {
            ref
                .read(routinesViewModelProvider.notifier)
                .transferHabitToRoutine(
                  targetRoutineId: widget.routine.id,
                  habitId: habitId,
                );
            setState(() => _isDragOver = false);
          },
          onWillAcceptWithDetails: (data) {
            final isAlreadyInRoutine = widget.habits.any((h) => h.id == data);
            final state = ref.read(routinesViewModelProvider);
            final isSameRoutine = state.sourceRoutineId == widget.routine.id;
            return !isAlreadyInRoutine && !isSameRoutine;
          },
          onLeave: (data) {
            setState(() => _isDragOver = false);
            ref
                .read(routinesViewModelProvider.notifier)
                .setDragTarget(widget.routine.id, false);
          },
          onMove: (details) {
            setState(() => _isDragOver = true);
            ref
                .read(routinesViewModelProvider.notifier)
                .setDragTarget(widget.routine.id, true);
          },
          builder: (context, candidateData, rejectedData) {
            return CompositedTransformTarget(
              link: _layerLink,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isDragOver || isDragTarget
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : widget.routine.active
                      ? theme.colorScheme.surface
                      : theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDragOver || isDragTarget
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: _isDragOver || isDragTarget ? 2 : 1,
                  ),
                  boxShadow: _isDragOver || isDragTarget
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: widget.routine.active ? 1.0 : 0.75,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isNarrow = constraints.maxWidth < 180;

                        final titleStyle = (isNarrow
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.bold);

                        final double smallGap = isNarrow ? 6.0 : 10.0;
                        final double sectionGap = isNarrow ? 10.0 : 14.0;

                        final double dropZoneHeight = isNarrow ? 80.0 : 110.0;
                        final double dropIconSize = isNarrow ? 28.0 : 36.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.routine.name,
                                        style: titleStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: smallGap),
                                      Text(
                                        _getRoutineTypeDisplay(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleMenu,
                                  icon: const Icon(Icons.more_vert),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 40),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sectionGap),
                            if (widget.habits.isEmpty)
                              Container(
                                height: dropZoneHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.1),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: dropIconSize,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
                                    SizedBox(height: isNarrow ? 4 : 8),
                                    Text(
                                      'Drop habits here',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.habits.length,
                                itemBuilder: (context, index) {
                                  final habit = widget.habits[index];
                                  return DragDropHabitItem(
                                    habit: habit,
                                    isInRoutine: true,
                                    routineId: widget.routine.id,
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLast;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isLast = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDestructive
                    ? Colors.red.shade50
                    : theme.colorScheme.surfaceContainerHighest)
                : Colors.transparent,
            borderRadius: widget.isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : null,
          ),
          child: Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDestructive
                      ? Colors.red.shade600
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
