// test/core/services/widget_data_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/core/services/widget_data_service.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';

void main() {
  group('WidgetDataService.filterAssignments', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 22, 10, 0, 0);
    });

    AssignmentRow makeRow({
      required String id,
      required String courseId,
      required String title,
      required int dueDateMillis,
      String? submissionState,
    }) {
      return AssignmentRow(
        id: id,
        courseId: courseId,
        title: title,
        dueDateMillis: dueDateMillis,
        submissionState: submissionState,
        state: 'published',
        description: null,
        submissionId: null,
        materialsJson: null,
        submissionAttachmentsJson: null,
      );
    }

    CourseRow makeCourse(String id, String name) => CourseRow(
          id: id,
          name: name,
          description: null,
          section: null,
          room: null,
          ownerId: null,
          courseState: 'ACTIVE',
        );

    test('未提出の将来課題のみ返す', () {
      final todayEnd = DateTime(2026, 5, 22, 23, 59, 59);
      final tomorrow = DateTime(2026, 5, 23, 23, 59, 59);
      final rows = [
        makeRow(
          id: 'a1',
          courseId: 'c1',
          title: '今日締切',
          dueDateMillis: todayEnd.millisecondsSinceEpoch,
        ),
        makeRow(
          id: 'a2',
          courseId: 'c1',
          title: '明日締切',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
        ),
        makeRow(
          id: 'a3',
          courseId: 'c1',
          title: '提出済み',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
          submissionState: 'turnedIn',
        ),
        makeRow(
          id: 'a4',
          courseId: 'c1',
          title: '期限切れ',
          dueDateMillis: DateTime(2026, 5, 21).millisecondsSinceEpoch,
        ),
      ];
      final courses = [makeCourse('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.length, 2);
      expect(result.map((e) => e['id']), containsAll(['a1', 'a2']));
    });

    test('今日締切の課題は is_today=true', () {
      final todayEnd = DateTime(2026, 5, 22, 23, 59, 59);
      final rows = [
        makeRow(
          id: 'a1',
          courseId: 'c1',
          title: '今日締切',
          dueDateMillis: todayEnd.millisecondsSinceEpoch,
        ),
      ];
      final courses = [makeCourse('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.first['is_today'], true);
    });

    test('明日以降の課題は is_today=false', () {
      final tomorrow = DateTime(2026, 5, 23, 23, 59, 59);
      final rows = [
        makeRow(
          id: 'a1',
          courseId: 'c1',
          title: '明日締切',
          dueDateMillis: tomorrow.millisecondsSinceEpoch,
        ),
      ];
      final courses = [makeCourse('c1', 'コース1')];

      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: courses,
        now: now,
      );

      expect(result.first['is_today'], false);
    });

    test('期限昇順でソートされる', () {
      final t1 = DateTime(2026, 5, 23, 10, 0);
      final t2 = DateTime(2026, 5, 22, 23, 59);
      final rows = [
        makeRow(id: 'a1', courseId: 'c1', title: '後', dueDateMillis: t1.millisecondsSinceEpoch),
        makeRow(id: 'a2', courseId: 'c1', title: '先', dueDateMillis: t2.millisecondsSinceEpoch),
      ];
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [makeCourse('c1', 'c')],
        now: now,
      );

      expect(result.first['id'], 'a2');
    });

    test('最大5件に切り詰める', () {
      final due = DateTime(2026, 5, 23, 10, 0).millisecondsSinceEpoch;
      final rows = List.generate(
        8,
        (i) => makeRow(id: 'a$i', courseId: 'c1', title: 'T$i', dueDateMillis: due + i),
      );
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [makeCourse('c1', 'c')],
        now: now,
      );

      expect(result.length, 5);
    });

    test('コース名が埋め込まれる', () {
      final rows = [
        makeRow(
          id: 'a1',
          courseId: 'c1',
          title: '課題',
          dueDateMillis: DateTime(2026, 5, 23).millisecondsSinceEpoch,
        ),
      ];
      final result = WidgetDataService.filterAssignments(
        assignmentRows: rows,
        courseRows: [makeCourse('c1', '数学')],
        now: now,
      );

      expect(result.first['course_name'], '数学');
    });
  });
}
