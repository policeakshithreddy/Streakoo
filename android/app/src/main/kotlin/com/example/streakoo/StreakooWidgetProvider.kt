package com.example.streakoo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StreakooWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from SharedPreferences (synced from Flutter)
                val completed = widgetData.getInt("completed_habits", 0)
                val total = widgetData.getInt("total_habits", 0)
                val streak = widgetData.getInt("current_streak", 0)
                val motivation = widgetData.getString("motivation", null) ?: getDefaultMessage(completed, total, streak)

                // Format habit count display
                val habitDisplay = when {
                    total == 0 -> "✨"
                    else -> "$completed/$total"
                }

                // Format streak display
                val streakDisplay = when {
                    streak >= 7 -> "🔥 $streak"
                    streak > 0 -> "✨ $streak"
                    else -> "🎯 0"
                }

                // Update UI elements
                setTextViewText(R.id.appwidget_text, habitDisplay)
                setTextViewText(R.id.widget_streak_value, streakDisplay)
                setTextViewText(R.id.widget_motivation, motivation)

                // Update Progress Bar
                val progress = if (total > 0) (completed * 100) / total else 0
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)

                // Click to open app
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                // Use the root layout ID if possible, or a known ID. 
                // In widget_layout.xml, root is LinearLayout with no ID, let's assume views.setOnClickPendingIntent checks invalid ID or we need to add ID. 
                // Actually, RemoteViews setOnClickPendingIntent usually needs an ID. 
                // Let's assume we can attach it to appwidget_text or motivation for now if root has no ID,
                // OR better, let's view widget_layout.xml again to see if I gave root an ID.
                // I checked widget_layout.xml, root has no ID. I should probably add one or click on a specific element.
                // Let's add ID to root in widget_layout.xml in a follow up or just click on 'appwidget_text' for now.
                // Wait, creating a mismatch fix here first.
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun getDefaultMessage(completed: Int, total: Int, streak: Int): String {
        return when {
            total == 0 -> "Add your first habit! 🌟"
            completed == total && streak >= 7 -> "On fire! $streak days! 🔥"
            completed == total -> "All done today! ✨"
            completed >= total / 2 -> "Almost there! 💪"
            streak > 0 -> "$streak day streak! 🎯"
            else -> "Let's do this! 🌟"
        }
    }
}
