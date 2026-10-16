import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment Configuration class that reads variables provided via `--dart-define`.
class EnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );

  static const String _rawApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Resolves the API URL based on platform (e.g. converting `localhost` to `10.0.2.2` for Android Emulator).
  static String get apiUrl {
    var url = _rawApiUrl;
    if (!kIsWeb && Platform.isAndroid && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    } else if (url.endsWith('/api/')) {
      url = url.substring(0, url.length - 5);
    } else if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static bool get isLocal => environment == 'local';
  static bool get isUat => environment == 'uat';
  static bool get isProd => environment == 'prod';
}
