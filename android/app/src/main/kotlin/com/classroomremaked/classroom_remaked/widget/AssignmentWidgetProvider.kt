package com.classroomremaked.classroom_remaked.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.classroomremaked.classroom_remaked.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

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

        val rowIds = listOf(
            Triple(R.id.widget_row_0, R.id.widget_title_0, R.id.widget_course_0) to Pair(R.id.widget_due_0, R.id.widget_divider_0),
            Triple(R.id.widget_row_1, R.id.widget_title_1, R.id.widget_course_1) to Pair(R.id.widget_due_1, R.id.widget_divider_1),
            Triple(R.id.widget_row_2, R.id.widget_title_2, R.id.widget_course_2) to Pair(R.id.widget_due_2, R.id.widget_divider_2),
            Triple(R.id.widget_row_3, R.id.widget_title_3, R.id.widget_course_3) to Pair(R.id.widget_due_3, R.id.widget_divider_3),
            Triple(R.id.widget_row_4, R.id.widget_title_4, R.id.widget_course_4) to Pair(R.id.widget_due_4, null),
        )

        rowIds.forEach { (row, due) ->
            views.setViewVisibility(row.first, View.GONE)
            views.setViewVisibility(due.first, View.GONE)
            due.second?.let { views.setViewVisibility(it, View.GONE) }
        }
        views.setViewVisibility(R.id.widget_empty, View.GONE)

        if (json == null) {
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        } else {
            val obj = JSONObject(json)
            val assignments = obj.optJSONArray("assignments")

            if (assignments == null || assignments.length() == 0) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                val count = minOf(assignments.length(), rowIds.size)
                for (i in 0 until count) {
                    val a = assignments.getJSONObject(i)
                    val (row, due) = rowIds[i]

                    views.setTextViewText(row.second, a.optString("title", ""))
                    views.setTextViewText(row.third, a.optString("course_name", ""))
                    views.setViewVisibility(row.first, View.VISIBLE)

                    val dueDateMillis = a.optLong("due_millis", 0L)
                    val (label, color) = formatDue(dueDateMillis)
                    views.setTextViewText(due.first, label)
                    views.setTextColor(due.first, color)
                    views.setViewVisibility(due.first, View.VISIBLE)

                    // 最後の行以外は仕切りを表示
                    due.second?.let {
                        if (i < count - 1) views.setViewVisibility(it, View.VISIBLE)
                    }
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

    private fun formatDue(millis: Long): Pair<String, Int> {
        if (millis == 0L) return Pair("", Color.parseColor("#888888"))
        val date = Date(millis)
        val cal = Calendar.getInstance().apply { time = date }
        val today = Calendar.getInstance()
        val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }

        val timeFmt = SimpleDateFormat("HH:mm", Locale.JAPAN)
        return when {
            isSameDay(cal, today) ->
                Pair("今日 ${timeFmt.format(date)}", Color.parseColor("#E53935"))
            isSameDay(cal, tomorrow) ->
                Pair("明日 ${timeFmt.format(date)}", Color.parseColor("#F57C00"))
            else -> {
                val dateFmt = SimpleDateFormat("M/d(E)", Locale.JAPAN)
                Pair(dateFmt.format(date), Color.parseColor("#888888"))
            }
        }
    }

    private fun isSameDay(a: Calendar, b: Calendar): Boolean =
        a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
        a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
}
