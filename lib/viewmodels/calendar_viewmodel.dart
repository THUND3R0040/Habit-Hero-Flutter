import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/habit_service.dart';
import '../services/completion_service.dart';
import '../services/supabase_providers.dart';

class DayCompletion {
  final DateTime date;
  final int completedCount;
  final int totalCount;
  final double completionRate;

  DayCompletion({
    required this.date,
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
  });
}

class DayDetails {
  final DateTime date;
  final List<Habit> completedHabits;
  final List<Habit> missedHabits;

  DayDetails({
    required this.date,
    required this.completedHabits,
    required this.missedHabits,
  });
}

class CalendarState {
  final Map<String, DayCompletion> dayCompletions;
  final DayDetails? selectedDayDetails;
  final bool isLoading;
  final String? error;

  CalendarState({
    required this.dayCompletions,
    this.selectedDayDetails,
    required this.isLoading,
    this.error,
  });

  CalendarState copyWith({
    Map<String, DayCompletion>? dayCompletions,
    DayDetails? selectedDayDetails,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      dayCompletions: dayCompletions ?? this.dayCompletions,
      selectedDayDetails: selectedDayDetails ?? this.selectedDayDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CalendarViewModel extends StateNotifier<CalendarState> {
  final HabitService _habitService;
  final CompletionService _completionService;

  CalendarViewModel(
    this._habitService,
    this._completionService,
  ) : super(CalendarState(
          dayCompletions: {},
          isLoading: true,
        )) {
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final habits = await _habitService.getHabits();
      final completions = await _completionService.getCompletionsForDateRange(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      final dayCompletionsMap = <String, DayCompletion>{};

      for (int day = 1; day <= endOfMonth.day; day++) {
        final date = DateTime(now.year, now.month, day);
        if (date.isAfter(now)) continue;

        final dateStr = date.toIso8601String().split('T')[0];
        int completedCount = 0;
        int totalCount = habits.length;

        for (final habit in habits) {
          final key = '${habit.id}_$dateStr';
          final completion = completions[key];
          if (completion != null && completion.completed) {
            completedCount++;
          }
        }

        final completionRate =
            totalCount > 0 ? completedCount / totalCount : 0.0;

        dayCompletionsMap[dateStr] = DayCompletion(
          date: date,
          completedCount: completedCount,
          totalCount: totalCount,
          completionRate: completionRate,
        );
      }

      state = state.copyWith(
        dayCompletions: dayCompletionsMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadDayDetails(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final habits = await _habitService.getHabits();
      final completions = await _completionService.getCompletionsForDate(date);

      final completionMap = <String, bool>{};
      for (final completion in completions) {
        completionMap[completion.habitId] = completion.completed;
      }

      final completedHabits = <Habit>[];
      final missedHabits = <Habit>[];

      for (final habit in habits) {
        final completed = completionMap[habit.id] ?? false;
        if (completed) {
          completedHabits.add(habit);
        } else {
          missedHabits.add(habit);
        }
      }

      state = state.copyWith(
        selectedDayDetails: DayDetails(
          date: date,
          completedHabits: completedHabits,
          missedHabits: missedHabits,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearSelectedDay() {
    state = state.copyWith(selectedDayDetails: null);
  }
}

final calendarViewModelProvider =
    StateNotifierProvider<CalendarViewModel, CalendarState>((ref) {
  return CalendarViewModel(
    ref.watch(habitServiceProvider),
    ref.watch(completionServiceProvider),
  );
});

