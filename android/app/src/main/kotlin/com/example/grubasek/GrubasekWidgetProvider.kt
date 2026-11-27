package com.example.grubasek

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class GrubasekWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val allPrefs = prefs.all

            val remainingKcal = (allPrefs["flutter.widget_remaining_kcal"] as? Number)?.toInt() ?: 1450
            val proteinText = (allPrefs["flutter.widget_protein"] as? String) ?: "85g"
            val carbsText = (allPrefs["flutter.widget_carbs"] as? String) ?: "140g"
            val waterText = (allPrefs["flutter.widget_water"] as? String) ?: "1.5 L"
            val isOver = (allPrefs["flutter.widget_is_over"] as? Boolean) ?: false

            val views = RemoteViews(context.packageName, R.layout.widget_grubasek)

            val kcalDisplay = if (isOver) "+$remainingKcal kcal" else "$remainingKcal kcal"
            views.setTextViewText(R.id.widget_calories_left, kcalDisplay)
            views.setTextViewText(
                R.id.widget_calories_subtitle,
                if (isOver) "ponad dzienny cel" else "pozostało do celu"
            )

            views.setTextViewText(R.id.widget_protein_val, proteinText)
            views.setTextViewText(R.id.widget_carbs_val, carbsText)
            views.setTextViewText(R.id.widget_water_val, waterText)

            // Click on widget opens app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, GrubasekWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (id in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }
}
