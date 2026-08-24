import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:latyr_app/config/environment_config.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';

class SseCaptureEvent {
  final String eventType;
  final Map<String, dynamic> data;

  SseCaptureEvent({required this.eventType, required this.data});

  @override
  String toString() => 'SseCaptureEvent(type: $eventType, data: $data)';
}

class SseClient {
  final Dio _dio;
  final TokenProvider? _tokenProvider;
  final _eventController = StreamController<SseCaptureEvent>.broadcast();
  CancelToken? _cancelToken;
  bool _isConnected = false;

  SseClient({Dio? dio, TokenProvider? tokenProvider})
      : _dio = dio ?? Dio(),
        _tokenProvider = tokenProvider;

  Stream<SseCaptureEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    _cancelToken = CancelToken();
    try {
      final token = _tokenProvider != null ? await _tokenProvider() : null;
      final headers = <String, dynamic>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await _dio.get<ResponseBody>(
        '${EnvironmentConfig.apiUrl}/api/v1/captures/stream',
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
        cancelToken: _cancelToken,
      );

      _isConnected = true;
      String buffer = '';

      response.data?.stream.listen(
        (Uint8List chunk) {
          final text = utf8.decode(chunk);
          buffer += text;

          while (buffer.contains('\n\n')) {
            final splitIndex = buffer.indexOf('\n\n');
            final message = buffer.substring(0, splitIndex);
            buffer = buffer.substring(splitIndex + 2);

            _parseAndEmitSseMessage(message);
          }
        },
        onDone: () {
          _isConnected = false;
        },
        onError: (err) {
          _isConnected = false;
        },
        cancelOnError: true,
      );
    } catch (_) {
      _isConnected = false;
    }
  }

  void _parseAndEmitSseMessage(String message) {
    if (message.trim().isEmpty || message.startsWith(':')) {
      return; // Comment or ping
    }

    String eventType = 'MESSAGE';
    String dataJson = '';

    final lines = message.split('\n');
    for (final line in lines) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataJson = line.substring(5).trim();
      }
    }

    if (dataJson.isNotEmpty) {
      try {
        final parsed = jsonDecode(dataJson);
        if (parsed is Map<String, dynamic>) {
          _eventController.add(SseCaptureEvent(eventType: eventType, data: parsed));
        }
      } catch (_) {}
    }
  }

  void disconnect() {
    _cancelToken?.cancel('Disconnected by client');
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
