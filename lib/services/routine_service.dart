import '../models/routine.dart';
import '../models/routine_habit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineService {
  final SupabaseClient _supabase;

  RoutineService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;
  
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  Future<List<Routine>> getRoutines() async {
    _ensureAuthenticated();
    final response = await _supabase
        .from('routines')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Routine.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // UPDATE this method to include description, type, and customTimeText
  Future<Routine> createRoutine({
    required String name,
    String? description,
    RoutineType type = RoutineType.morning,
    String? customTimeText,
    bool active = true,
  }) async {
    _ensureAuthenticated();
    final response = await _supabase.from('routines').insert({
      'user_id': _userId!,
      'name': name,
      'description': description,
      'preferred_time': type.name,
      'custom_time_text': customTimeText,
      'active': active,
    }).select().single();

    return Routine.fromJson(response);
  }

  // UPDATE this method to include description, type, and customTimeText
  Future<Routine> updateRoutine({
    required String id,
    String? name,
    String? description,
    RoutineType? type,
    String? customTimeText,
    bool? active,
  }) async {
    _ensureAuthenticated();
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (type != null) updates['preferred_time'] = type.name;
    if (customTimeText != null) updates['custom_time_text'] = customTimeText;
    if (active != null) updates['active'] = active;

    final response = await _supabase
        .from('routines')
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return Routine.fromJson(response);
  }

  // ADD this new method for form-based updates
  Future<Routine> updateRoutineFromForm({
    required String id,
    required RoutineFormData formData,
  }) async {
    return updateRoutine(
      id: id,
      name: formData.name,
      description: formData.description,
      type: formData.type,
      customTimeText: formData.customTimeText,
    );
  }

  Future<void> deleteRoutine(String id) async {
    _ensureAuthenticated();
    await _supabase
        .from('routines')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  // ADD this method to toggle active state
  Future<Routine> toggleActive(String id) async {
    _ensureAuthenticated();
    
    // Get current routine
    final currentRoutine = await _supabase
        .from('routines')
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .single();
    
    final routine = Routine.fromJson(currentRoutine);
    
    // Toggle and update
    final response = await _supabase
        .from('routines')
        .update({'active': !routine.active})
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return Routine.fromJson(response);
  }

  Future<List<RoutineHabit>> getRoutineHabits(String routineId) async {
    final response = await _supabase
        .from('routine_habits')
        .select()
        .eq('routine_id', routineId);

    return (response as List)
        .map((json) => RoutineHabit.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHabitToRoutine({
    required String routineId,
    required String habitId,
  }) async {
    await _supabase.from('routine_habits').insert({
      'routine_id': routineId,
      'habit_id': habitId,
    });
  }

  Future<void> removeHabitFromRoutine({
    required String routineId,
    required String habitId,
  }) async {
    await _supabase
        .from('routine_habits')
        .delete()
        .eq('routine_id', routineId)
        .eq('habit_id', habitId);
  }

  Future<List<RoutineHabit>> getHabitsByRoutine(String routineId) async {
    final response = await _supabase
        .from('routine_habits')
        .select()
        .eq('routine_id', routineId);

    return (response as List)
        .map((json) => RoutineHabit.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}