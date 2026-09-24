import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

/// Frosted-glass floating navigation island — Latyr's primary nav bar.
///
/// Sits at the bottom of every main screen, floating above content.
/// Uses [CupertinoIcons] and adapts its glass surface to light/dark mode.
/// Active item expands into an amber pill with label; inactive shows icon only.
class FloatingNavIsland extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavIsland({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xCC1C1C1E) // 80% dark elevated
        : const Color(0xD9FAFAF8); // 85% light alabaster

    final borderColor = isDark
        ? const Color(0x1AFFFFFF) // 10% white stroke
        : const Color(0x80FFFFFF); // 50% white stroke

    return Container(
      height: LSpacing.navIslandHeight,
      margin: const EdgeInsets.symmetric(
        horizontal: LSpacing.navIslandMarginH,
        vertical: LSpacing.navIslandMarginV,
      ),
      child: ClipRRect(
        borderRadius: LSpacing.brPill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: LSpacing.blurNav, sigmaY: LSpacing.blurNav),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: LSpacing.brPill,
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Color(isDark ? 0x59000000 : 0x14000000),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(context, 0, CupertinoIcons.house_fill, 'Home'),
                _buildNavItem(context, 1, CupertinoIcons.rectangle_grid_2x2_fill, 'Library'),
                _buildNavItem(context, 2, CupertinoIcons.search, 'Search'),
                _buildNavItem(context, 3, CupertinoIcons.person_fill, 'You'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        child: Center(
          child: _NavPill(
            icon: icon,
            label: label,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavPill({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final iconColor = isSelected
        ? LColors.brandAmberDark
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93));
    final activeBg = isDark
        ? const Color(0x2AE58B04) // 16% amber on dark
        : const Color(0xFFFEF3C7); // warm amber fill on light

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: isSelected
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : const Color(0x00000000),
        borderRadius: LSpacing.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          if (isSelected) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: LTypography.caption1Bold.copyWith(color: LColors.brandAmberDark),
            ),
          ],
        ],
      ),
    );
  }
}
