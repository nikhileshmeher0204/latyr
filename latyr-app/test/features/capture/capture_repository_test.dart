
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  test('syncPending preserves caption and transitions successfully on 200', () async {
    RequestOptions? capturedOptions;
    final adapter = _CustomResponseAdapter((options) {
      capturedOptions = options;
      return ResponseBody.fromString(
        '{"id":"server-123","status":"COMPLETED","category":"TECH"}',
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    });
    final customDio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    final customRepo = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: customDio),
      canCapture: () => true,
    );

    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('item-1'),
        originalUrl: const Value('https://example.test/tech'),
        originalCaption: const Value('My custom caption'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
      ),
    );

    await customRepo.syncPending();

    expect(capturedOptions, isNotNull);
    final sentData = capturedOptions!.data as Map<String, dynamic>;
    expect(sentData['caption'], 'My custom caption');

    final updated = await db.getCaptureById('item-1');
    expect(updated?.status, 'COMPLETED');
    expect(updated?.serverCaptureId, 'server-123');
    expect(await db.getPendingSyncCaptures(), isEmpty);
  });

  test('syncPending classifies 402 QUOTA_EXCEEDED as FAILED and stops retrying', () async {
    final adapter = _CustomResponseAdapter((options) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 402,
          data: {'error': 'QUOTA_EXCEEDED', 'message': 'Monthly limit reached'},
        ),
        type: DioExceptionType.badResponse,
      );
    });
    final customDio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    final customRepo = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: customDio),
      canCapture: () => true,
    );

    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('item-quota'),
        originalUrl: const Value('https://example.test/item'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
      ),
    );

    await customRepo.syncPending();

    final updated = await db.getCaptureById('item-quota');
    expect(updated?.status, 'FAILED');
    expect(updated?.summary, contains('Monthly limit reached'));
    expect(await db.getPendingSyncCaptures(), isEmpty);
  });

  test('syncPending classifies 400 Bad Request as FAILED', () async {
    final adapter = _CustomResponseAdapter((options) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'error': 'INVALID_URL', 'message': 'Invalid destination URL'},
        ),
        type: DioExceptionType.badResponse,
      );
    });
    final customDio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    final customRepo = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: customDio),
      canCapture: () => true,
    );

    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('item-invalid'),
        originalUrl: const Value('http://localhost:8080/private'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
      ),
    );

    await customRepo.syncPending();

    final updated = await db.getCaptureById('item-invalid');
    expect(updated?.status, 'FAILED');
    expect(await db.getPendingSyncCaptures(), isEmpty);
  });

  test('syncPending on transient 500 server error leaves capture PENDING_SYNC for retry', () async {
    final adapter = _CustomResponseAdapter((options) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 500,
          data: {'error': 'INTERNAL_ERROR'},
        ),
        type: DioExceptionType.badResponse,
      );
    });
    final customDio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter;
    final customRepo = CaptureRepository(
      db: db,
      apiClient: ApiClient(customDio: customDio),
      canCapture: () => true,
    );

    await db.insertCapture(
      LocalCapturesCompanion(
        id: const Value('item-transient'),
        originalUrl: const Value('https://example.test/item'),
        contentType: const Value('URL'),
        status: const Value('PENDING_SYNC'),
      ),
    );

    await customRepo.syncPending();

    final updated = await db.getCaptureById('item-transient');
    expect(updated?.status, 'PENDING_SYNC');
    expect(await db.getPendingSyncCaptures(), hasLength(1));
  });

  test('ApiClient getCaptures transmits page and size in query parameters', () async {
    RequestOptions? capturedOptions;
    final adapter = _CustomResponseAdapter((options) {
      capturedOptions = options;
      return ResponseBody.fromString('{"items":[],"total_pages":1}', 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
    });
    final client = ApiClient(customDio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))..httpClientAdapter = adapter);
    await client.getCaptures(page: 3, size: 50);

    expect(capturedOptions, isNotNull);
    expect(capturedOptions!.queryParameters['page'], 3);
    expect(capturedOptions!.queryParameters['size'], 50);
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

class _CustomResponseAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  _CustomResponseAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}