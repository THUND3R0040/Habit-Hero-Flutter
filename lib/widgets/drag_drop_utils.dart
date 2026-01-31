import 'package:flutter/material.dart';

class DragDropUtils {
  static Widget buildDragFeedback(
    Widget child, {
    double scale = 1.05,
    double opacity = 0.8,
    double elevation = 8,
  }) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Material(
          elevation: elevation,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  static Widget buildDraggingChild(Widget child) {
    return Opacity(
      opacity: 0.3,
      child: child,
    );
  }
}