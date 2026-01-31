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
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
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
            // Use transfer method instead of add method
            ref
                .read(routinesViewModelProvider.notifier)
                .transferHabitToRoutine(
                  targetRoutineId: widget.routine.id,
                  habitId: habitId,
                );
            setState(() => _isDragOver = false);
          },
         onWillAcceptWithDetails: (data) {
  // Check if habit is already in this routine
  // ignore: unrelated_type_equality_checks
  final isAlreadyInRoutine = widget.habits.any((h) => h.id == data);
  // Also check if we're trying to drop on the same routine it came from
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
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and menu button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.routine.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getRoutineTypeDisplay(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  // Active/Inactive Toggle
                                  _ActiveToggle(
                                    isActive: widget.routine.active,
                                    onToggle: widget.onToggleActive,
                                  ),
                                ],
                              ),
                            ),
                            // Three-dot menu button
                            IconButton(
                              onPressed: _toggleMenu,
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'More options',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        if (widget.routine.description?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              widget.routine.description ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),

                        // Habits Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Habits (${widget.habits.length})',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              if (widget.habits.isEmpty)
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.1),
                                          // Use a different visual cue instead of dashed border
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.drag_indicator,
                                            size: 40,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Drag habits here',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Drop zone',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: widget.habits.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final habit = widget.habits[index];
                                      return DragDropHabitItem(
                                        habit: habit,
                                        isInRoutine: true,
                                        routineId: widget.routine.id,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _ActiveToggle({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isActive
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
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
