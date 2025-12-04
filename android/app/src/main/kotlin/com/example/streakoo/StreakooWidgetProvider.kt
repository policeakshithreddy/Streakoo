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
                val steps = widgetData.getInt("steps", 0)

                // Update UI
                setTextViewText(R.id.habits_count_text, "$completed/$total")
                setTextViewText(R.id.streak_text, "🔥 $streak")
                setTextViewText(R.id.steps_text, "👟 $steps steps today")

                // Update Progress Bar
                val progress = if (total > 0) (completed * 100) / total else 0
                setProgressBar(R.id.habits_progress_bar, 100, progress, false)

                // Click to open app
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
