import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'recording_http_adapter.dart';

void main() {
  test('late token from a disconnected session cannot reopen or replace a stream', () async {
    final pendingToken = Completer<String?>();
    final stream = StreamController<Uint8List>();
    final adapter = RecordingHttpAdapter(
      respond: (_) => ResponseBody(stream.stream, 200),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    var requests = 0;
    final client = SseClient(dio: dio, tokenProvider: () {
      return requests++ == 0 ? pendingToken.future : Future.value('new-session-token');
    });
    final oldConnection = client.connect();
    client.disconnect();
    await client.connect();
    pendingToken.complete('old-session-token');
    await oldConnection;
    expect(client.isConnected, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.headers['Authorization'], 'Bearer new-session-token');
    client.dispose();
    await stream.close();
    dio.close();
  });

  final providers = <String, TokenProvider?>{
    'absent': null,
    'signed out': () async => null,
    'empty': () async => '',
    'blank': () async => '  ',
    'failure': () async => throw StateError('Token unavailable'),
  };
  for (final entry in providers.entries) {
    testWidgets('SSE ${entry.key}: no transport or auth retry timer', (
      tester,
    ) async {
      final adapter = RecordingHttpAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      var attempts = 0;
      final client = SseClient(
        dio: dio,
        tokenProvider: entry.value == null
            ? null
            : () {
                attempts++;
                return entry.value!();
              },
      );
      addTearDown(client.dispose);
      addTearDown(() => dio.close());
      await client.connect();
      await tester.pump(const Duration(minutes: 1));
      expect(client.isConnected, isFalse);
      expect(adapter.requests, isEmpty);
      expect(attempts, entry.value == null ? 0 : 1);
    });
  }
  for (final status in [401, 403]) {
    testWidgets('SSE $status does not retry rejected credentials', (
      tester,
    ) async {
      final adapter = RecordingHttpAdapter(
        respond: (_) => ResponseBody.fromString('', status),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = SseClient(
        dio: dio,
        tokenProvider: () async => 'expired-token',
      );
      addTearDown(client.dispose);
      addTearDown(() => dio.close());
      await tester.runAsync(client.connect);
      await tester.pump(const Duration(minutes: 1));
      expect(adapter.requests, hasLength(1));
      expect(client.isConnected, isFalse);
    });
  }
  testWidgets('SSE explicit reconnect uses token after sign-in', (
    tester,
  ) async {
    final stream = StreamController<Uint8List>();
    final adapter = RecordingHttpAdapter(
      respond: (_) => ResponseBody(stream.stream, 200),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    String? token;
    final client = SseClient(dio: dio, tokenProvider: () async => token);
    addTearDown(() => dio.close());
    await client.connect();
    expect(adapter.requests, isEmpty);
    token = 'firebase-token';
    await tester.runAsync(client.connect);
    expect(client.isConnected, isTrue);
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer firebase-token',
    );
    client.dispose();
    await stream.close();
  });
}
