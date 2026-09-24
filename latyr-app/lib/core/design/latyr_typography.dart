import 'package:flutter/cupertino.dart';

/// Latyr Apple HIG typography scale — mapped to Inter.
///
/// Based on Apple's Human Interface Guidelines Dynamic Type scale.
/// Tracking (letter-spacing) is size-specific: negative for large text,
/// near-zero for body, slightly positive for captions — exactly as Apple ships.
///
/// Usage:
///   ```dart
///   Text('Hello', style: LTypography.largeTitle)
///   ```
class LTypography {
  LTypography._();

  // ─── Display / Large Titles ─────────────────────────────────────────────────

  /// 34pt · w700 · -0.4 tracking — top-level screen titles (Home, Library)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.18,
  );

  /// 28pt · w700 · -0.3 tracking — editorial hero headings
  static const TextStyle title1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  /// 22pt · w700 · -0.2 tracking — section titles, modal headers
  static const TextStyle title2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.22,
  );

  /// 20pt · w600 · -0.1 tracking — card headers, sheet titles
  static const TextStyle title3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.25,
  );

  // ─── Body & Content ─────────────────────────────────────────────────────────

  /// 17pt · w600 · -0.1 tracking — section headers, nav bar labels
  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// 17pt · w400 · 0 tracking — primary content body text
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.47,
  );

  /// 16pt · w400 · 0 tracking — callout, supporting body
  static const TextStyle callout = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.44,
  );

  /// 15pt · w400 · 0 tracking — subheadline, secondary content
  static const TextStyle subheadline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Alias for subheadline
  static const TextStyle subhead = subheadline;

  // ─── Small / Meta ──────────────────────────────────────────────────────────

  /// 13pt · w400 · +0.1 tracking — footnotes, timestamps, secondary meta
  static const TextStyle footnote = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.38,
  );

  /// 12pt · w400 · +0.1 tracking — caption text
  static const TextStyle caption1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.33,
  );

  /// 11pt · w400 · +0.2 tracking — smallest labels, status chips
  static const TextStyle caption2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.27,
  );

  // ─── Weighted Variants ─────────────────────────────────────────────────────

  /// Semibold footnote — for pill badges, filter chip labels
  static const TextStyle footnoteSemibold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.38,
  );

  /// Bold caption — for status badges
  static const TextStyle caption1Bold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.33,
  );

  /// Bold caption2 — for mini labels, counts
  static const TextStyle caption2Bold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.27,
  );

  /// Semibold headline — nav tab labels
  static const TextStyle headlineSemibold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Medium subheadline — secondary info with slightly more weight
  static const TextStyle subheadlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Large metric number — stat cards
  static const TextStyle largeNumber = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
  );

  /// Button label — standard button text
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  /// Small button / pill label
  static const TextStyle pillLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
}
