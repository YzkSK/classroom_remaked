// lib/data/datasources/local/course_order_datasource.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

class CourseOrderDataSource {
  CourseOrderDataSource(this._db);

  final AppDatabase _db;

  Future<List<String>> getOrderedIds() async {
    final rows = await (_db.select(_db.courseOrders)
          ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
        .get();
    return rows.map((r) => r.courseId).toList();
  }

  Future<void> initializeNewCourses(List<String> allCourseIds) async {
    final existing = await _db.select(_db.courseOrders).get();
    final existingIds = existing.map((r) => r.courseId).toSet();
    final newIds =
        allCourseIds.where((id) => !existingIds.contains(id)).toList();
    if (newIds.isEmpty) return;

    final maxIdx = existing.isEmpty
        ? -1
        : existing.map((r) => r.sortIndex).reduce((a, b) => a > b ? a : b);

    await _db.batch((batch) {
      for (int i = 0; i < newIds.length; i++) {
        batch.insert(
          _db.courseOrders,
          CourseOrdersCompanion.insert(
            courseId: newIds[i],
            sortIndex: maxIdx + 1 + i,
          ),
        );
      }
    });
  }

  Future<void> updateOrder(List<String> orderedIds) async {
    await _db.batch((batch) {
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          _db.courseOrders,
          CourseOrdersCompanion(sortIndex: Value(i)),
          where: (t) => t.courseId.equals(orderedIds[i]),
        );
      }
    });
  }
}
