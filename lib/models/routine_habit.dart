import 'package:json_annotation/json_annotation.dart';

part 'routine_habit.g.dart';

@JsonSerializable()
class RoutineHabit {
  @JsonKey(name: 'routine_id')
  final String routineId;
  @JsonKey(name: 'habit_id')
  final String habitId;

  RoutineHabit({
    required this.routineId,
    required this.habitId,
  });

  factory RoutineHabit.fromJson(Map<String, dynamic> json) =>
      _$RoutineHabitFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineHabitToJson(this);

  RoutineHabit copyWith({
    String? routineId,
    String? habitId,
  }) {
    return RoutineHabit(
      routineId: routineId ?? this.routineId,
      habitId: habitId ?? this.habitId,
    );
  }
}

