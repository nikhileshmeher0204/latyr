import 'package:flutter/cupertino.dart';
import 'package:latyr_app/config/app_properties.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/latyr_progressive_blur.dart';

/// Standardized, high-end floating navigation AppBar for all Intent Detail views
/// (Movies, GitHub Repos, Travel, Music, Books, etc.).
///
/// Byte-to-byte identical architectural reproduction of `CaptureDetailScreen`:
/// 1. High-Performance Progressive Frosted Blur Backdrop (`LatyrProgressiveBlur`)
///    - `sigmaStart: 25.0, sigmaEnd: 0.0`
///    - Progressive linear gradient tint (`0.0, 0.45, 0.80, 1.0`)
///    - Height: `topPadding + 58.0 + 10.0`
/// 2. Floating Navigation Bar:
///    - 42x42 circular frosted glass dismiss / back button with subtle border & shadow
///    - Centered contextual bubble pill (`horizontal: 16, vertical: 10`, radius `24`, letterSpacing `0.8`)
///    - Flexible right action cluster with matching 42x42 circular buttons
class IntentDetailAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final Widget? titleLeading;
  final List<Widget>? actions;
  final bool isDark;
  final Color scaffoldBgColor;
  final IconData backIcon;
  final bool enableBlur;

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
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final navBarHeight = topPadding + 58.0;

    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return SizedBox(
      height: navBarHeight + 10.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. High-Performance Progressive Frosted Blur Backdrop (Exact CaptureDetailScreen implementation)
          if (enableBlur && (AppProperties.enableTopBlur || AppProperties.enableTopTint))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: navBarHeight + 10.0,
              child: IgnorePointer(
                child: LatyrProgressiveBlur(
                  enabled: AppProperties.enableTopBlur,
                  sigmaStart: 25.0,
                  sigmaEnd: 0.0,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  child: AppProperties.enableTopTint
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.45, 0.80, 1.0],
                              colors: [
                                scaffoldBgColor.withValues(alpha: isDark ? 0.85 : 0.82),
                                scaffoldBgColor.withValues(alpha: isDark ? 0.60 : 0.50),
                                scaffoldBgColor.withValues(alpha: isDark ? 0.20 : 0.12),
                                scaffoldBgColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),

          // 2. Floating Navigation Bar (Seamless, transparent backdrop without cut-off box)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(backIcon, color: textColor, size: 20),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Centered Sub Category / Intent Bubble Pill
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: borderColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (titleLeading != null) ...[
                                titleLeading!,
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: LTypography.footnoteSemibold.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right Actions Cluster
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    else
                      const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper factory for uniform 42x42 circular frosted action buttons (Share, Favorite, External Link, etc.)
  static Widget buildActionButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cardBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
