import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';

void main() {
  test('audit reproduction: distinct query-based resources are deleted as duplicates', () async {
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    addTearDown(db.close);
    for (final suffix in ['first', 'second']) {
      await db.insertCapture(LocalCapturesCompanion(
        id: Value(suffix),
        originalUrl: Value('https://example.org/article?id=$suffix'),
        status: const Value('COMPLETED'),
      ));
    }
    expect(await db.getAllCaptures(), hasLength(2));
    await db.deduplicateCaptures();
    // This passing assertion reproduces the defect, not the desired behavior.
    expect(await db.getAllCaptures(), hasLength(1));
  });
}
