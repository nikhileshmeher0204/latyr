import 'package:flutter/cupertino.dart';

/// Latyr Apple HIG typography scale — mapped to Inter.
///
/// Implements Apple's Human Interface Guidelines Dynamic Type optical tracking:
/// - Display titles (>= 20pt) use negative optical tracking (-0.35 to -0.80) and tight leading (1.15 - 1.22).
/// - Body text (14-17pt) uses subtle negative tracking (-0.15) with comfortable leading (1.40 - 1.45).
/// - Captions and footnotes (<= 12pt) use POSITIVE tracking (+0.10 to +0.20) so small glyphs do not bleed.
/// - Numeric counters use [FontFeature.tabularFigures()] for uniform monospaced digit widths.
///
/// Usage:
///   ```dart
///   Text('Hello', style: LTypography.largeTitle)
///   Text('Subtext', style: context.footnote)
///   ```
class LTypography {
  LTypography._();

  static const String fontFamily = 'Inter';

  // ─── Display / Large Titles (SF Pro Display equivalent) ───────────────────────

  /// 34pt · w700 · -0.80 tracking · 1.15 leading — screen hero titles
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.80,
    height: 1.15,
  );

  /// 28pt · w700 · -0.60 tracking · 1.18 leading — prominent section headers
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.60,
    height: 1.18,
  );

  /// 22pt · w700 · -0.45 tracking · 1.20 leading — section titles, modal headers
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.45,
    height: 1.20,
  );

  /// 20pt · w600 · -0.35 tracking · 1.22 leading — card headers, sheet titles
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.22,
  );

  // ─── Body & Content (SF Pro Text equivalent) ─────────────────────────────────

  /// 17pt · w600 · -0.35 tracking · 1.30 leading — section headers, prominent labels
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.30,
  );

  /// 17pt · w400 · -0.15 tracking · 1.42 leading — primary content body text
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.15,
    height: 1.42,
  );

  /// 16pt · w400 · -0.15 tracking · 1.40 leading — callout, supporting content
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.15,
    height: 1.40,
  );

  /// 15pt · w400 · -0.10 tracking · 1.38 leading — subheadline, secondary descriptions
  static const TextStyle subheadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.10,
    height: 1.38,
  );

  /// Alias for subheadline
  static const TextStyle subhead = subheadline;

  // ─── Small / Meta / Captions (Positive optical tracking for clarity) ────────

  /// 13pt · w400 · -0.05 tracking · 1.35 leading — footnotes, timestamps
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
    height: 1.35,
  );

  /// 12pt · w400 · +0.10 tracking · 1.30 leading — caption text
  static const TextStyle caption1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.10,
    height: 1.30,
  );

  /// 11pt · w400 · +0.20 tracking · 1.25 leading — small metadata chips
  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.20,
    height: 1.25,
  );

  // ─── Weighted Variants & Specialized Apple Tokens ───────────────────────────

  /// Semibold footnote — for pill badges, category tags
  static const TextStyle footnoteSemibold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.35,
  );

  /// Bold caption1 — for status indicators
  static const TextStyle caption1Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.10,
    height: 1.30,
  );

  /// Bold caption2 — for mini counters and tags
  static const TextStyle caption2Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.20,
    height: 1.25,
  );

  /// Semibold headline — nav tab labels, modal titles
  static const TextStyle headlineSemibold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.30,
  );

  /// Medium subheadline — secondary info with balanced emphasis
  static const TextStyle subheadlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.10,
    height: 1.38,
  );

  /// All-caps eyebrow label — for category tags and pill badges (T1, T2, MOMENT)
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.60,
    height: 1.20,
  );

  /// Large metric number with tabular figures — stat cards, counter widgets
  static const TextStyle largeNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.50,
    height: 1.10,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Hero metric number (e.g. 266 days, 98%)
  static const TextStyle heroMetric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.80,
    height: 1.05,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Button label — standard button text
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.20,
  );

  /// Small button / pill label
  static const TextStyle pillLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.10,
  );

  // ─── Apple SF Pro Rounded Flavors (InterRounded / Open Runde) ───────────────

  static const String roundedFontFamily = 'InterRounded';

  /// Rounded 28pt · w700 · -0.60 tracking — prominent rounded headers
  static const TextStyle roundedTitle1 = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.60,
    height: 1.18,
  );

  /// Rounded 22pt · w700 · -0.45 tracking — section titles, modal headers
  static const TextStyle roundedTitle2 = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.45,
    height: 1.20,
  );

  /// Rounded 20pt · w600 · -0.35 tracking — card headers (Summary, Intents)
  static const TextStyle roundedTitle3 = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.22,
  );

  /// Rounded 17pt · w600 · -0.35 tracking — card section titles, action buttons
  static const TextStyle roundedHeadline = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.35,
    height: 1.30,
  );

  /// Rounded 17pt · w400 · -0.15 tracking — soft body text
  static const TextStyle roundedBody = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.15,
    height: 1.42,
  );

  /// Rounded 15pt · w500 · -0.10 tracking — soft subheadline
  static const TextStyle roundedSubheadline = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.10,
    height: 1.38,
  );

  /// Rounded 13pt · w600 · -0.05 tracking — rounded badge & tag labels
  static const TextStyle roundedPill = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.35,
  );

  /// Rounded 10pt · w700 · +0.60 tracking — rounded all-caps eyebrow
  static const TextStyle roundedEyebrow = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.60,
    height: 1.20,
  );

  /// Rounded 22pt · w700 · -0.50 tracking · tabular figures — rounded stat numbers
  static const TextStyle roundedNumber = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.50,
    height: 1.10,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Rounded 32pt · w700 · -0.80 tracking — hero counter (e.g. 266 in screenshot)
  static const TextStyle roundedHeroMetric = TextStyle(
    fontFamily: roundedFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.80,
    height: 1.05,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Convenience extension to convert any TextStyle to its Apple Rounded flavor
extension RoundedTextStyle on TextStyle {
  TextStyle get rounded => copyWith(fontFamily: LTypography.roundedFontFamily);
}

/// Convenience typography accessors on BuildContext
extension TypographyContext on BuildContext {
  TextStyle get largeTitle => LTypography.largeTitle;
  TextStyle get title1 => LTypography.title1;
  TextStyle get title2 => LTypography.title2;
  TextStyle get title3 => LTypography.title3;
  TextStyle get headline => LTypography.headline;
  TextStyle get body => LTypography.body;
  TextStyle get callout => LTypography.callout;
  TextStyle get subheadline => LTypography.subheadline;
  TextStyle get footnote => LTypography.footnote;
  TextStyle get caption1 => LTypography.caption1;
  TextStyle get caption2 => LTypography.caption2;
  TextStyle get largeNumber => LTypography.largeNumber;

  // Apple Rounded Flavor Shortcuts
  TextStyle get roundedTitle1 => LTypography.roundedTitle1;
  TextStyle get roundedTitle2 => LTypography.roundedTitle2;
  TextStyle get roundedTitle3 => LTypography.roundedTitle3;
  TextStyle get roundedHeadline => LTypography.roundedHeadline;
  TextStyle get roundedBody => LTypography.roundedBody;
  TextStyle get roundedNumber => LTypography.roundedNumber;
}
