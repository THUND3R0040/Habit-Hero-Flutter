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
            // ignore: unrelated_type_equality_checks
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
                        // Everything inside the card scales off this single
                        // width measurement.  A half-screen card on a 360px
                        // phone lands around 148-164px here after the outer
                        // padding and the 16px gap in the two-column Row.
                        final bool isNarrow = constraints.maxWidth < 180;

                        // --- title ---
                        final titleStyle = (isNarrow
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.bold);

                        // --- description ---
                        final descStyle = (isNarrow
                                ? theme.textTheme.bodySmall
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        );

                        // --- spacing ---
                        final double smallGap = isNarrow ? 6.0 : 10.0;
                        final double sectionGap = isNarrow ? 10.0 : 14.0;

                        // --- drop zone ---
                        final double dropZoneHeight = isNarrow ? 80.0 : 110.0;
                        final double dropIconSize = isNarrow ? 28.0 : 36.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Header row: title column + menu button ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title — 2 lines max, ellipsis after
                                      Text(
                                        widget.routine.name,
                                        style: titleStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: smallGap),
                                      // Routine type label
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
                                      SizedBox(height: smallGap),
                                      // Active / Inactive toggle
                                      _ActiveToggle(
                                        isActive: widget.routine.active,
                                        onToggle: widget.onToggleActive,
                                        compact: isNarrow,
                                      ),
                                    ],
                                  ),
                                ),
                                // Three-dot menu — smaller on narrow
                                IconButton(
                                  onPressed: _toggleMenu,
                                  icon: Icon(Icons.more_vert,
                                      size: isNarrow ? 18 : 24),
                                  iconSize: isNarrow ? 18 : 24,
                                  padding: isNarrow
                                      ? const EdgeInsets.all(4)
                                      : null,
                                  constraints: isNarrow
                                      ? const BoxConstraints(
                                          minWidth: 28, minHeight: 28)
                                      : null,
                                  tooltip: 'More options',
                                ),
                              ],
                            ),

                            SizedBox(height: sectionGap),

                            // ── Description ──
                            if (widget.routine.description?.isNotEmpty == true)
                              Padding(
                                padding: EdgeInsets.only(bottom: sectionGap),
                                child: Text(
                                  widget.routine.description ?? '',
                                  style: descStyle,
                                  // Fewer lines on narrow so the card
                                  // stays compact; still readable.
                                  maxLines: isNarrow ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            // ── Habits section ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Habits (${widget.habits.length})',
                                  style: (isNarrow
                                          ? theme.textTheme.bodySmall
                                          : theme.textTheme.labelLarge)
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: smallGap),
                                if (widget.habits.isEmpty)
                                  // Empty drop zone — height and icon scale
                                  Container(
                                    height: dropZoneHeight,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.drag_indicator,
                                            size: dropIconSize,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          SizedBox(
                                              height: isNarrow ? 4.0 : 6.0),
                                          Text(
                                            'Drag habits here',
                                            style: (isNarrow
                                                    ? theme.textTheme.bodySmall
                                                    : theme
                                                        .textTheme.bodyMedium)
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: widget.habits.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 4),
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

// ---------------------------------------------------------------------------
// _ActiveToggle
// ---------------------------------------------------------------------------
class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  // When compact is true the track and knob shrink and the label text drops
  // to bodySmall so the toggle fits comfortably on narrow cards.
  final bool compact;

  const _ActiveToggle({
    required this.isActive,
    required this.onToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Track dimensions
    final double trackW = compact ? 36.0 : 44.0;
    final double trackH = compact ? 20.0 : 24.0;
    final double knobD = compact ? 13.0 : 16.0;
    final double knobMargin = compact ? 3.0 : 4.0;

    return GestureDetector(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: trackW,
            height: trackH,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(trackH / 2),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
                  isActive ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knobD,
                height: knobD,
                margin: EdgeInsets.symmetric(horizontal: knobMargin),
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
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
              color:
                  isActive ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MenuButton
// ---------------------------------------------------------------------------
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