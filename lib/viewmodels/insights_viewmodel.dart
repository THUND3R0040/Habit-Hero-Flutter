import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import '../services/habit_service.dart';
import '../services/routine_service.dart';
import '../services/completion_service.dart';
import '../services/supabase_providers.dart';

class HabitStats {
  final Habit habit;
  final int completedCount;
  final double completionPercentage;

  HabitStats({
    required this.habit,
    required this.completedCount,
    required this.completionPercentage,
  });
}

class RoutineStats {
  final Routine routine;
  final double completionPercentage;

  RoutineStats({
    required this.routine,
    required this.completionPercentage,
  });
}

class InsightsState {
  final double overallCompletionPercentage;
  final HabitStats? bestHabit;
  final HabitStats? worstHabit;
  final List<RoutineStats> routineStats;
  final bool isLoading;
  final String? error;

  InsightsState({
    required this.overallCompletionPercentage,
    this.bestHabit,
    this.worstHabit,
    required this.routineStats,
    required this.isLoading,
    this.error,
  });

  InsightsState copyWith({
    double? overallCompletionPercentage,
    HabitStats? bestHabit,
    HabitStats? worstHabit,
    List<RoutineStats>? routineStats,
    bool? isLoading,
    String? error,
  }) {
    return InsightsState(
      overallCompletionPercentage:
          overallCompletionPercentage ?? this.overallCompletionPercentage,
      bestHabit: bestHabit ?? this.bestHabit,
      worstHabit: worstHabit ?? this.worstHabit,
      routineStats: routineStats ?? this.routineStats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class InsightsViewModel extends StateNotifier<InsightsState> {
  final HabitService _habitService;
  final RoutineService _routineService;
  final CompletionService _completionService;

  InsightsViewModel(
    this._habitService,
    this._routineService,
    this._completionService,
  ) : super(InsightsState(
          overallCompletionPercentage: 0.0,
          routineStats: [],
          isLoading: true,
        )) {
    loadInsights();
  }

  Future<void> loadInsights() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final habits = await _habitService.getHabits();
      final routines = await _routineService.getRoutines();
      final completions = await _completionService.getCompletionsForDateRange(
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      final habitStatsList = <HabitStats>[];
      int totalCompletions = 0;
      int totalPossible = 0;

      for (final habit in habits) {
        int completedCount = 0;
        for (int i = 0; i < 30; i++) {
          final date = thirtyDaysAgo.add(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];
          final key = '${habit.id}_$dateStr';
          final completion = completions[key];
          if (completion != null && completion.completed) {
            completedCount++;
            totalCompletions++;
          }
          totalPossible++;
        }

        final percentage = 30 > 0 ? (completedCount / 30 * 100) : 0.0;

        habitStatsList.add(HabitStats(
          habit: habit,
          completedCount: completedCount,
          completionPercentage: percentage,
        ));
      }

      final overallPercentage =
          totalPossible > 0 ? (totalCompletions / totalPossible * 100) : 0.0;

      habitStatsList.sort((a, b) =>
          b.completionPercentage.compareTo(a.completionPercentage));

      final bestHabit = habitStatsList.isNotEmpty ? habitStatsList.first : null;
      final worstHabit =
          habitStatsList.isNotEmpty ? habitStatsList.last : null;

      final routineStatsList = <RoutineStats>[];
      for (final routine in routines) {
        final routineHabits =
            await _routineService.getRoutineHabits(routine.id);
        if (routineHabits.isEmpty) continue;

        int routineCompletions = 0;
        int routinePossible = 0;

        for (final routineHabit in routineHabits) {
          for (int i = 0; i < 30; i++) {
            final date = thirtyDaysAgo.add(Duration(days: i));
            final dateStr = date.toIso8601String().split('T')[0];
            final key = '${routineHabit.habitId}_$dateStr';
            final completion = completions[key];
            if (completion != null && completion.completed) {
              routineCompletions++;
            }
            routinePossible++;
          }
        }

        final routinePercentage = routinePossible > 0
            ? (routineCompletions / routinePossible * 100)
            : 0.0;

        routineStatsList.add(RoutineStats(
          routine: routine,
          completionPercentage: routinePercentage,
        ));
      }

      state = state.copyWith(
        overallCompletionPercentage: overallPercentage,
        bestHabit: bestHabit,
        worstHabit: worstHabit,
        routineStats: routineStatsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final insightsViewModelProvider =
    StateNotifierProvider<InsightsViewModel, InsightsState>((ref) {
  return InsightsViewModel(
    ref.watch(habitServiceProvider),
    ref.watch(routineServiceProvider),
    ref.watch(completionServiceProvider),
  );
});

