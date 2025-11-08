import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:streakoo/models/habit.dart';
import 'package:streakoo/providers/app_provider.dart';
import 'package:streakoo/providers/habit_provider.dart';
import 'package:streakoo/utils/constants.dart';
import 'package:streakoo/widgets/habit_tile.dart';

class DailyTrackingTab extends StatelessWidget {
  const DailyTrackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${appProvider.userName}!'),
        centerTitle: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: habitProvider.habitBoxNotifier,
        builder: (context, Box<Habit> box, _) {
          final habits = box.values.toList();
          if (habits.isEmpty) {
            return const Center(
              child: Text(
                'No habits yet. Add one!',
                style: AppColors.subheadingStyle,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              // Get the key to pass to the tile
              final habitKey = box.keyAt(index);
              return HabitTile(habit: habit, habitKey: habitKey);
            },
          );
        },
      ),
    );
  }
}
