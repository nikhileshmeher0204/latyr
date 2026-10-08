import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

/// AppTheme — bridges CupertinoThemeData and MaterialThemeData.
///
/// The app uses [CupertinoApp] as root. The Material bridge lets any legacy
/// Material widget (RefreshIndicator, Slider, etc.) pick up consistent colors.
class AppTheme {
  AppTheme._();

  // ─── Legacy static accessors (backward compat) ─────────────────────────────

  static const Color background = Color(0xFF0E0E10);
  static const Color surface = Color(0xFF17171A);
  static const Color surfaceElevated = Color(0xFF1F1F23);
  static const Color border = Color(0xFF38383A);

  static const Color primary = LColors.brandAmber;
  static const Color primaryLight = LColors.brandAmberLight;
  static const Color accent = LColors.sageEmerald;
  static const Color warning = LColors.warning;
  static const Color error = LColors.error;
  static const Color info = LColors.info;

  static const CupertinoDynamicColor textPrimary = LColors.label;
  static const CupertinoDynamicColor textSecondary = LColors.secondaryLabel;
  static const CupertinoDynamicColor textMuted = LColors.tertiaryLabel;

  // ─── Cupertino Theme ───────────────────────────────────────────────────────

  static CupertinoThemeData cupertinoTheme({Brightness? brightness}) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: LColors.brandAmber,
      primaryContrastingColor: LColors.staticWhite,
      scaffoldBackgroundColor: LColors.systemBackground,
      barBackgroundColor: LColors.glassSurface,
      textTheme: CupertinoTextThemeData(
        primaryColor: LColors.brandAmber,
        textStyle: LTypography.body.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.label,
        ),
        navTitleTextStyle: LTypography.headline.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.label,
        ),
        navLargeTitleTextStyle: LTypography.largeTitle.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.label,
        ),
        navActionTextStyle: LTypography.body.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.brandAmber,
        ),
        actionTextStyle: LTypography.body.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.brandAmber,
        ),
        tabLabelTextStyle: LTypography.caption2Bold.copyWith(
          fontFamily: LTypography.fontFamily,
        ),
        pickerTextStyle: LTypography.title3.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.label,
        ),
        dateTimePickerTextStyle: LTypography.title3.copyWith(
          fontFamily: LTypography.fontFamily,
          color: LColors.label,
        ),
      ),
    );
  }

  // ─── Material bridge (for RefreshIndicator, Slider, Snackbar, etc.) ───────

  static ThemeData materialBridge({Brightness brightness = Brightness.light}) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isLight ? const Color(0xFFFAF9F6) : const Color(0xFF0E0E10),
      primaryColor: LColors.brandAmber,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: LColors.brandAmber,
        onPrimary: LColors.staticWhite,
        secondary: LColors.sageEmerald,
        onSecondary: LColors.staticWhite,
        error: LColors.error,
        onError: LColors.staticWhite,
        surface: isLight ? const Color(0xFFF2F1EE) : const Color(0xFF17171A),
        onSurface: isLight ? const Color(0xFF121316) : const Color(0xFFF5F5F7),
      ),
      fontFamily: 'Inter',
      textTheme: TextTheme(
        headlineLarge: LTypography.largeTitle,
        headlineMedium: LTypography.title1,
        titleLarge: LTypography.title3,
        titleMedium: LTypography.headline,
        bodyLarge: LTypography.body,
        bodyMedium: LTypography.callout,
        bodySmall: LTypography.footnote,
        labelLarge: LTypography.pillLabel,
        labelSmall: LTypography.caption2Bold,
      ),
    );
  }

  // ─── Convenience getters (legacy API) ─────────────────────────────────────

  static ThemeData get lightTheme => materialBridge(brightness: Brightness.light);
  static ThemeData get darkTheme => materialBridge(brightness: Brightness.dark);
}
