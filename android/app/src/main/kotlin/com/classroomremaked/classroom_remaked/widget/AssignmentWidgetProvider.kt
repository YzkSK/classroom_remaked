package com.classroomremaked.classroom_remaked.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.classroomremaked.classroom_remaked.R

class AssignmentWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        val widgetData = HomeWidgetPlugin.getData(context)
        val json = widgetData.getString("widget_assignments", null)

        val itemIds = listOf(
            R.id.widget_item_0,
            R.id.widget_item_1,
            R.id.widget_item_2,
            R.id.widget_item_3,
            R.id.widget_item_4,
        )

        itemIds.forEach { views.setViewVisibility(it, View.GONE) }
        views.setViewVisibility(R.id.widget_empty, View.GONE)

        if (json == null) {
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        } else {
            val obj = JSONObject(json)
            val assignments = obj.optJSONArray("assignments")

            if (assignments == null || assignments.length() == 0) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                for (i in 0 until minOf(assignments.length(), itemIds.size)) {
                    val a = assignments.getJSONObject(i)
                    val title = a.optString("title", "")
                    val courseName = a.optString("course_name", "")
                    val isToday = a.optBoolean("is_today", false)
                    val prefix = if (isToday) "【今日】" else ""
                    views.setTextViewText(itemIds[i], "$prefix$title  $courseName")
                    views.setViewVisibility(itemIds[i], View.VISIBLE)
                }
            }
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
