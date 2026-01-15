import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';
import '../models/habit.dart';
import '../models/routine_habit.dart';
import '../services/routine_service.dart';
import '../services/habit_service.dart';
import '../services/supabase_providers.dart';

class RoutineWithHabits {
  final Routine routine;
  final List<Habit> habits;

  RoutineWithHabits({
    required this.routine,
    required this.habits,
  });
}

class RoutinesState {
  final List<RoutineWithHabits> routines;
  final List<Habit> allHabits;
  final bool isLoading;
  final String? error;

  RoutinesState({
    required this.routines,
    required this.allHabits,
    required this.isLoading,
    this.error,
  });

  RoutinesState copyWith({
    List<RoutineWithHabits>? routines,
    List<Habit>? allHabits,
    bool? isLoading,
    String? error,
  }) {
    return RoutinesState(
      routines: routines ?? this.routines,
      allHabits: allHabits ?? this.allHabits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RoutinesViewModel extends StateNotifier<RoutinesState> {
  final RoutineService _routineService;
  final HabitService _habitService;

  RoutinesViewModel(
    this._routineService,
    this._habitService,
  ) : super(RoutinesState(
          routines: [],
          allHabits: [],
          isLoading: true,
        )) {
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final routines = await _routineService.getRoutines();
      final habits = await _habitService.getHabits();

      final routinesWithHabits = <RoutineWithHabits>[];

      for (final routine in routines) {
        final routineHabits = await _routineService.getRoutineHabits(routine.id);
        final habitIds = routineHabits.map((rh) => rh.habitId).toList();
        final routineHabitsList = habits
            .where((h) => habitIds.contains(h.id))
            .toList();

        routinesWithHabits.add(RoutineWithHabits(
          routine: routine,
          habits: routineHabitsList,
        ));
      }

      state = state.copyWith(
        routines: routinesWithHabits,
        allHabits: habits,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createRoutine({
    required String name,
    bool active = true,
  }) async {
    try {
      await _routineService.createRoutine(name: name, active: active);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateRoutine({
    required String id,
    String? name,
    bool? active,
  }) async {
    try {
      await _routineService.updateRoutine(id: id, name: name, active: active);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      await _routineService.deleteRoutine(id);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addHabitToRoutine({
    required String routineId,
    required String habitId,
  }) async {
    try {
      await _routineService.addHabitToRoutine(
        routineId: routineId,
        habitId: habitId,
      );
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeHabitFromRoutine({
    required String routineId,
    required String habitId,
  }) async {
    try {
      await _routineService.removeHabitFromRoutine(
        routineId: routineId,
        habitId: habitId,
      );
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reorderHabitsInRoutine({
    required String routineId,
    required List<String> habitIds,
  }) async {
    // Note: Reordering is not supported without a position column
    // This method is kept for API compatibility but does nothing
    await loadRoutines();
  }
}

final routinesViewModelProvider =
    StateNotifierProvider<RoutinesViewModel, RoutinesState>((ref) {
  return RoutinesViewModel(
    ref.watch(routineServiceProvider),
    ref.watch(habitServiceProvider),
  );
});

