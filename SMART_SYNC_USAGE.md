# Smart Habit Sync with Streak Confirmation - Usage Guide

## How to Integrate

The feature is **fully implemented** but needs ONE integration call to activate it. Here's how:

### Option 1: Call on App Startup (Recommended)
Add this to `nav_wrapper.dart` or your main authenticated screen's `initState`:

```dart
@override
void initState() {
  super.initState();
  
  // After a small delay to ensure context is mounted
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.handleSyncConflicts(context);
  });
}
```

### Option 2: Call After Login
In your login success handler:

```dart
// After successful login
if (mounted) {
  await appState.handleSyncConflicts(context);
}
```

## How It Works

1. **Auto-Sync**: When user logs in on Device B after making changes on Device A:
   - Habit metadata (name, emoji, goal) syncs automatically ✅
   - Streak numbers are **detected** as conflicts

2. **User Prompt**: If streak conflicts exist:
   - Beautiful purple/pink themed dialog appears
   - Shows up to 3 habits with streak differences  
   - "Cloud: 5 days → Local: 10 days"

3. **User Choice**:
   - **"Yes, Update Streaks"** → Import cloud streaks
   - **"No, Keep Local"** → Keep current device streaks

## Files Created/Modified

### New Files
- `/lib/models/sync_conflict_result.dart` - Data models
- `/lib/widgets/streak_sync_confirmation_dialog.dart` - UI dialog

### Modified Files
- `/lib/services/supabase_service.dart` - Added `fetchHabitsWithoutStreaks()`, `syncStreaksOnly()`
- `/lib/services/sync_service.dart` - Added conflict detection to `syncOnAppOpen()`
- `/lib/state/app_state.dart` - Added `handleSyncConflicts(BuildContext)`

## Testing Checklist

- [ ] Log in on Device A, create habit with 5-day streak
- [ ] Back up to cloud
- [ ] Log in on Device B, verify habit appears with 5-day streak
- [ ] On Device B, increase streak to 10 days locally (don't backup)
- [ ] On Device A, rename habit, backup to cloud
- [ ] Log in on Device B again
- [ ] **Expected**: Dialog shows "Cloud: 5 vs Local: 10"
- [ ] Choose "No" → Keeps 10-day local streak ✅
- [ ] Choose "Yes" → Updates to 5-day cloud streak ✅

## Design Notes

- Dialog uses AI theme colors (purple #8B5CF6 → pink #EC4899)
- Non-blocking: User can decline sync without data loss
- Preserves user control:  Cloud doesn't force-overwrite local data
