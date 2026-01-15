import '../models/habit_completion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompletionService {
  final SupabaseClient _supabase;

  CompletionService(this._supabase);

  Future<void> toggleCompletion({
    required String habitId,
    required DateTime date,
    required bool completed,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    await _supabase.from('habit_completions').upsert({
      'habit_id': habitId,
      'date': dateStr,
      'completed': completed,
    });
  }

  Future<HabitCompletion?> getCompletion({
    required String habitId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId)
        .eq('date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return HabitCompletion.fromJson(response as Map<String, dynamic>);
  }

  Future<List<HabitCompletion>> getCompletionsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('habit_completions')
        .select()
        .eq('date', dateStr);

    return (response as List)
        .map((json) => HabitCompletion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<HabitCompletion>> getCompletionsForHabit(String habitId) async {
    final response = await _supabase
        .from('habit_completions')
        .select()
        .eq('habit_id', habitId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => HabitCompletion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, HabitCompletion>> getCompletionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('habit_completions')
        .select()
        .gte('date', startStr)
        .lte('date', endStr);

    final completions = (response as List)
        .map((json) => HabitCompletion.fromJson(json as Map<String, dynamic>))
        .toList();

    final map = <String, HabitCompletion>{};
    for (final completion in completions) {
      final key = '${completion.habitId}_${completion.date.toIso8601String().split('T')[0]}';
      map[key] = completion;
    }

    return map;
  }
}

