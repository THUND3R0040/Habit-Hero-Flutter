// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_completion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitCompletion _$HabitCompletionFromJson(Map<String, dynamic> json) =>
    HabitCompletion(
      habitId: json['habit_id'] as String,
      date: HabitCompletion._dateFromJson(json['date']),
      completed: json['completed'] as bool,
    );

Map<String, dynamic> _$HabitCompletionToJson(HabitCompletion instance) =>
    <String, dynamic>{
      'habit_id': instance.habitId,
      'date': HabitCompletion._dateToJson(instance.date),
      'completed': instance.completed,
    };
