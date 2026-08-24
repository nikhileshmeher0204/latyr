import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

void main() {
  late AppDatabase db;
  late CaptureRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
    // ApiClient with dummy Dio that will fail gracefully to test offline path
    final apiClient = ApiClient(
      customDio: Dio(BaseOptions(baseUrl: 'http://localhost:8080')),
    );

    repository = CaptureRepository(
      db: db,
      apiClient: apiClient,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('CaptureRepository: offline captureUrl writes PENDING_SYNC to Drift SQLite immediately', () async {
    final capture = await repository.captureUrl('https://www.instagram.com/reel/C8xyz123/');

    expect(capture.id, isNotEmpty);
    expect(capture.originalUrl, equals('https://www.instagram.com/reel/C8xyz123/'));
    expect(capture.status, equals('PENDING_SYNC'));

    final pending = await db.getPendingSyncCaptures();
    expect(pending.length, equals(1));
    expect(pending.first.id, equals(capture.id));
  });
}
