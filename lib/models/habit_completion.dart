import 'package:json_annotation/json_annotation.dart';

part 'habit_completion.g.dart';

@JsonSerializable()
class HabitCompletion {
  @JsonKey(name: 'habit_id')
  final String habitId;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime date;
  final bool completed;

  HabitCompletion({
    required this.habitId,
    required this.date,
    required this.completed,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) =>
      _$HabitCompletionFromJson(json);

  Map<String, dynamic> toJson() => _$HabitCompletionToJson(this);

  HabitCompletion copyWith({
    String? habitId,
    DateTime? date,
    bool? completed,
  }) {
    return HabitCompletion(
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
    );
  }

  static DateTime _dateFromJson(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    }
    return DateTime.now();
  }

  static String _dateToJson(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}

