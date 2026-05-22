// lib/core/services/widget_data_service.dart
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../../data/datasources/local/app_database.dart';

const _widgetDataKey = 'widget_assignments';
const _appGroupId = 'group.com.classroomremaked.classroomRemaked';
const _iOSWidgetName = 'AssignmentWidget';
const _androidWidgetName = 'AssignmentWidgetProvider';
const _androidQualifiedName =
    'com.classroomremaked.classroom_remaked.widget.AssignmentWidgetProvider';

class WidgetDataService {
  const WidgetDataService();

  Future<void> updateWidget(AppDatabase db) async {
    await HomeWidget.setAppGroupId(_appGroupId);

    final now = DateTime.now();
    final assignmentRows = await db.select(db.assignments).get();
    final courseRows = await db.select(db.courses).get();

    final filtered = filterAssignments(
      assignmentRows: assignmentRows,
      courseRows: courseRows,
      now: now,
    );

    final payload = {
      'updated_at': now.toIso8601String(),
      'assignments': filtered,
    };

    await HomeWidget.saveWidgetData<String>(_widgetDataKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
      qualifiedAndroidName: _androidQualifiedName,
    );
  }

  static List<Map<String, dynamic>> filterAssignments({
    required List<AssignmentRow> assignmentRows,
    required List<CourseRow> courseRows,
    required DateTime now,
    int maxCount = 5,
  }) {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final courseNames = {for (final c in courseRows) c.id: c.name};

    final filtered = assignmentRows
        .where((r) =>
            r.submissionState != 'turnedIn' && r.dueDateMillis != null)
        .map((r) {
          final due = DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!);
          return MapEntry(r, due);
        })
        .where((e) => e.value.isAfter(now))
        .map((e) => <String, dynamic>{
              'id': e.key.id,
              'course_id': e.key.courseId,
              'title': e.key.title,
              'course_name': courseNames[e.key.courseId] ?? '',
              'due_millis': e.key.dueDateMillis,
              'is_today': !e.value.isAfter(endOfToday),
            })
        .toList();

    filtered.sort(
        (a, b) => (a['due_millis'] as int).compareTo(b['due_millis'] as int));
    return filtered.take(maxCount).toList();
  }
}
