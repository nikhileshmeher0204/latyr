import 'package:flutter/cupertino.dart';

/// Represents the detected canonical source of a capture.
enum CaptureSource {
  instagramReel,
  youtubeShort,
  youtubeVideo,
  webPage,
  image;

  String get displayName {
    switch (this) {
      case CaptureSource.instagramReel:
        return 'Instagram Reel';
      case CaptureSource.youtubeShort:
        return 'YouTube Short';
      case CaptureSource.youtubeVideo:
        return 'YouTube Video';
      case CaptureSource.webPage:
        return 'Webpage';
      case CaptureSource.image:
        return 'Screenshot';
    }
  }

  String get shortName {
    switch (this) {
      case CaptureSource.instagramReel:
        return 'Reel';
      case CaptureSource.youtubeShort:
        return 'Short';
      case CaptureSource.youtubeVideo:
        return 'Video';
      case CaptureSource.webPage:
        return 'Web';
      case CaptureSource.image:
        return 'Image';
    }
  }

  /// Maps string representation (from Backend enum or Drift DB) to [CaptureSource].
  static CaptureSource? fromString(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final normalized = val.trim().toUpperCase();
    switch (normalized) {
      case 'INSTAGRAM_REEL':
      case 'INSTAGRAMREEL':
      case 'INSTAGRAM':
        return CaptureSource.instagramReel;
      case 'YOUTUBE_SHORT':
      case 'YOUTUBESHORT':
      case 'SHORT':
        return CaptureSource.youtubeShort;
      case 'YOUTUBE_VIDEO':
      case 'YOUTUBEVIDEO':
      case 'YOUTUBE':
        return CaptureSource.youtubeVideo;
      case 'WEB_URL':
      case 'WEBPAGE':
      case 'WEB':
        return CaptureSource.webPage;
      case 'IMAGE':
      case 'SCREENSHOT':
        return CaptureSource.image;
      default:
        return null;
    }
  }

  /// Returns the corresponding action icon (Play, Open Link, Viewfinder).
  IconData get actionIcon {
    switch (this) {
      case CaptureSource.instagramReel:
      case CaptureSource.youtubeShort:
      case CaptureSource.youtubeVideo:
        return CupertinoIcons.play_arrow_solid;
      case CaptureSource.webPage:
        return CupertinoIcons.arrow_up_right;
      case CaptureSource.image:
        return CupertinoIcons.viewfinder;
    }
  }
}
