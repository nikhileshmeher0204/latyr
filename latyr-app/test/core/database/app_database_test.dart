import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('LocalCaptures: should insert PENDING_SYNC capture and retrieve it', () async {
    final entry = LocalCapturesCompanion(
      id: const Value('test-uuid-1'),
      originalUrl: const Value('https://www.instagram.com/reel/C8xyz123/'),
      contentType: const Value('URL'),
      status: const Value('PENDING_SYNC'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    await db.insertCapture(entry);

    final pending = await db.getPendingSyncCaptures();
    expect(pending.length, equals(1));
    expect(pending.first.id, equals('test-uuid-1'));
    expect(pending.first.status, equals('PENDING_SYNC'));
  });

  test('LocalCaptures: watchAllCaptures stream should reactively emit on insert and update', () async {
    final stream = db.watchAllCaptures();

    expect(
      stream,
      emitsInOrder([
        isEmpty,
        hasLength(1),
        predicate<List<LocalCapture>>((list) => list.first.status == 'COMPLETED'),
      ]),
    );

    // Initial empty state is emitted
    await pumpEventQueue();

    // 1. Insert item
    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('test-uuid-2'),
        originalUrl: const Value('https://www.instagram.com/reel/test/'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // 2. Update item to COMPLETED
    await db.updateCapture(
      LocalCapturesCompanion(
        id: const Value('test-uuid-2'),
        status: const Value('COMPLETED'),
        intent: const Value('WATCH'),
        category: const Value('Entertainment'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });
}
