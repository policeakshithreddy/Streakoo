package com.example.streakoo

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RadioButton
import android.widget.LinearLayout

class FocusWidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var selectedMode = "habits"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_widget_config)

        // Set result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(RESULT_CANCELED)

        // Find the widget ID from the intent.
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        // If this activity was started with an intent without an app widget ID, finish with an error.
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        // Setup UI
        val cardHabits = findViewById<LinearLayout>(R.id.card_habits)
        val cardSteps = findViewById<LinearLayout>(R.id.card_steps)
        val cardSleep = findViewById<LinearLayout>(R.id.card_sleep)
        
        val radioHabits = findViewById<RadioButton>(R.id.radio_habits)
        val radioSteps = findViewById<RadioButton>(R.id.radio_steps)
        val radioSleep = findViewById<RadioButton>(R.id.radio_sleep)
        
        // Default selection
        radioHabits.isChecked = true
        
        val clickListener = View.OnClickListener { view ->
            radioHabits.isChecked = false
            radioSteps.isChecked = false
            radioSleep.isChecked = false
            
            when (view.id) {
                R.id.card_habits -> {
                    selectedMode = "habits"
                    radioHabits.isChecked = true
                }
                R.id.card_steps -> {
                    selectedMode = "steps"
                    radioSteps.isChecked = true
                }
                R.id.card_sleep -> {
                    selectedMode = "sleep"
                    radioSleep.isChecked = true
                }
            }
        }

        cardHabits.setOnClickListener(clickListener)
        cardSteps.setOnClickListener(clickListener)
        cardSleep.setOnClickListener(clickListener)

        findViewById<View>(R.id.btn_save).setOnClickListener {
            // Save the selection
            saveTitlePref(this, appWidgetId, selectedMode)

            // It is the responsibility of the configuration activity to update the app widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            StreakooWidgetFocus.updateAppWidget(this, appWidgetManager, appWidgetId)

            // Make sure we pass back the original appWidgetId
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    companion object {
        private const val PREFS_NAME = "com.example.streakoo.FocusWidget"
        private const val PREF_PREFIX_KEY = "appwidget_"

        internal fun saveTitlePref(context: Context, appWidgetId: Int, text: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
            prefs.putString(PREF_PREFIX_KEY + appWidgetId, text)
            prefs.apply()
        }

        internal fun loadTitlePref(context: Context, appWidgetId: Int): String {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0)
            return prefs.getString(PREF_PREFIX_KEY + appWidgetId, "habits") ?: "habits"
        }
        
        internal fun deleteTitlePref(context: Context, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
            prefs.remove(PREF_PREFIX_KEY + appWidgetId)
            prefs.apply()
        }
    }
}
