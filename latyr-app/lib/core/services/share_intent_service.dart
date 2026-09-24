import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

class ShareIntentService {
  static const _channel = MethodChannel('com.latyr.latyr_app/share');
  final CaptureRepository captureRepository;

  String? _lastHandledUrl;
  DateTime? _lastHandledAt;

  ShareIntentService({required this.captureRepository}) {
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
      if (text != null && text.isNotEmpty) {
        _handleSharedText(text);
      }
    }).catchError((e) {
      debugPrint('Error getting initial shared text: $e');
    });
  }

  void _handleSharedText(String text) {
    debugPrint('Received shared text from Android Share Sheet: $text');
    final extractedUrl = _extractUrl(text);
    if (extractedUrl != null) {
      // Debounce: prevent duplicate processing within 5 seconds for the same URL
      final now = DateTime.now();
      if (_lastHandledUrl == extractedUrl &&
          _lastHandledAt != null &&
          now.difference(_lastHandledAt!).inSeconds < 5) {
        debugPrint('Debounced duplicate share intent for URL: $extractedUrl');
        return;
      }
      _lastHandledUrl = extractedUrl;
      _lastHandledAt = now;

      String? caption = text.replaceAll(extractedUrl, '').trim();
      if (caption.isEmpty) {
        caption = null;
      }
      debugPrint('Optimistically capturing URL from share sheet: $extractedUrl (caption: $caption)');
      captureRepository.captureUrl(extractedUrl, caption: caption);
    }
  }

  String? _extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    return match?.group(0) ?? (text.startsWith('http') ? text.trim() : null);
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
