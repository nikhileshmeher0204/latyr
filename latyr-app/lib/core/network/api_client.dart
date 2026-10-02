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
                baseUrl: '${EnvironmentConfig.apiUrl}/api/v1',
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

  Future<Response<Map<String, dynamic>>> createCapture(String url, {String? caption}) async {
    final payload = <String, dynamic>{
      'url': url,
      'content_type': 'URL',
    };
    if (caption != null && caption.trim().isNotEmpty) {
      payload['caption'] = caption.trim();
    }
    return dio.post<Map<String, dynamic>>(
      '/captures',
      data: payload,
    );
  }

  Future<Response<Map<String, dynamic>>> uploadImageCapture(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    return dio.post<Map<String, dynamic>>(
      '/captures/upload',
      data: formData,
    );
  }

  Future<Response<Map<String, dynamic>>> getWeatherContext(double? lat, double? lon) async {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lon != null) params['lon'] = lon;
    return dio.get<Map<String, dynamic>>('/context/weather', queryParameters: params);
  }

  Future<Response<Map<String, dynamic>>> getCaptures({
    int page = 0,
    int size = 20,
    String? status,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      ...?status != null ? {'status': status} : null,
      ...?category != null ? {'category': category} : null,
    };

    return dio.get<Map<String, dynamic>>(
      '/captures',
      queryParameters: queryParams,
    );
  }

  Future<Response<Map<String, dynamic>>> getCaptureDetail(String id) async {
    return dio.get<Map<String, dynamic>>('/captures/$id');
  }

  Future<Response<Map<String, dynamic>>> updateEntity(
    String entityId,
    Map<String, dynamic> updatePayload,
  ) async {
    return dio.patch<Map<String, dynamic>>(
      '/entities/$entityId',
      data: updatePayload,
    );
  }
}



