import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import '../models/habit_completion.dart';
import '../services/habit_service.dart';
import '../services/routine_service.dart';
import '../services/completion_service.dart';
import '../services/supabase_providers.dart';

class TodayHabit {
  final Habit habit;
  final bool completed;
  final Routine? routine;

  TodayHabit({
    required this.habit,
    required this.completed,
    this.routine,
  });
}

class TodayState {
  final List<TodayHabit> habits;
  final bool isLoading;
  final String? error;
  final int completedCount;
  final int totalCount;

  TodayState({
    required this.habits,
    required this.isLoading,
    this.error,
    required this.completedCount,
    required this.totalCount,
  });

  TodayState copyWith({
    List<TodayHabit>? habits,
    bool? isLoading,
    String? error,
    int? completedCount,
    int? totalCount,
  }) {
    return TodayState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class TodayViewModel extends StateNotifier<TodayState> {
  final HabitService _habitService;
  final RoutineService _routineService;
  final CompletionService _completionService;

  TodayViewModel(
    this._habitService,
    this._routineService,
    this._completionService,
  ) : super(TodayState(
          habits: [],
          isLoading: true,
          completedCount: 0,
          totalCount: 0,
        )) {
    loadTodayHabits();
  }

  Future<void> loadTodayHabits() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final habits = await _habitService.getHabits();
      final routines = await _routineService.getRoutines();
      final activeRoutines = routines.where((r) => r.active).toList();
      final completions = await _completionService.getCompletionsForDate(startOfDay);

      final completionMap = <String, bool>{};
      for (final completion in completions) {
        completionMap[completion.habitId] = completion.completed;
      }

      final routineHabitsMap = <String, List<String>>{};
      for (final routine in activeRoutines) {
        final routineHabits = await _routineService.getRoutineHabits(routine.id);
        routineHabitsMap[routine.id] =
            routineHabits.map((rh) => rh.habitId).toList();
      }

      final habitRoutineMap = <String, Routine>{};
      for (final entry in routineHabitsMap.entries) {
        final routine = activeRoutines.firstWhere((r) => r.id == entry.key);
        for (final habitId in entry.value) {
          habitRoutineMap[habitId] = routine;
        }
      }

      final todayHabits = habits.map((habit) {
        final completed = completionMap[habit.id] ?? false;
        final routine = habitRoutineMap[habit.id];
        return TodayHabit(
          habit: habit,
          completed: completed,
          routine: routine,
        );
      }).toList();

      final completedCount = todayHabits.where((h) => h.completed).length;
      final totalCount = todayHabits.length;

      state = state.copyWith(
        habits: todayHabits,
        isLoading: false,
        completedCount: completedCount,
        totalCount: totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleHabit(String habitId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final currentCompletion =
          await _completionService.getCompletion(habitId: habitId, date: startOfDay);
      final newCompleted = !(currentCompletion?.completed ?? false);

      await _completionService.toggleCompletion(
        habitId: habitId,
        date: startOfDay,
        completed: newCompleted,
      );

      await loadTodayHabits();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<TodayHabit> getHabitsByRoutine(Routine? routine) {
    if (routine == null) {
      return state.habits.where((h) => h.routine == null).toList();
    }
    return state.habits.where((h) => h.routine?.id == routine.id).toList();
  }

  List<Routine> getActiveRoutines() {
    final routineIds = state.habits
        .where((h) => h.routine != null)
        .map((h) => h.routine!.id)
        .toSet();
    return state.habits
        .where((h) => h.routine != null)
        .map((h) => h.routine!)
        .toSet()
        .toList();
  }
}

final todayViewModelProvider =
    StateNotifierProvider<TodayViewModel, TodayState>((ref) {
  return TodayViewModel(
    ref.watch(habitServiceProvider),
    ref.watch(routineServiceProvider),
    ref.watch(completionServiceProvider),
  );
});

