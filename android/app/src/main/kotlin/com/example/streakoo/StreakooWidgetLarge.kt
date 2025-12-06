package com.example.streakoo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StreakooWidgetLarge : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_large).apply {
                // Get data from SharedPreferences (synced from Flutter)
                val completed = widgetData.getInt("completed_habits", 0)
                val total = widgetData.getInt("total_habits", 0)
                val streak = widgetData.getInt("current_streak", 0)
                val steps = widgetData.getInt("steps", 0)
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

                // Format steps display
                val stepsDisplay = when {
                    steps >= 10000 -> "👟 ${steps / 1000}k steps 🎉"
                    steps >= 5000 -> "👟 $steps steps 💪"
                    steps > 0 -> "👟 $steps steps"
                    else -> "👟 0 steps"
                }

                // Update UI elements
                setTextViewText(R.id.appwidget_text, habitDisplay)
                setTextViewText(R.id.widget_streak_count, streakDisplay)
                setTextViewText(R.id.widget_motivation, motivation)
                setTextViewText(R.id.widget_steps_count, stepsDisplay)

                // Update Progress Bar
                val progress = if (total > 0) (completed * 100) / total else 0
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)

                // Click to open app
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    2, // Use different request code for different widgets
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root_large, pendingIntent)
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
