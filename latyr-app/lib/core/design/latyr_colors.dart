import 'package:flutter/cupertino.dart';

/// Latyr's Apple-HIG-aligned adaptive color system.
///
/// Every color uses [CupertinoDynamicColor] so it automatically adapts to
/// light mode, dark mode, high-contrast, and elevated contexts — exactly
/// the way Apple's system palettes work.
///
/// Usage:
///   ```dart
///   color: LColors.label.resolveFrom(context)
///   ```
/// Or inside a CupertinoTheme/MaterialTheme context the resolution is
/// automatic when you pass the color to any widget that calls `resolve`.
class LColors {
  LColors._();

  // ─── System Backgrounds ────────────────────────────────────────────────────

  /// Primary app background — white in light, true black in dark (OLED).
  static const CupertinoDynamicColor systemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFAF9F6), // Latyr alabaster (warmer than pure white)
    darkColor: Color(0xFF0E0E10), // Richer than pure black — Latyr obsidian
  );

  /// Secondary grouped background — off-white in light, elevated dark in dark.
  static const CupertinoDynamicColor secondarySystemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF2F1EE),
    darkColor: Color(0xFF17171A),
  );

  /// Tertiary grouped background (cards on top of secondary).
  static const CupertinoDynamicColor tertiarySystemBackground = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFFFFF),
    darkColor: Color(0xFF1F1F23),
  );

  /// Translucent glass surface — used for frosted cards.
  static const CupertinoDynamicColor glassSurface = CupertinoDynamicColor.withBrightness(
    color: Color(0xCCFFFFFF), // 80% white
    darkColor: Color(0xBF1F1F23), // 75% elevated dark
  );

  // ─── Labels / Text ─────────────────────────────────────────────────────────

  /// Primary text — used for titles and prominent content.
  static const CupertinoDynamicColor label = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF121316),
    darkColor: Color(0xFFF5F5F7),
  );

  /// Secondary text — used for subtitles, metadata, descriptions.
  static const CupertinoDynamicColor secondaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF6E6D7A),
    darkColor: Color(0xFF98989D),
  );

  /// Tertiary text — used for placeholders, tertiary info.
  static const CupertinoDynamicColor tertiaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF94A3B8),
    darkColor: Color(0xFF636366),
  );

  /// Quaternary text — very faint, used for disabled or decorative text.
  static const CupertinoDynamicColor quaternaryLabel = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC8CEDB),
    darkColor: Color(0xFF3A3A3C),
  );

  // ─── Separators ────────────────────────────────────────────────────────────

  static const CupertinoDynamicColor separator = CupertinoDynamicColor.withBrightness(
    color: Color(0x33C6C6C8), // ~20% opacity
    darkColor: Color(0x33545458),
  );

  static const CupertinoDynamicColor opaqueSeparator = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFC6C6C8),
    darkColor: Color(0xFF38383A),
  );

  // ─── Fill Colors (controls, input backgrounds) ─────────────────────────────

  static const CupertinoDynamicColor systemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x29787880), // ~16% gray
    darkColor: Color(0x3D787880),
  );

  static const CupertinoDynamicColor secondarySystemFill = CupertinoDynamicColor.withBrightness(
    color: Color(0x1F787880),
    darkColor: Color(0x29787880),
  );

  // ─── Brand / Accent ────────────────────────────────────────────────────────

  /// Latyr amber — primary CTA, active state, selections, progress bars.
  static const Color brandAmber = Color(0xFFE58B04);
  static const Color brandAmberDark = Color(0xFFB45309);
  static const Color brandAmberLight = Color(0xFFF59E0B);

  /// Amber fill for selected backgrounds.
  static const CupertinoDynamicColor amberFill = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFEF3C7), // warm amber subtle
    darkColor: Color(0x2AE58B04), // 16% amber in dark
  );

  /// Amber border/outline.
  static const Color amberBorder = Color(0x33E58B04);

  // ─── Category Accents ──────────────────────────────────────────────────────

  static const Color terracotta = Color(0xFFD9534F);
  static const Color terracottaDark = Color(0xFF80222A);
  static const CupertinoDynamicColor terracottaFill = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFDF2F0),
    darkColor: Color(0x22D9534F),
  );

  static const Color royalIndigo = Color(0xFF6366F1);
  static const CupertinoDynamicColor indigoFill = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFEFF1FF),
    darkColor: Color(0x226366F1),
  );

  static const Color sageEmerald = Color(0xFF10B981);
  static const CupertinoDynamicColor emeraldFill = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFEDF7F3),
    darkColor: Color(0x2210B981),
  );

  static const Color royalViolet = Color(0xFF8B5CF6);
  static const CupertinoDynamicColor violetFill = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF5F3FF),
    darkColor: Color(0x228B5CF6),
  );

  // ─── Semantic States ───────────────────────────────────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // ─── Ambient Gradients ─────────────────────────────────────────────────────

  /// Warm honey glow for ambient background (light mode).
  static const Color ambientHoney = Color(0xFFF6E3BA);
  static const Color ambientWheat = Color(0xFFEED7AE);
  static const Color ambientWarmGlow = Color(0xFFFBF6EC);

  // ─── Static Whites / Blacks used on always-dark surfaces ───────────────────

  static const Color staticWhite = Color(0xFFFFFFFF);
  static const Color staticBlack = Color(0xFF000000);
  static const Color staticWhite70 = Color(0xB3FFFFFF);
  static const Color staticWhite40 = Color(0x66FFFFFF);
  static const Color staticWhite12 = Color(0x1FFFFFFF);

  // ─── Instagram Brand ───────────────────────────────────────────────────────

  static const Color instagramPink = Color(0xFFE1306C);
}
