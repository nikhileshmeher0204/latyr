import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';

void main() {
  test('AuthInterceptor: should attach Bearer token to request headers', () async {
    final interceptor = AuthInterceptor(
      tokenProvider: () async => 'mock-firebase-id-token-12345',
    );

    final options = RequestOptions(path: '/api/v1/captures');
    final handler = RequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers['Authorization'], equals('Bearer mock-firebase-id-token-12345'));
  });

  test('AuthInterceptor: should not fail when token provider returns null', () async {
    final interceptor = AuthInterceptor(
      tokenProvider: () async => null,
    );

    final options = RequestOptions(path: '/api/v1/captures');
    final handler = RequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers.containsKey('Authorization'), isFalse);
  });
}
