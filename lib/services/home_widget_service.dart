import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.com.streakoo.app'; // Replace with your actual App Group ID if you have one
  static const String androidWidgetName = 'StreakooWidgetProvider';

  static Future<void> updateWidgetData({
    required int completedHabits,
    required int totalHabits,
    required int currentStreak,
    required int steps,
  }) async {
    try {
      // Save data to shared storage
      await HomeWidget.saveWidgetData<int>('completed_habits', completedHabits);
      await HomeWidget.saveWidgetData<int>('total_habits', totalHabits);
      await HomeWidget.saveWidgetData<int>('current_streak', currentStreak);
      await HomeWidget.saveWidgetData<int>('steps', steps);

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'StreakooWidget',
      );
    } catch (e) {
      print('Error updating home widget: $e');
    }
  }
}
