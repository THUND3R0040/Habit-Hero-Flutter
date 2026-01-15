import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/habit_service.dart';
import '../services/completion_service.dart';
import '../services/supabase_providers.dart';

class HabitWithStats {
  final Habit habit;
  final double completionPercentage;

  HabitWithStats({
    required this.habit,
    required this.completionPercentage,
  });
}

class HabitsState {
  final List<HabitWithStats> habits;
  final bool isLoading;
  final String? error;

  HabitsState({
    required this.habits,
    required this.isLoading,
    this.error,
  });

  HabitsState copyWith({
    List<HabitWithStats>? habits,
    bool? isLoading,
    String? error,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HabitsViewModel extends StateNotifier<HabitsState> {
  final HabitService _habitService;
  final CompletionService _completionService;

  HabitsViewModel(
    this._habitService,
    this._completionService,
  ) : super(HabitsState(
          habits: [],
          isLoading: true,
        )) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final habits = await _habitService.getHabits();
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final habitsWithStats = <HabitWithStats>[];

      for (final habit in habits) {
        final completions =
            await _completionService.getCompletionsForHabit(habit.id);
        final recentCompletions = completions.where((c) {
          return c.date.isAfter(thirtyDaysAgo) && c.completed;
        }).length;

        final daysInRange = 30;
        final percentage = daysInRange > 0
            ? (recentCompletions / daysInRange * 100).clamp(0.0, 100.0)
            : 0.0;

        habitsWithStats.add(HabitWithStats(
          habit: habit,
          completionPercentage: percentage,
        ));
      }

      state = state.copyWith(
        habits: habitsWithStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createHabit({
    required String name,
    String? description,
    required String icon,
    required String color,
  }) async {
    try {
      await _habitService.createHabit(
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateHabit({
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    try {
      await _habitService.updateHabit(
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _habitService.deleteHabit(id);
      await loadHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final habitsViewModelProvider =
    StateNotifierProvider<HabitsViewModel, HabitsState>((ref) {
  return HabitsViewModel(
    ref.watch(habitServiceProvider),
    ref.watch(completionServiceProvider),
  );
});

