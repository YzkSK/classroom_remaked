package com.classroomremaked.classroom_remaked.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import com.classroomremaked.classroom_remaked.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

private const val TAG = "AssignmentWidget"

class AssignmentWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called, ids=${appWidgetIds.toList()}")
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "updateWidget id=$appWidgetId")
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        try {
            val rowIds    = intArrayOf(R.id.widget_row_0,    R.id.widget_row_1,    R.id.widget_row_2,    R.id.widget_row_3,    R.id.widget_row_4)
            val titleIds  = intArrayOf(R.id.widget_title_0,  R.id.widget_title_1,  R.id.widget_title_2,  R.id.widget_title_3,  R.id.widget_title_4)
            val courseIds = intArrayOf(R.id.widget_course_0, R.id.widget_course_1, R.id.widget_course_2, R.id.widget_course_3, R.id.widget_course_4)
            val dueIds    = intArrayOf(R.id.widget_due_0,    R.id.widget_due_1,    R.id.widget_due_2,    R.id.widget_due_3,    R.id.widget_due_4)
            val dividerIds = intArrayOf(R.id.widget_divider_0, R.id.widget_divider_1, R.id.widget_divider_2, R.id.widget_divider_3)

            for (i in rowIds.indices) {
                views.setViewVisibility(rowIds[i], View.GONE)
                views.setViewVisibility(dueIds[i], View.GONE)
            }
            for (id in dividerIds) views.setViewVisibility(id, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.GONE)

            val widgetData = HomeWidgetPlugin.getData(context)
            val json = widgetData.getString("widget_assignments", null)
            Log.d(TAG, "json=${json?.take(100)}")

            if (json == null) {
                Log.d(TAG, "no data, showing empty")
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
                        views.setTextViewText(titleIds[i],  a.optString("title", ""))
                        views.setTextViewText(courseIds[i], a.optString("course_name", ""))
                        views.setViewVisibility(rowIds[i], View.VISIBLE)

                        val (label, color) = formatDue(a.optLong("due_millis", 0L))
                        views.setTextViewText(dueIds[i], label)
                        views.setTextColor(dueIds[i], color)
                        views.setViewVisibility(dueIds[i], View.VISIBLE)

                        if (i < count - 1 && i < dividerIds.size) {
                            views.setViewVisibility(dividerIds[i], View.VISIBLE)
                        }

                        val assignmentId = a.optString("id", "")
                        if (assignmentId.isNotEmpty()) {
                            val uri = Uri.parse("classroomremaked://assignment?id=$assignmentId")
                            val rowIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                                data = uri
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            }
                            if (rowIntent != null) {
                                val rowPending = PendingIntent.getActivity(
                                    context, i + 1, rowIntent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                                views.setOnClickPendingIntent(rowIds[i], rowPending)
                            }
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
        } catch (e: Exception) {
            Log.e(TAG, "exception in updateWidget", e)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        }

        Log.d(TAG, "calling updateAppWidget id=$appWidgetId")
        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d(TAG, "updateAppWidget done")
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
