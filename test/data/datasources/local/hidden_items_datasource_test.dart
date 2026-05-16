// test/data/datasources/local/hidden_items_datasource_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/hidden_items_datasource.dart';

void main() {
  late AppDatabase db;
  late HiddenItemsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = HiddenItemsDataSource(db);
  });

  tearDown(() async => db.close());

  test('hide したアイテムが getHiddenIds に含まれる', () async {
    await ds.hide('c1', 'course');
    await ds.hide('c2', 'course');
    await ds.hide('a1', 'assignment');

    final courseIds = await ds.getHiddenIds('course');
    expect(courseIds, {'c1', 'c2'});

    final assignmentIds = await ds.getHiddenIds('assignment');
    expect(assignmentIds, {'a1'});
  });

  test('unhide したアイテムが getHiddenIds から消える', () async {
    await ds.hide('c1', 'course');
    await ds.unhide('c1');

    final ids = await ds.getHiddenIds('course');
    expect(ids, isEmpty);
  });

  test('同じ itemId を2回 hide しても重複しない', () async {
    await ds.hide('c1', 'course');
    await ds.hide('c1', 'course');

    final ids = await ds.getHiddenIds('course');
    expect(ids.length, 1);
  });
}
