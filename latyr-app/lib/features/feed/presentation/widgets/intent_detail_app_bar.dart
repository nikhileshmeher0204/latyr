import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

/// Standardized, high-end floating navigation AppBar for all Intent Detail views
/// (Movies, GitHub Repos, Travel, Music, Books, etc.).
///
/// Direct 1:1 design harmony with `CaptureDetailScreen`:
/// - 42x42 circular frosted glass dismiss / back button with subtle border & shadow
/// - Centered contextual pill bubble with pill styling (with optional leading icon/svg)
/// - Flexible right action cluster with matching circular buttons
class IntentDetailAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final Widget? titleLeading;
  final List<Widget>? actions;
  final bool isDark;
  final IconData backIcon;

  const IntentDetailAppBar({
    super.key,
    this.onBack,
    required this.title,
    this.titleLeading,
    this.actions,
    required this.isDark,
    this.backIcon = CupertinoIcons.back,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Circular Frosted Back/Dismiss Button
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

            // 2. Centered Contextual Bubble Pill
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
                            fontSize: 12.5,
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

            // 3. Right Action Cluster
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            else
              // Balances the 42px width so the center pill remains optically centered
              const SizedBox(width: 42),
          ],
        ),
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
