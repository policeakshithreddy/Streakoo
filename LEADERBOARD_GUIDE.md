# Leaderboard System - Quick Start Guide

## ✅ What's Been Implemented

###  Core Services
1. **LeaderboardService** (`/lib/services/leaderboard_service.dart`)
   - Smart scoring algorithm
   - Supabase sync
   - Global/Weekly leaderboard fetching

2. **Data Models** (`/lib/models/user_score.dart`)
   - UserScore with score breakdown
   - LeaderboardEntry with rankings
   - Tier system (Beginner → Legend)

3. **UI Screen** (`/lib/screens/leaderboard_screen.dart`)
   - Tab navigation (Global/Weekly)
   - Top 3 podium display
   - User rank highlighting
   - Pull to refresh

---

## 🗄️ Supabase Setup Required

**Run this SQL in your Supabase SQL Editor**:

```sql
-- Create user_scores table
CREATE TABLE user_scores (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT NOT NULL DEFAULT 'Anonymous',
  total_score INT DEFAULT 0,
  daily_completions INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  completion_rate DECIMAL(5,2) DEFAULT 0,
  total_xp INT DEFAULT 0,
  current_week_score INT DEFAULT 0,
  last_updated TIMESTAMP DEFAULT NOW(),
  is_public BOOLEAN DEFAULT TRUE
);

-- Create indexes for performance
CREATE INDEX idx_user_scores_total ON user_scores(total_score DESC);
CREATE INDEX idx_user_scores_weekly ON user_scores(current_week_score DESC);

-- Enable Row Level Security
ALTER TABLE user_scores ENABLE ROW LEVEL SECURITY;

-- Anyone can view public scores
CREATE POLICY "Anyone can view public scores"
  ON user_scores FOR SELECT
  USING (is_public = TRUE);

-- Users can update their own score
CREATE POLICY "Users can update own score"
  ON user_scores FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can insert their own score
CREATE POLICY "Users can insert own score"
  ON user_scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

---

## 🔗 Integration Steps

### Step 1: Add to Navigation
**File**: `/lib/screens/nav_wrapper.dart`

```dart
// Add to bottom navigation
NavigationDestination(
  icon: Icon(Icons.leaderboard),
  label: 'Leaderboard',
),

// Add to screens list
const LeaderboardScreen(),
```

### Step 2: Auto-Update Score on Habit Completion
**File**: `/lib/state/app_state.dart`

Add to `completeHabit()` method:

```dart
Future<void> completeHabit(Habit habit) async {
  // ... existing completion logic ...
  
  // Update leaderboard score
  await _updateLeaderboardScore();
}

Future<void> _updateLeaderboardScore() async {
  final supabase = SupabaseService();
  if (!supabase.isAuthenticated) return;
  
  final userId = supabase.currentUser!.id;
  final username = supabase.currentUser!.email?.split('@').first ?? 'User';
  
  final score = LeaderboardService.instance.calculateScoreFromHabits(
    userId: userId,
    username: username,
    habits: _habits,
    totalXP: userLevel.totalXP,
  );
  
  await LeaderboardService.instance.syncScoreToCloud(score);
}
```

### Step 3: Import Dependencies
```dart
import 'package:streakoo/models/user_score.dart';
import 'package:streakoo/services/leaderboard_service.dart';
import 'package:streakoo/screens/leaderboard_screen.dart';
```

---

## 📊 How Scoring Works

**Formula**:
```
Total Score = (Completions × 10) + (Streak × 5) + (Rate% × 2) + XP
```

**Example**:
- 100 completions = 1,000 pts
- 30-day streak = 150 pts
- 85% rate = 170 pts
- 500 XP = 500 pts
- **Total: 1,820 pts** → "Advanced" tier

**Score Tiers**:
- 10,000+ = Legend 🏆
- 5,000+ = Master ⭐
- 2,500+ = Expert 💎
- 1,000+ = Advanced 🎯
- 500+ = Intermediate 📈
- 0-500 = Beginner 🌱

---

## 🎨 UI Features

- **Podium Display**: Top 3 users with gradient badges
- **Your Rank**: Highlighted in purple
- **Tabs**: Global (all-time) vs Weekly (resets Monday)
- **Pull to Refresh**: Update rankings
- **Score Tiers**: Gamified progression labels

---

## ✅ Testing Checklist

- [ ] Run Supabase SQL script
- [ ] Add leaderboard to navigation
- [ ] Complete a habit → check score updates
- [ ] Open leaderboard → see your rank
- [ ] Switch between Global/Weekly tabs
- [ ] Pull to refresh rankings

---

**Ready to compete!** 🏆
