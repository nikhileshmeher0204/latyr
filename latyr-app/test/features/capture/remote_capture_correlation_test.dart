import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

void main() {
  const url = 'https://example.test/shared-resource';
  for (final delivery in ['feed', 'CAPTURE_PROCESSING', 'CAPTURE_COMPLETED']) {
    for (final scenario in ['bound', 'image', 'ambiguous', 'unique']) {
      test(
        '$delivery correlates only a unique unbound URL: $scenario',
        () async {
          final db = AppDatabase.forTesting(
            DatabaseConnection(NativeDatabase.memory()),
          );
          final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
            ..httpClientAdapter = _FeedAdapter(url);
          final sse = _ControlledSse();
          final repo = CaptureRepository(
            db: db,
            apiClient: ApiClient(customDio: dio),
            sseClient: sse,
            canCapture: () => true,
          );
          try {
            await db.insertCapture(
              LocalCapturesCompanion(
                id: const Value('original'),
                originalUrl: const Value(url),
                serverCaptureId: Value(
                  scenario == 'bound' ? 'server-original' : null,
                ),
                contentType: Value(scenario == 'image' ? 'IMAGE' : 'URL'),
                status: const Value('PENDING_SYNC'),
                title: const Value('Personal title'),
                entitiesJson: const Value('[{"title":"Preserve me"}]'),
              ),
            );
            if (scenario == 'ambiguous') {
              await db.insertCapture(
                const LocalCapturesCompanion(
                  id: Value('second-pending'),
                  originalUrl: Value(url),
                  serverCaptureId: Value(''),
                  title: Value('Second title'),
                ),
              );
            }
            final before = await db.getAllCaptures();
            if (delivery == 'feed') {
              await repo.fetchRemoteFeed();
            } else {
              sse.controller.add(
                SseCaptureEvent(
                  eventType: delivery,
                  data: {
                    'capture_id': 'server-new',
                    'original_caption': url,
                    'title': 'Remote title',
                    'entities': <Object>[],
                  },
                ),
              );
              await pumpEventQueue(times: 30);
            }
            if (scenario == 'unique') {
              final row = await db.getCaptureById('original');
              expect(row!.serverCaptureId, 'server-new');
              expect(await db.getAllCaptures(), hasLength(1));
            } else {
              for (final row in before) {
                expect(
                  await db.getCaptureById(row.id),
                  row,
                  reason:
                      'Unrelated or ambiguous local data must remain intact',
                );
              }
              expect(
                await db.getAllCaptures(),
                hasLength(
                  before.length + (delivery == 'CAPTURE_PROCESSING' ? 0 : 1),
                ),
              );
            }
          } finally {
            repo.dispose();
            await sse.controller.close();
            sse.dispose();
            dio.close();
            await db.close();
          }
        },
      );
    }
  }
}

class _ControlledSse extends SseClient {
  final controller = StreamController<SseCaptureEvent>.broadcast();
  @override
  Stream<SseCaptureEvent> get events => controller.stream;
}

class _FeedAdapter implements HttpClientAdapter {
  final String url;
  _FeedAdapter(this.url);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(
      options.path.endsWith('/server-new')
          ? {'entities': <Object>[]}
          : {
              'items': [
                {
                  'id': 'server-new',
                  'original_caption': url,
                  'title': 'Remote title',
                  'status': 'COMPLETED',
                },
              ],
            },
    ),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}
