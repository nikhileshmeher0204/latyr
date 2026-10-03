import 'package:latyr_app/core/enums/capture_source.dart';

/// Client-side classifier for detecting capture source from URLs or share text.
class CaptureSourceClassifier {
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"]+|www\.[^\s<>"]+',
    caseSensitive: false,
  );

  static const Set<String> _trackingParams = {
    'igsh',
    'stkn',
    'si',
    'ref',
    'ref_src',
    'feature',
    'context',
    'mibextid',
    'fbclid',
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'gclid',
    'dclid',
  };

  /// Extracts the first HTTP(S) URL from dirty share text (e.g. "Check out this reel https://...").
  static String? extractFirstUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _urlRegex.firstMatch(text.trim());
    return match?.group(0);
  }

  /// Strips tracking and analytics parameters from query string while preserving essential routing parameters.
  static String normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    try {
      final uri = Uri.parse(trimmed);
      final cleanQuery = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((k, _) => _trackingParams.contains(k.toLowerCase()));

      var path = uri.path;
      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }

      final cleanUri = Uri(
        scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
        host: uri.host.replaceFirst(RegExp(r'^www\.'), ''),
        port: (uri.port == 80 || uri.port == 443) ? null : (uri.hasPort ? uri.port : null),
        path: path,
        queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
      );

      return cleanUri.toString();
    } catch (_) {
      return trimmed;
    }
  }

  /// Classifies a raw URL or dirty share string into a [CaptureSource].
  ///
  /// Returns `null` if the text cannot be classified or contains no valid URL.
  static CaptureSource? classify(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final urlCandidate = extractFirstUrl(raw) ?? raw.trim();

    try {
      final uri = Uri.parse(urlCandidate);
      final host = (uri.host.isEmpty ? '' : uri.host).toLowerCase();
      final cleanHost = host.replaceFirst(RegExp(r'^www\.'), '');
      final path = uri.path.toLowerCase();

      // 1. Instagram
      if (cleanHost == 'instagram.com' || cleanHost == 'instagr.am' || cleanHost.endsWith('.instagram.com')) {
        // As per requirements: treat both Instagram reels and posts as instagramReel
        return CaptureSource.instagramReel;
      }

      // 2. YouTube
      if (cleanHost == 'youtube.com' || cleanHost == 'm.youtube.com' || cleanHost == 'youtu.be' || cleanHost.endsWith('.youtube.com')) {
        if (path.contains('/shorts/')) {
          return CaptureSource.youtubeShort;
        }
        return CaptureSource.youtubeVideo;
      }

      // 3. General Webpage (HTTP/HTTPS)
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return CaptureSource.webPage;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
