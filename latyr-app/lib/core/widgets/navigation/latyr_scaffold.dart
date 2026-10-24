import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';

/// Standardized, high-performance scaffold for Latyr detail screens.
///
/// Features:
/// - Automatically places the persistent [LatyrAppBar] above the content.
/// - Allows the body to scroll seamlessly underneath the progressive blur backdrop.
/// - Supports ambient background auras (e.g. dynamic color extraction gradients).
class LatyrScaffold extends StatelessWidget {
  final LatyrAppBar? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? backgroundAura;
  final SystemUiOverlayStyle? overlayStyle;

  const LatyrScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.backgroundAura,
    this.overlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBgColor = backgroundColor ??
        (isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA));

    final defaultOverlay = SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: scaffoldBgColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle ?? defaultOverlay,
      child: CupertinoPageScaffold(
        backgroundColor: scaffoldBgColor,
        child: Stack(
          children: [
            ?backgroundAura,
            body,
            if (appBar != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: appBar!,
              ),
          ],
        ),
      ),
    );
  }
}
