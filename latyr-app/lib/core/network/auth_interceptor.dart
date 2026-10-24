import 'package:dio/dio.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';

typedef TokenProvider = Future<String?> Function();

class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;

  AuthInterceptor({required this.tokenProvider});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.removeWhere(
      (key, _) => key.toLowerCase() == 'authorization',
    );
    try {
      final token = await tokenProvider();
      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      }
    } catch (_) {
      // Token failures must never fall through to an unauthenticated request.
    }
    return handler.reject(
      DioException(
        requestOptions: options,
        error: const AuthenticationRequiredException(),
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Unauthorized: Trigger token refresh or re-auth if needed
    }
    return handler.next(err);
  }
}
