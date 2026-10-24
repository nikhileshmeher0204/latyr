import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';

class ShareIntentService {
  static const _channel = MethodChannel('com.latyr.latyr_app/share');
  final FutureOr<bool> Function() canCapture;
  final Future<void> Function(String url, {String? caption}) captureUrl;
  final void Function() onAuthenticationRequired;
  bool _disposed = false;

  String? _lastHandledUrl;
  DateTime? _lastHandledAt;

  ShareIntentService({required this.canCapture, required this.captureUrl,
    required this.onAuthenticationRequired}) {
    _init();
  }

  void _init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _handleSharedText(text);
        }
      }
    });

    // Check for initial shared text when launched from cold start
    _channel.invokeMethod<String>('getInitialSharedText').then((text) {
      if (!_disposed && text != null && text.isNotEmpty) {
        _handleSharedText(text);
      }
    }).catchError((e) {
      debugPrint('Error getting initial shared text: $e');
    });
  }

  Future<void> _handleSharedText(String text) async {
    if (_disposed) return;
    if (!await canCapture()) {
      onAuthenticationRequired();
      return;
    }
    final extractedUrl = _extractUrl(text);
    if (extractedUrl != null) {
      // Debounce: prevent duplicate processing within 5 seconds for the same URL
      final now = DateTime.now();
      if (_lastHandledUrl == extractedUrl &&
          _lastHandledAt != null &&
          now.difference(_lastHandledAt!).inSeconds < 5) {
        return;
      }
      _lastHandledUrl = extractedUrl;
      _lastHandledAt = now;

      String? caption = text.replaceAll(extractedUrl, '').trim();
      if (caption.isEmpty) {
        caption = null;
      }
      try {
        await captureUrl(extractedUrl, caption: caption);
      } on AuthenticationRequiredException {
        _lastHandledUrl = null;
        _lastHandledAt = null;
        if (!_disposed) onAuthenticationRequired();
      } catch (e, st) {
        debugPrint('Error capturing shared URL: $e\n$st');
      }
    }
  }

  String? _extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    return match?.group(0) ?? (text.startsWith('http') ? text.trim() : null);
  }

  void dispose() {
    _disposed = true;
    _channel.setMethodCallHandler(null);
  }
}
