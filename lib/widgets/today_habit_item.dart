import 'package:flutter/material.dart';
import '../models/habit.dart';

class TodayHabitItem extends StatelessWidget {
  final Habit habit;
  final bool completed;
  final VoidCallback onToggle;

  const TodayHabitItem({
    super.key,
    required this.habit,
    required this.completed,
    required this.onToggle,
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
    final color = _getColorFromString(habit.color);
    final icon = _getIconFromString(habit.icon);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: CheckboxListTile(
        value: completed,
        onChanged: (_) => onToggle(),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: habit.description != null && habit.description!.isNotEmpty
            ? Text(habit.description!)
            : null,
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        activeColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

