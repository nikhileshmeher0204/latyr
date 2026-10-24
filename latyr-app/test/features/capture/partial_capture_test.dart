import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/widgets/latyr_capture_card.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';
import 'package:latyr_app/features/feed/presentation/screens/capture_detail_screen.dart';

void main() {
  late AppDatabase db;
  late _PartialTransport transport;
  late _Events events;
  late Dio dio;
  late CaptureRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    transport = _PartialTransport();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = transport;
    events = _Events();
    repository = CaptureRepository(db: db, apiClient: ApiClient(customDio: dio),
      sseClient: events, canCapture: () => true);
  });

  tearDown(() async {
    repository.dispose();
    await events.controller.close();
    events.dispose();
    dio.close();
    await db.close();
  });

  test('partial SSE is terminal and late processing cannot reopen it', () async {
    await _insert(db, 'PROCESSING');
    events.controller.add(SseCaptureEvent(eventType: 'CAPTURE_PARTIAL', data: {
      'capture_id': 'server', 'status': 'PARTIAL', 'error_code': 'AI_OUTCOME_UNKNOWN',
    }));
    await pumpEventQueue(times: 30);
    expect((await db.getCaptureById('local'))!.status, 'PARTIAL');
    events.controller.add(SseCaptureEvent(eventType: 'CAPTURE_PROCESSING', data: {
      'capture_id': 'server', 'status': 'PROCESSING',
    }));
    await pumpEventQueue(times: 30);
    expect((await db.getCaptureById('local'))!.status, 'PARTIAL');
    expect(await repository.hasActiveProcessingCaptures(), isFalse);
    await repository.checkProcessingCaptures();
    expect(transport.calls, 0);
  });

  test('polling persists partial and stops future processing requests', () async {
    await _insert(db, 'PROCESSING');
    await repository.checkProcessingCaptures();
    expect((await db.getCaptureById('local'))!.status, 'PARTIAL');
    await repository.checkProcessingCaptures();
    expect(transport.calls, 1);
    expect(await repository.hasActiveProcessingCaptures(), isFalse);
  });

  test('HTTP 200 partial admission is not reported completed or resubmitted', () async {
    final first = await repository.captureUrl('https://example.test/source');
    expect(first.status, 'PARTIAL');
    final second = await repository.captureUrl('https://example.test/source');
    expect(second.id, first.id);
    expect(second.status, 'PARTIAL');
    expect(transport.calls, 1);
  });

  test('queued submission respects partial status in HTTP 202 response', () async {
    transport.statusCode = 202;
    await _insert(db, 'PENDING_SYNC', serverId: null);
    await repository.syncPending();
    expect((await db.getCaptureById('local'))!.status, 'PARTIAL');
    await repository.syncPending();
    expect(transport.calls, 1);
    expect(await db.getPendingSyncCaptures(), isEmpty);
  });

  test('feed hydration keeps partial terminal state', () async {
    await repository.fetchRemoteFeed();
    expect((await db.getAllCaptures()).single.status, 'PARTIAL');
    expect(await repository.hasActiveProcessingCaptures(), isFalse);
  });

  testWidgets('partial capture card and detail explain unavailable intents without a spinner', (tester) async {
    await _insert(db, 'PARTIAL', serverId: '');
    final capture = (await db.getCaptureById('local'))!;
    await tester.pumpWidget(CupertinoApp(home: CupertinoPageScaffold(
      child: SizedBox(width: 340, height: 400, child: LatyrCaptureCard(capture: capture)),
    )));
    await tester.pumpAndSettle();
    expect(find.text('PARTIAL CAPTURE'), findsOneWidget);
    await tester.pumpWidget(ProviderScope(child: CupertinoApp(
      home: CaptureDetailScreen(capture: capture),
    )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Partial capture'), 300,
      scrollable: find.byType(Scrollable).first);
    expect(find.text('Partial capture'), findsOneWidget);
    expect(find.text('The source was saved, but useful capture intents could not be extracted.'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _insert(AppDatabase db, String status, {String? serverId = 'server'}) =>
  db.insertCapture(LocalCapturesCompanion(
    id: const Value('local'), serverCaptureId: Value(serverId), status: Value(status),
    title: const Value('Saved source'), originalUrl: const Value('https://example.test/source'),
    originalCaption: const Value('Source text'),
  ));

class _Events extends SseClient {
  final controller = StreamController<SseCaptureEvent>.broadcast();
  @override
  Stream<SseCaptureEvent> get events => controller.stream;
}

class _PartialTransport implements HttpClientAdapter {
  int calls = 0;
  int statusCode = 200;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    calls++;
    final capture = {'id': 'server', 'status': 'PARTIAL', 'title': 'Saved source',
      'original_caption': 'https://example.test/source', 'entities': <Object>[]};
    final body = options.path.endsWith('/captures') && options.method == 'GET'
      ? {'items': [capture]} : capture;
    return ResponseBody.fromString(jsonEncode(body), statusCode,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}
