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
    String? subCategory,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'status': ?status,
      'category': ?category,
      'subCategory': ?subCategory,
    };

    return dio.get<Map<String, dynamic>>(
      '/captures',
      queryParameters: queryParams,
    );
  }

  Future<Response<Map<String, dynamic>>> getTaxonomy() async {
    return dio.get<Map<String, dynamic>>('/captures/taxonomy');
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

  // --- Personal Curated Collections API ---

  Future<Response<List<dynamic>>> getUserCollections() async {
    return dio.get<List<dynamic>>('/collections');
  }

  Future<Response<Map<String, dynamic>>> getCollectionById(String id) async {
    return dio.get<Map<String, dynamic>>('/collections/$id');
  }

  Future<Response<Map<String, dynamic>>> createCollection({
    required String name,
    String? description,
    String? icon,
    String? colorHex,
  }) async {
    return dio.post<Map<String, dynamic>>(
      '/collections',
      data: {
        'name': name,
        'description': ?description,
        'icon': ?icon,
        'colorHex': ?colorHex,
      },
    );
  }

  Future<Response<Map<String, dynamic>>> updateCollection(
    String id, {
    String? name,
    String? description,
    String? icon,
    String? colorHex,
    bool? isPinned,
  }) async {
    return dio.patch<Map<String, dynamic>>(
      '/collections/$id',
      data: {
        'name': ?name,
        'description': ?description,
        'icon': ?icon,
        'colorHex': ?colorHex,
        'isPinned': ?isPinned,
      },
    );
  }

  Future<Response<void>> deleteCollection(String id) async {
    return dio.delete<void>('/collections/$id');
  }

  Future<Response<List<dynamic>>> getCollectionEntities(String collectionId) async {
    return dio.get<List<dynamic>>('/collections/$collectionId/entities');
  }

  Future<Response<void>> addEntityToCollection(String collectionId, String entityId) async {
    return dio.post<void>('/collections/$collectionId/entities/$entityId');
  }

  Future<Response<void>> removeEntityFromCollection(String collectionId, String entityId) async {
    return dio.delete<void>('/collections/$collectionId/entities/$entityId');
  }

  Future<Response<List<dynamic>>> getEntityCollections(String entityId) async {
    return dio.get<List<dynamic>>('/entities/$entityId/collections');
  }
}
