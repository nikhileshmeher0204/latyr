import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/core/enums/capture_source.dart';
import 'package:latyr_app/core/util/capture_source_classifier.dart';

void main() {
  group('CaptureSourceClassifier', () {
    test('extractFirstUrl extracts URL from commentary share text', () {
      const shareText = 'Check out this awesome reel https://www.instagram.com/reel/C8xyz123/?igsh=abc it was so cool!';
      final extracted = CaptureSourceClassifier.extractFirstUrl(shareText);
      expect(extracted, 'https://www.instagram.com/reel/C8xyz123/?igsh=abc');
    });

    test('normalizeUrl strips tracking parameters', () {
      const url = 'https://www.instagram.com/reel/C8xyz123/?igsh=abc1234&utm_source=ig_web_copy_link';
      final normalized = CaptureSourceClassifier.normalizeUrl(url);
      expect(normalized, 'https://instagram.com/reel/C8xyz123');
    });

    test('Classifies Instagram Reel URLs', () {
      expect(
        CaptureSourceClassifier.classify('https://www.instagram.com/reel/C8xyz123/'),
        CaptureSource.instagramReel,
      );
      expect(
        CaptureSourceClassifier.classify('https://instagr.am/reel/C8xyz123/'),
        CaptureSource.instagramReel,
      );
    });

    test('Classifies Instagram Post as instagramReel (per project requirement)', () {
      expect(
        CaptureSourceClassifier.classify('https://www.instagram.com/p/C8xyz123/'),
        CaptureSource.instagramReel,
      );
    });

    test('Classifies YouTube Short URLs', () {
      expect(
        CaptureSourceClassifier.classify('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        CaptureSource.youtubeShort,
      );
      expect(
        CaptureSourceClassifier.classify('https://youtube.com/shorts/dQw4w9WgXcQ?feature=share'),
        CaptureSource.youtubeShort,
      );
    });

    test('Classifies YouTube standard video and youtu.be URLs', () {
      expect(
        CaptureSourceClassifier.classify('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        CaptureSource.youtubeVideo,
      );
      expect(
        CaptureSourceClassifier.classify('https://youtu.be/dQw4w9WgXcQ'),
        CaptureSource.youtubeVideo,
      );
    });

    test('Classifies general Web pages', () {
      expect(
        CaptureSourceClassifier.classify('https://techcrunch.com/2026/08/24/ai-agents'),
        CaptureSource.webPage,
      );
      expect(
        CaptureSourceClassifier.classify('https://github.com/flutter/flutter'),
        CaptureSource.webPage,
      );
    });

    test('Returns null for invalid or null inputs', () {
      expect(CaptureSourceClassifier.classify(null), isNull);
      expect(CaptureSourceClassifier.classify(''), isNull);
      expect(CaptureSourceClassifier.classify('just plain text with no link'), isNull);
    });

    test('CaptureSource enum fromString mapping and action icons', () {
      expect(CaptureSource.fromString('INSTAGRAM_REEL'), CaptureSource.instagramReel);
      expect(CaptureSource.fromString('YOUTUBE_SHORT'), CaptureSource.youtubeShort);
      expect(CaptureSource.fromString('YOUTUBE_VIDEO'), CaptureSource.youtubeVideo);
      expect(CaptureSource.fromString('WEB_URL'), CaptureSource.webPage);
      expect(CaptureSource.fromString('IMAGE'), CaptureSource.image);
      expect(CaptureSource.fromString('UNKNOWN_XYZ'), isNull);
      expect(CaptureSource.fromString(null), isNull);

      expect(CaptureSource.instagramReel.actionIcon, isNotNull);
      expect(CaptureSource.youtubeShort.actionIcon, isNotNull);
      expect(CaptureSource.webPage.actionIcon, isNotNull);
      expect(CaptureSource.image.actionIcon, isNotNull);
    });
  });
}
