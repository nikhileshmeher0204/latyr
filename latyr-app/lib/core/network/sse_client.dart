import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  final TokenProvider? tokenProvider;
  final _eventController = StreamController<SseCaptureEvent>.broadcast();
  CancelToken? _cancelToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  Timer? _reconnectTimer;
  Duration _reconnectDelay = const Duration(seconds: 2);

  SseClient({Dio? dio, this.tokenProvider})
      : _dio = dio ??
            Dio(
              BaseOptions(
                // SSE is a long-lived stream — no receive timeout.
                // connectTimeout must be non-zero or Dio rejects immediately.
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: Duration.zero,
              ),
            );

  Stream<SseCaptureEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isDisposed || _isConnected || _isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();

    _cancelToken = CancelToken();
    try {
      final token = tokenProvider != null ? await tokenProvider!() : null;
      final headers = <String, dynamic>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final streamUrl = '${EnvironmentConfig.apiUrl}/api/v1/captures/stream';
      debugPrint('[SSE] Connecting to real-time event stream: $streamUrl');

      final response = await _dio.get<ResponseBody>(
        streamUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
        cancelToken: _cancelToken,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectDelay = const Duration(seconds: 2); // Reset backoff on success
      debugPrint('[SSE] Successfully connected to SSE stream');

      String buffer = '';

      response.data?.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
        (String text) {
          buffer += text;

          while (buffer.contains('\n\n')) {
            final splitIndex = buffer.indexOf('\n\n');
            final message = buffer.substring(0, splitIndex);
            buffer = buffer.substring(splitIndex + 2);

            _parseAndEmitSseMessage(message);
          }
        },
        onDone: () {
          debugPrint('[SSE] Stream closed by server');
          _isConnected = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onError: (err) {
          debugPrint('[SSE] Stream error: $err');
          _isConnected = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[SSE] Connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _isConnected || _isConnecting) return;
    _reconnectTimer?.cancel();
    debugPrint('[SSE] Scheduling reconnect in ${_reconnectDelay.inSeconds}s...');
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed && !_isConnected) {
        connect();
      }
    });

    // Exponential backoff capped at 16 seconds
    final nextSec = (_reconnectDelay.inSeconds * 2).clamp(2, 16);
    _reconnectDelay = Duration(seconds: nextSec);
  }

  void _parseAndEmitSseMessage(String message) {
    if (message.trim().isEmpty || message.startsWith(':')) {
      return; // Comment or heartbeat ping
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
          debugPrint('[SSE] Received event $eventType: $dataJson');
          _eventController.add(SseCaptureEvent(eventType: eventType, data: parsed));
        }
      } catch (e) {
        debugPrint('[SSE] Failed to decode event JSON: $e');
      }
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _cancelToken?.cancel('Disconnected by client');
    _isConnected = false;
    _isConnecting = false;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
  }
}
