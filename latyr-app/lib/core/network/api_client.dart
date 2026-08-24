import 'dart:io';

import 'package:dio/dio.dart';
import 'package:latyr_app/config/environment_config.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? customDio, TokenProvider? tokenProvider})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: EnvironmentConfig.apiUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (tokenProvider != null) {
      dio.interceptors.add(AuthInterceptor(tokenProvider: tokenProvider));
    }
  }

  Future<Response<Map<String, dynamic>>> createCapture(String url) async {
    return dio.post<Map<String, dynamic>>(
      '/api/v1/captures',
      data: {'url': url, 'content_type': 'URL'},
    );
  }

  Future<Response<Map<String, dynamic>>> uploadImageCapture(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    return dio.post<Map<String, dynamic>>(
      '/api/v1/captures/upload',
      data: formData,
    );
  }

  Future<Response<Map<String, dynamic>>> getCaptures({
    int page = 0,
    int size = 20,
    String? status,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
    };

    return dio.get<Map<String, dynamic>>(
      '/api/v1/captures',
      queryParameters: queryParams,
    );
  }

  Future<Response<Map<String, dynamic>>> getCaptureDetail(String id) async {
    return dio.get<Map<String, dynamic>>('/api/v1/captures/$id');
  }

  Future<Response<Map<String, dynamic>>> updateEntity(
    String entityId,
    Map<String, dynamic> updatePayload,
  ) async {
    return dio.patch<Map<String, dynamic>>(
      '/api/v1/entities/$entityId',
      data: updatePayload,
    );
  }
}
