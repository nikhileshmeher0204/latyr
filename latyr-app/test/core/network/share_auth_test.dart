import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/services/share_intent_service.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';
import 'recording_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'signed-out method-channel share queues nothing and permits retry after sign-in',
    () async {
      const channel = MethodChannel('com.latyr.latyr_app/share');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      final db = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
      final attempted = Completer<void>();
      final adapter = RecordingHttpAdapter(respond: (options) {
        attempted.complete();
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;
      var signedIn = false;
      final repository = CaptureRepository(
        db: db,
        apiClient: ApiClient(customDio: dio),
        canCapture: () => signedIn,
      );
      var signInNotices = 0;
      final service = ShareIntentService(
        canCapture: () => signedIn,
        captureUrl: (url, {caption}) async {
          await repository.captureUrl(url, caption: caption);
        },
        onAuthenticationRequired: () => signInNotices++,
      );
      addTearDown(() async {
        service.dispose();
        repository.dispose();
        dio.close();
        messenger.setMockMethodCallHandler(channel, null);
        await db.close();
      });

      Future<void> share() async {
        final reply = Completer<ByteData?>();
        ServicesBinding.instance.channelBuffers.push(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onSharedText', 'https://example.test/shared'),
          ),
          reply.complete,
        );
        const StandardMethodCodec().decodeEnvelope((await reply.future)!);
        await Future<void>.delayed(Duration.zero);
      }

      await share();
      expect(await db.getAllCaptures(), isEmpty);
      expect(adapter.requests, isEmpty);
      expect(signInNotices, 1);

      signedIn = true;
      await share();
      // Wait for the asynchronous local write and intercepted offline response.
      await repository.watchCaptures().firstWhere(
        (captures) => captures.isNotEmpty,
      );
      await attempted.future;
      await Future<void>.delayed(Duration.zero);
      expect(await db.getPendingSyncCaptures(), hasLength(1));
    },
  );
}
