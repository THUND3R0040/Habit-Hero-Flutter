import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/calendar_viewmodel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Color _getCompletionColor(int completedCount, int totalCount) {
    if (totalCount == 0) return Colors.transparent;
    
    final rate = completedCount / totalCount;
    
    // Strong green for high completion (8+ tasks or 80%+)
    if (completedCount >= 8 || rate >= 0.8) {
      return Colors.green.withOpacity(0.7);
    }
    // Medium green for medium completion (5-7 tasks or 50-79%)
    if (completedCount >= 5 || rate >= 0.5) {
      return Colors.green.withOpacity(0.5);
    }
    // Light green for low completion (1-4 tasks or 1-49%)
    if (completedCount >= 1 || rate > 0) {
      return Colors.green.withOpacity(0.3);
    }
    // No completion
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarViewModelProvider);
    final viewModel = ref.read(calendarViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => viewModel.loadCalendarData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadCalendarData(),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return day.year == _selectedDay.year &&
                  day.month == _selectedDay.month &&
                  day.day == _selectedDay.day;
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!selectedDay.isAfter(DateTime.now())) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                viewModel.loadDayDetails(selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, focused) {
                final dateStr = date.toIso8601String().split('T')[0];
                final completion = state.dayCompletions[dateStr];
                final isSelected = date.year == _selectedDay.year &&
                    date.month == _selectedDay.month &&
                    date.day == _selectedDay.day;
                
                if (completion != null && 
                    !date.isAfter(DateTime.now()) && 
                    completion.completedCount > 0 &&
                    !isSelected) {
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(
                        completion.completedCount,
                        completion.totalCount,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
              todayBuilder: (context, date, focused) {
                final dateStr = date.toIso8601String().split('T')[0];
                final completion = state.dayCompletions[dateStr];
                final isSelected = date.year == _selectedDay.year &&
                    date.month == _selectedDay.month &&
                    date.day == _selectedDay.day;
                
                Color backgroundColor;
                if (isSelected) {
                  backgroundColor = Colors.blue;
                } else if (completion != null && 
                    !date.isAfter(DateTime.now()) && 
                    completion.completedCount > 0) {
                  backgroundColor = _getCompletionColor(
                    completion.completedCount,
                    completion.totalCount,
                  );
                } else {
                  backgroundColor = Colors.blue.withOpacity(0.5);
                }
                
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: backgroundColor.opacity > 0.5
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, date, focused) {
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                // Return null to remove markers that cover day numbers
                return null;
              },
            ),
            eventLoader: (day) {
              final dateStr = day.toIso8601String().split('T')[0];
              final completion = state.dayCompletions[dateStr];
              if (completion != null && !day.isAfter(DateTime.now())) {
                return [completion];
              }
              return [];
            },
          ),
          if (state.selectedDayDetails != null)
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${state.selectedDayDetails!.date.day}/${state.selectedDayDetails!.date.month}/${state.selectedDayDetails!.date.year}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => viewModel.clearSelectedDay(),
                          ),
                        ],
                      ),
                    ),
                    if (state.selectedDayDetails!.completedHabits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Completed (${state.selectedDayDetails!.completedHabits.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green,
                              ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            state.selectedDayDetails!.completedHabits.length,
                        itemBuilder: (context, index) {
                          final habit =
                              state.selectedDayDetails!.completedHabits[index];
                          return ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green),
                            title: Text(habit.name),
                          );
                        },
                      ),
                    ),
                    if (state.selectedDayDetails!.missedHabits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Missed (${state.selectedDayDetails!.missedHabits.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            state.selectedDayDetails!.missedHabits.length,
                        itemBuilder: (context, index) {
                          final habit =
                              state.selectedDayDetails!.missedHabits[index];
                          return ListTile(
                            leading: const Icon(Icons.cancel, color: Colors.red),
                            title: Text(habit.name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

