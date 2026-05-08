// test/data/datasources/local/notification_logs_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/notification_logs_datasource.dart';

void main() {
  late AppDatabase db;
  late NotificationLogsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = NotificationLogsDataSource(db);
  });

  tearDown(() async => db.close());

  test('log した ID が getLoggedIds に含まれる', () async {
    await ds.log('a1');
    await ds.log('a2');
    final ids = await ds.getLoggedIds();
    expect(ids, containsAll(['a1', 'a2']));
  });

  test('同じ ID を2回 log しても重複しない', () async {
    await ds.log('a1');
    await ds.log('a1');
    final ids = await ds.getLoggedIds();
    expect(ids.length, 1);
  });

  test('delete で ID が消える', () async {
    await ds.log('a1');
    await ds.delete('a1');
    final ids = await ds.getLoggedIds();
    expect(ids, isEmpty);
  });
}
