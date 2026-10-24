
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

void main() {
  test('disposing during final read cannot return a stale capture', () async {
    final localDb = _PausedReadDatabase();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _OfflineAdapter();
    final repo = CaptureRepository(db: localDb,
      apiClient: ApiClient(customDio: dio), canCapture: () => true);
    final pending = repo.captureUrl('https://example.test/article');
    await localDb.readStarted.future;
    repo.dispose();
    final result = expectLater(pending, throwsA(isA<AuthenticationRequiredException>()));
    localDb.releaseRead.complete();
    await result;
    expect(await localDb.getPendingSyncCaptures(), hasLength(1));
    await localDb.close();
    dio.close();
  });

  test('logout during API response cannot apply stale completion', () async {
    final localDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final adapter = _PausedResponseAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    var active = true;
    final repo = CaptureRepository(db: localDb,
      apiClient: ApiClient(customDio: dio), canCapture: () => active);
    final pending = repo.captureUrl('https://example.test/article');
    await adapter.started.future;
    active = false;
    final result = expectLater(pending, throwsA(isA<AuthenticationRequiredException>()));
    adapter.response.complete(ResponseBody.fromString('{"id":"server","status":"PENDING"}', 202,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]}));
    await result;
    expect((await localDb.getPendingSyncCaptures()).single.serverCaptureId, null);
    repo.dispose();
    await localDb.close();
    dio.close();
  });

  late AppDatabase db;
  late CaptureRepository repository;
  late _OfflineAdapter transport;
  late bool signedIn;

  setUp(() {
    signedIn = true;
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    transport = _OfflineAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = transport;
    repository = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: dio),
      canCapture: () => signedIn,
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  test(
    'authenticated offline capture persists for later sync without real HTTP',
    () async {
      final capture = await repository.captureUrl(
        'https://example.test/article',
      );
      expect(capture.status, 'PENDING_SYNC');
      expect((await db.getPendingSyncCaptures()).single.id, capture.id);
      expect(transport.calls, 1);
    },
  );

  test(
    'signed-out capture does not return existing capture, queue or send',
    () async {
      await db.insertCapture(
        LocalCapturesCompanion(
          id: const Value('existing'),
          originalUrl: const Value('https://example.test/article'),
          status: const Value('COMPLETED'),
        ),
      );
      signedIn = false;
      await expectLater(
        repository.captureUrl('https://example.test/article'),
        throwsA(isA<AuthenticationRequiredException>()),
      );
      expect(await db.getPendingSyncCaptures(), isEmpty);
      expect(await db.getAllCaptures(), hasLength(1));
      expect(transport.calls, 0);
    },
  );

  test('signed-out sync does not dispatch or remove queued work', () async {
    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('pending'),
        originalUrl: const Value('https://example.test/article'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
      ),
    );
    signedIn = false;
    await repository.syncPending();
    expect(transport.calls, 0);
    expect(await db.getPendingSyncCaptures(), hasLength(1));
  });
}

class _PausedReadDatabase extends AppDatabase {
  final readStarted = Completer<void>();
  final releaseRead = Completer<void>();
  _PausedReadDatabase() : super.forTesting(DatabaseConnection(NativeDatabase.memory()));

  @override
  Future<LocalCapture?> getCaptureById(String id) async {
    final capture = await super.getCaptureById(id);
    readStarted.complete();
    await releaseRead.future;
    return capture;
  }
}

class _PausedResponseAdapter implements HttpClientAdapter {
  final started = Completer<void>();
  final response = Completer<ResponseBody>();
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) {
    started.complete();
    return response.future;
  }
  @override
  void close({bool force = false}) {}
}

class _OfflineAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
