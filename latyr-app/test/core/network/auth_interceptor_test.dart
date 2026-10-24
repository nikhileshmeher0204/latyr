import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';

import 'recording_http_adapter.dart';

void main() {
  test(
    'AuthInterceptor: should attach Bearer token to request headers',
    () async {
      final interceptor = AuthInterceptor(
        tokenProvider: () async => 'mock-firebase-id-token-12345',
      );

      final options = RequestOptions(path: '/api/v1/captures');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(
        options.headers['Authorization'],
        equals('Bearer mock-firebase-id-token-12345'),
      );
    },
  );

  for (final token in <String?>[null, '', '  ']) {
    test('missing/blank token rejects before transport: $token', () async {
      final adapter = RecordingHttpAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(AuthInterceptor(tokenProvider: () async => token));
      addTearDown(() => dio.close());
      await expectLater(dio.get('/captures'), throwsA(isA<DioException>()));
      expect(adapter.requests, isEmpty);
    });
  }

  test(
    'provider failure removes stale credentials and blocks transport',
    () async {
      final adapter = RecordingHttpAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          tokenProvider: () async {
            throw StateError('Token refresh unavailable');
          },
        ),
      );
      addTearDown(() => dio.close());
      try {
        await dio.get(
          '/captures',
          options: Options(
            headers: {
              'authorization': 'Bearer stale-lowercase',
              'Authorization': 'Bearer stale',
            },
          ),
        );
        fail('Unauthenticated request must fail');
      } on DioException catch (error) {
        expect(error.error, isA<AuthenticationRequiredException>());
        expect(
          error.requestOptions.headers.keys.where(
            (key) => key.toLowerCase() == 'authorization',
          ),
          isEmpty,
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );

  test('each request obtains the latest valid token', () async {
    final adapter = RecordingHttpAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    var token = 'first-firebase-token';
    dio.interceptors.add(AuthInterceptor(tokenProvider: () async => token));
    addTearDown(() => dio.close());
    await dio.get('/captures');
    token = 'refreshed-firebase-token';
    await dio.get(
      '/captures',
      options: Options(headers: {'authorization': 'Bearer obsolete'}),
    );
    expect(
      adapter.requests[0].headers['Authorization'],
      'Bearer first-firebase-token',
    );
    expect(
      adapter.requests[1].headers['Authorization'],
      'Bearer refreshed-firebase-token',
    );
    expect(
      adapter.requests[1].headers.entries.where(
        (entry) => entry.key.toLowerCase() == 'authorization',
      ),
      hasLength(1),
    );
  });
}
