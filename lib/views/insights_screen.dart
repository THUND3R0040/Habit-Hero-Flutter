import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/insights_viewmodel.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsViewModelProvider);
    final viewModel = ref.read(insightsViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => viewModel.loadInsights(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadInsights(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadInsights(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Overall Completion',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      CircularProgressIndicator(
                        value: state.overallCompletionPercentage / 100,
                        strokeWidth: 8,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${state.overallCompletionPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (state.bestHabit != null)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: const Text('Best Habit'),
                    subtitle: Text(state.bestHabit!.habit.name),
                    trailing: Text(
                      '${state.bestHabit!.completionPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              if (state.worstHabit != null)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.trending_down, color: Colors.red),
                    title: const Text('Worst Habit'),
                    subtitle: Text(state.worstHabit!.habit.name),
                    trailing: Text(
                      '${state.worstHabit!.completionPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              if (state.routineStats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Completion by Routine',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...state.routineStats.map((routineStat) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                routineStat.routine.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${routineStat.completionPercentage.toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: routineStat.completionPercentage / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

