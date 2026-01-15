import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'habit_service.dart';
import 'routine_service.dart';
import 'completion_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((data) => data.session?.user);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService(ref.watch(supabaseClientProvider));
});

final routineServiceProvider = Provider<RoutineService>((ref) {
  return RoutineService(ref.watch(supabaseClientProvider));
});

final completionServiceProvider = Provider<CompletionService>((ref) {
  return CompletionService(ref.watch(supabaseClientProvider));
});

