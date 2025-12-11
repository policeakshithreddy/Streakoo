# Year in Review & Habit Insights - Integration Guide

## ✅ What's Been Implemented

### 1. Year in Review Service
**File**: `lib/services/year_in_review_service.dart`

**Features**:
- Calculate annual statistics (completions, streaks, XP)
- Find most consistent habit
- Identify best month
- Track perfect days (100% completion)
- Generate motivational messages
- Streak ranking system

**Usage**:
```dart
import 'package:provider/provider.dart';

// In your UI:
final appState = Provider.of<AppState>(context);
final review = YearInReviewService.instance.generateReview(
  appState.habits,
  2024  // or YearInReviewService.instance.getReviewYear()
);

// Access data:
print('Total Completions: ${review.totalCompletions}');
print('Longest Streak: ${review.longestStreak} days');
print('Most Consistent: ${review.mostConsistentHabit}');
print('Rank: ${review.streakRank}');  // "Champion 👑"
```

---

### 2. Habit Insights Service
**File**: `lib/services/habit_insights_service.dart`

**Features**:
- **Weekday Pattern**: "You complete workouts 80% more on weekdays"
- **Streak Warning**: "You usually skip on Fridays - don't break your 12-day streak!"
- **Performance Trend**: "You improved 30% this week!"
- **Motivational**: "7-day streak! You're on fire!"

**Usage**:
```dart
final insights = HabitInsightsService.instance.generateInsights(appState.habits);

// Get top 3 insights
final topInsights = HabitInsightsService.instance.getTopInsights(insights);

// Display in UI or send as notifications
for (final insight in topInsights) {
  print('${insight.icon} ${insight.message}');
}
```

---

### 3. Smart Notification Service
**File**: `lib/services/smart_notification_service.dart`

**Features**:
- Send weekly insights as notifications
- Deliver individual insights
- Integration with existing notification system

**Usage**:
```dart
// Send weekly insights (call once per week)
await SmartNotificationService.instance.sendWeeklyInsights(appState.habits);

// Send single insight
await SmartNotificationService.instance.sendInsight(topInsights.first);
```

---

## 🎯 Quick Integration Examples

### Example 1: Show Insights on Stats Screen
```dart
// In stats_screen.dart
class _StatsScreenState extends State<StatsScreen> {
  List<HabitInsight> _insights = [];

  @override
  void initState() {
   super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final insights = HabitInsightsService.instance.generateInsights(appState.habits);
    setState(() {
      _insights = HabitInsightsService.instance.getTopInsights(insights);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // ... existing stats ...
        
        // Add Insights Section
        if (_insights.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('💡 Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ..._insights.map((insight) => ListTile(
            leading: Text(insight.icon, style: const TextStyle(fontSize: 24)),
            title: Text(insight.message),
            subtitle: Text('${insight.habitEmoji} ${insight.habitName}'),
          )),
        ],
      ],
    );
  }
}
```

---

### Example 2: Weekly Insights Notification
```dart
// In main.dart or app init
void _scheduleWeeklyInsights(AppState appState) {
  // Call this once per week (e.g., every Sunday)
  SmartNotificationService.instance.sendWeeklyInsights(appState.habits);
}
```

---

### Example 3: Add "Year in Review" Button
```dart
// In profile_screen.dart or stats_screen.dart
ElevatedButton(
  onPressed: () {
    final appState = Provider.of<AppState>(context, listen: false);
    final review = YearInReviewService.instance.generateReview(
      appState.habits,
      2024,
    );
    
    // Show dialog or navigate to review screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 ${review.year} in Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Completions: ${review.totalCompletions}'),
            Text('Longest Streak: ${review.longestStreak} days'),
            Text('Rank: ${review.streakRank}'),
            Text(review.motivationalMessage),
          ],
        ),
      ),
    );
  },
  child: const Text('View Year in Review'),
)
```

---

## 📱 Next Steps (Optional UI Polish)

To create the full "Spotify Wrapped" style UI with animated slides and sharing:

1. **Create Year in Review Screen** with PageView for slides
2. **Add animations** using flutter_animate package
3. **Implement sharing** using share_plus package
4. **Generate shareable image** using screenshot package

**Estimated time**: 6-8 additional hours for full UI

---

## 🎉 Current State

**Ready to Use**:
- ✅ Year statistics calculation
- ✅ Habit pattern analysis
- ✅ Smart insights generation
- ✅ Notification delivery

**Needs UI** (can be added later):
- ⏳ Animated slides screen
- ⏳ Social sharing buttons
- ⏳ Image generation for sharing

**The core intelligence is done!** You can start showing insights to users TODAY by adding the simple integration examples above.
