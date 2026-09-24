// Re-export shim — keeps all existing `AppColors.xxx` references working
// while the new design system uses `LColors` from `latyr_colors.dart`.
export 'package:latyr_app/core/design/latyr_colors.dart';

import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';

/// Legacy AppColors — all values now delegate to LColors constants.
/// Kept for backward-compatibility with any code referencing AppColors directly.
class AppColors {
  AppColors._();

  static const Color brandAmber = LColors.brandAmber;
  static const Color brandAmberDark = LColors.brandAmberDark;
  static const Color brandAmberLight = LColors.brandAmberLight;
  static const CupertinoDynamicColor amberSubtle = LColors.amberFill;
  static const Color amberGlow = LColors.brandAmberLight;
  static const Color amberBorder = LColors.amberBorder;

  static const Color obsidian = Color(0xFF0E0E10);
  static const Color obsidianElevated = Color(0xFF17171A);
  static const Color obsidianCard = Color(0xE017171A);
  static const Color obsidianBorder = LColors.staticWhite12;

  static const Color alabaster = Color(0xFFFAF9F6);
  static const Color alabasterGlass = Color(0xCCFFFFFF);
  static const Color alabasterBorder = Color(0xA6FFFFFF);

  static const Color ambientHoney = LColors.ambientHoney;
  static const Color ambientWheat = LColors.ambientWheat;
  static const Color ambientWarmGlow = LColors.ambientWarmGlow;

  static const CupertinoDynamicColor textPrimary = LColors.label;
  static const CupertinoDynamicColor textSecondary = LColors.secondaryLabel;
  static const CupertinoDynamicColor textMuted = LColors.tertiaryLabel;
  static const CupertinoDynamicColor textLight = LColors.quaternaryLabel;
  static const CupertinoDynamicColor slateLight = LColors.quaternaryLabel;
  static const Color textWhite = LColors.staticWhite;

  static const Color terracotta = LColors.terracotta;
  static const Color terracottaDark = LColors.terracottaDark;
  static const CupertinoDynamicColor terracottaSubtle = LColors.terracottaFill;

  static const Color royalIndigo = LColors.royalIndigo;
  static const CupertinoDynamicColor indigoSubtle = LColors.indigoFill;

  static const Color quoteAmber = LColors.brandAmber;
  static const CupertinoDynamicColor quoteSubtle = LColors.amberFill;

  static const Color sageEmerald = LColors.sageEmerald;
  static const CupertinoDynamicColor emeraldSubtle = LColors.emeraldFill;

  static const Color royalViolet = LColors.royalViolet;
  static const CupertinoDynamicColor violetSubtle = LColors.violetFill;

  static const Color success = LColors.success;
  static const Color warning = LColors.warning;
  static const Color error = LColors.error;
  static const Color info = LColors.info;
}
