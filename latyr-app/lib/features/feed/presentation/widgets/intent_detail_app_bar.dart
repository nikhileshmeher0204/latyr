import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';

/// Standardized, high-end floating navigation AppBar for all Intent Detail views.
///
/// Backed by [LatyrAppBar] with persistent stationary transitions and progressive blur.
class IntentDetailAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final Widget? titleLeading;
  final List<Widget>? actions;
  final bool isDark;
  final Color scaffoldBgColor;
  final IconData backIcon;
  final bool enableBlur;
  final bool isPersistent;

  const IntentDetailAppBar({
    super.key,
    this.onBack,
    required this.title,
    this.titleLeading,
    this.actions,
    required this.isDark,
    required this.scaffoldBgColor,
    this.backIcon = CupertinoIcons.back,
    this.enableBlur = true,
    this.isPersistent = true,
  });

  @override
  Widget build(BuildContext context) {
    return LatyrAppBar(
      title: title,
      titleLeading: titleLeading,
      onBack: onBack,
      actions: actions,
      isDark: isDark,
      scaffoldBgColor: scaffoldBgColor,
      backIcon: backIcon,
      enableBlur: enableBlur,
      isPersistent: isPersistent,
    );
  }

  /// Helper factory for uniform 42x42 circular frosted action buttons.
  static Widget buildActionButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return LatyrAppBar.actionButton(
      child: child,
      onPressed: onPressed,
      isDark: isDark,
    );
  }
}
