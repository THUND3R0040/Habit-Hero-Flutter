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

  RoutineWithHabits copyWith({
    Routine? routine,
    List<Habit>? habits,
  }) {
    return RoutineWithHabits(
      routine: routine ?? this.routine,
      habits: habits ?? this.habits,
    );
  }
}

class RoutinesState {
  final List<RoutineWithHabits> routines;
  final List<Habit> allHabits;
  final List<Habit> unassignedHabits;
  final bool isLoading;
  final String? error;
  final bool isDragging;
  final String? draggedHabitId;
  final Map<String, bool> routineDragTargets; // routineId -> isDragTarget

  RoutinesState({
    required this.routines,
    required this.allHabits,
    required this.unassignedHabits,
    required this.isLoading,
    this.error,
    this.isDragging = false,
    this.draggedHabitId,
    Map<String, bool>? routineDragTargets,
  }) : routineDragTargets = routineDragTargets ?? {};

  RoutinesState copyWith({
    List<RoutineWithHabits>? routines,
    List<Habit>? allHabits,
    List<Habit>? unassignedHabits,
    bool? isLoading,
    String? error,
    bool? isDragging,
    String? draggedHabitId,
    Map<String, bool>? routineDragTargets,
  }) {
    return RoutinesState(
      routines: routines ?? this.routines,
      allHabits: allHabits ?? this.allHabits,
      unassignedHabits: unassignedHabits ?? this.unassignedHabits,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDragging: isDragging ?? this.isDragging,
      draggedHabitId: draggedHabitId ?? this.draggedHabitId,
      routineDragTargets: routineDragTargets ?? this.routineDragTargets,
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
          unassignedHabits: [],
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
      final assignedHabitIds = <String>{};
      final routineDragTargets = <String, bool>{};

      for (final routine in routines) {
        final routineHabits = await _routineService.getRoutineHabits(routine.id);
        final habitIds = routineHabits.map((rh) => rh.habitId).toSet();
        assignedHabitIds.addAll(habitIds);
        
        final routineHabitsList = habits
            .where((h) => habitIds.contains(h.id))
            .toList();

        routinesWithHabits.add(RoutineWithHabits(
          routine: routine,
          habits: routineHabitsList,
        ));
        
        // Initialize drag targets
        routineDragTargets[routine.id] = false;
      }

      final unassignedHabits = habits
          .where((h) => !assignedHabitIds.contains(h.id))
          .toList();

      state = state.copyWith(
        routines: routinesWithHabits,
        allHabits: habits,
        unassignedHabits: unassignedHabits,
        isLoading: false,
        routineDragTargets: routineDragTargets,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createRoutine(RoutineFormData formData) async {
    try {
      await _routineService.createRoutine(
        name: formData.name,
        description: formData.description,
        type: formData.type,
        customTimeText: formData.customTimeText,
        active: true,
      );
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateRoutineFromForm({
    required String id,
    required RoutineFormData formData,
  }) async {
    try {
      await _routineService.updateRoutineFromForm(
        id: id,
        formData: formData,
      );
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleActiveRoutine(String id) async {
    try {
      await _routineService.toggleActive(id);
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

  // DRAG AND DROP METHODS

  void startDragging(String habitId) {
    state = state.copyWith(
      isDragging: true,
      draggedHabitId: habitId,
    );
  }

  void stopDragging() {
    state = state.copyWith(
      isDragging: false,
      draggedHabitId: null,
    );
    _clearAllDragTargets();
  }

  void setDragTarget(String routineId, bool isTarget) {
    final updatedTargets = Map<String, bool>.from(state.routineDragTargets);
    updatedTargets[routineId] = isTarget;
    state = state.copyWith(routineDragTargets: updatedTargets);
  }

  void _clearAllDragTargets() {
    final updatedTargets = Map<String, bool>.from(state.routineDragTargets);
    for (final key in updatedTargets.keys) {
      updatedTargets[key] = false;
    }
    state = state.copyWith(routineDragTargets: updatedTargets);
  }

  Future<void> addHabitToRoutine({
    required String routineId,
    required String habitId,
  }) async {
    try {
      // Add to database
      await _routineService.addHabitToRoutine(
        routineId: routineId,
        habitId: habitId,
      );
      
      // Update local state
      final updatedRoutines = <RoutineWithHabits>[];
      final draggedHabit = state.allHabits.firstWhere((h) => h.id == habitId);
      
      for (final routineWithHabits in state.routines) {
        if (routineWithHabits.routine.id == routineId) {
          // Add habit to this routine
          final updatedHabits = List<Habit>.from(routineWithHabits.habits);
          updatedHabits.add(draggedHabit);
          
          updatedRoutines.add(routineWithHabits.copyWith(
            habits: updatedHabits,
          ));
        } else {
          updatedRoutines.add(routineWithHabits);
        }
      }
      
      // Update unassigned habits
      final updatedUnassigned = state.unassignedHabits
          .where((h) => h.id != habitId)
          .toList();
      
      state = state.copyWith(
        routines: updatedRoutines,
        unassignedHabits: updatedUnassigned,
      );
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Reload to sync with server
      await loadRoutines();
    }
  }

  Future<void> removeHabitFromRoutine({
    required String routineId,
    required String habitId,
  }) async {
    try {
      // Remove from database
      await _routineService.removeHabitFromRoutine(
        routineId: routineId,
        habitId: habitId,
      );
      
      // Update local state
      final updatedRoutines = <RoutineWithHabits>[];
      final removedHabit = state.allHabits.firstWhere((h) => h.id == habitId);
      
      for (final routineWithHabits in state.routines) {
        if (routineWithHabits.routine.id == routineId) {
          // Remove habit from this routine
          final updatedHabits = routineWithHabits.habits
              .where((h) => h.id != habitId)
              .toList();
          
          updatedRoutines.add(routineWithHabits.copyWith(
            habits: updatedHabits,
          ));
        } else {
          updatedRoutines.add(routineWithHabits);
        }
      }
      
      // Add to unassigned habits
      final updatedUnassigned = List<Habit>.from(state.unassignedHabits);
      updatedUnassigned.add(removedHabit);
      
      state = state.copyWith(
        routines: updatedRoutines,
        unassignedHabits: updatedUnassigned,
      );
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Reload to sync with server
      await loadRoutines();
    }
  }

  Future<void> reorderHabitsInRoutine({
    required String routineId,
    required List<String> habitIds,
  }) async {
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