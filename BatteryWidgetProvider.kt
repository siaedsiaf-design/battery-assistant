package com.batteryassistant

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.widget.RemoteViews

class BatteryWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Read live battery state from system broadcast
        val batteryIntent = context.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )

        val level  = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale  = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val pct    = if (level != -1 && scale != -1) (level * 100 / scale) else 0
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING
                      || status == BatteryManager.BATTERY_STATUS_FULL

        // Build human-readable status string
        val statusText = when {
            isCharging && pct >= 100 -> "⚡ Full — Unplug!"
            isCharging               -> "⚡ Charging"
            pct <= 5                 -> "🔴 EMERGENCY"
            pct <= 10                -> "🔴 Critical"
            pct <= 20                -> "🟡 Low"
            else                     -> "🟢 Good"
        }

        // Push to every widget instance on home screen
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.battery_widget_layout)
            views.setTextViewText(R.id.widget_battery_pct, "$pct%")
            views.setTextViewText(R.id.widget_status, statusText)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
