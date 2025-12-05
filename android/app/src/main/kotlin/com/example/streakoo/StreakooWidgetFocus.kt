package com.example.streakoo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.view.View
import es.antonborri.home_widget.HomeWidgetProvider

class StreakooWidgetFocus : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
    
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // When the user deletes the widget, delete the preference associated with it.
        for (appWidgetId in appWidgetIds) {
            FocusWidgetConfigActivity.deleteTitlePref(context, appWidgetId)
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences? = null
        ) {
            // Load the mode (habits, steps, sleep) selected by user
            val mode = FocusWidgetConfigActivity.loadTitlePref(context, appWidgetId)
            
            // Get data from SharedPreferences (synced from Flutter)
            // We use the passed widgetData if available, otherwise get default
            val data = widgetData ?: context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            
            val completed = data.getInt("completed_habits", 0)
            val total = data.getInt("total_habits", 0)
            val steps = data.getInt("steps", 0)
            val sleepHours = data.getFloat("sleep_hours", 7.5f) // Default 7.5h
            val sleepScore = data.getInt("sleep_score", 85)
            
            val views = RemoteViews(context.packageName, R.layout.widget_layout_focus)

            // Hide all modes first
            views.setViewVisibility(R.id.mode_habits, View.GONE)
            views.setViewVisibility(R.id.mode_steps, View.GONE)
            views.setViewVisibility(R.id.mode_sleep, View.GONE)

            when (mode) {
                "habits" -> {
                    views.setViewVisibility(R.id.mode_habits, View.VISIBLE)
                    
                    // Update Habits UI
                    val progress = if (total > 0) (completed * 100) / total else 0
                    views.setProgressBar(R.id.habit_progress_circle, 100, progress, false)
                    views.setTextViewText(R.id.habit_stats_center, "$progress%")
                    views.setTextViewText(R.id.habit_detail_text, "$completed/$total completed")
                }
                "steps" -> {
                    views.setViewVisibility(R.id.mode_steps, View.VISIBLE)
                    
                    // Update Steps UI
                    views.setTextViewText(R.id.step_count_big, String.format("%,d", steps))
                    // Assuming 10k goal for now
                    val stepProgress = (steps * 100) / 10000
                    views.setProgressBar(R.id.step_progress_bar, 100, stepProgress.coerceAtMost(100), false)
                }
                "sleep" -> {
                    views.setViewVisibility(R.id.mode_sleep, View.VISIBLE)
                    
                    // Update Sleep UI
                    val hours = sleepHours.toInt()
                    val minutes = ((sleepHours - hours) * 60).toInt()
                    views.setTextViewText(R.id.sleep_duration, "${hours}h ${minutes}m")
                    views.setTextViewText(R.id.sleep_score, "Sleep Score: $sleepScore")
                }
            }

            // Click to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
