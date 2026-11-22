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

            val remainingKcal = prefs.getInt("flutter.widget_remaining_kcal", 1450)
            val proteinText = prefs.getString("flutter.widget_protein", "85g") ?: "85g"
            val carbsText = prefs.getString("flutter.widget_carbs", "140g") ?: "140g"
            val waterText = prefs.getString("flutter.widget_water", "1.5 L") ?: "1.5 L"
            val isOver = prefs.getBoolean("flutter.widget_is_over", false)

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
