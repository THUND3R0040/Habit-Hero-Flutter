import 'package:flutter/material.dart';
import '../models/routine.dart';

class RoutineCard extends StatefulWidget {
  final Routine routine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const RoutineCard({
    super.key,
    required this.routine,
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
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: widget.routine.active 
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
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
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                Expanded(
                  child: Center(
                    child: Text(
                      widget.routine.description ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _ActiveToggle({
    required this.isActive,
    required this.onToggle,
  });

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
              alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
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
              Text(
                widget.icon,
                style: const TextStyle(fontSize: 18),
              ),
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