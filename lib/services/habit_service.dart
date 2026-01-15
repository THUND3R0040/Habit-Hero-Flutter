import '../models/habit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitService {
  final SupabaseClient _supabase;

  HabitService(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;
  
  void _ensureAuthenticated() {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
  }

  Future<List<Habit>> getHabits() async {
    _ensureAuthenticated();
    final response = await _supabase
        .from('habits')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Habit.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Habit> createHabit({
    required String name,
    String? description,
    required String icon,
    required String color,
  }) async {
    _ensureAuthenticated();
    final response = await _supabase.from('habits').insert({
      'user_id': _userId!,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
    }).select().single();

    return Habit.fromJson(response as Map<String, dynamic>);
  }

  Future<Habit> updateHabit({
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    _ensureAuthenticated();
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;

    final response = await _supabase
        .from('habits')
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return Habit.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteHabit(String id) async {
    _ensureAuthenticated();
    await _supabase
        .from('habits')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<Habit?> getHabitById(String id) async {
    _ensureAuthenticated();
    final response = await _supabase
        .from('habits')
        .select()
        .eq('id', id)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return Habit.fromJson(response as Map<String, dynamic>);
  }
}

