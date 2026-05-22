import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classroom_remaked/data/datasources/local/app_database.dart';
import 'package:classroom_remaked/data/datasources/local/snoozed_items_datasource.dart';

void main() {
  late AppDatabase db;
  late SnoozedItemsDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = SnoozedItemsDataSource(db);
  });

  tearDown(() async => db.close());

  test('upsert した ID が getActiveSnoozed に含まれる', () async {
    final until = DateTime(2026, 5, 8, 14, 0);
    await ds.upsert('a1', until);
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map['a1'], until);
  });

  test('期限切れの ID は getActiveSnoozed に含まれない', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 10, 0));
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map, isEmpty);
  });

  test('getExpiredIds で期限切れ ID のみ返す', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 10, 0)); // expired
    await ds.upsert('a2', DateTime(2026, 5, 8, 14, 0)); // active
    final expired = await ds.getExpiredIds(DateTime(2026, 5, 8, 12, 0));
    expect(expired, {'a1'});
  });

  test('delete で ID が消える', () async {
    await ds.upsert('a1', DateTime(2026, 5, 8, 14, 0));
    await ds.delete('a1');
    final map = await ds.getActiveSnoozed(DateTime(2026, 5, 8, 12, 0));
    expect(map, isEmpty);
  });
}
