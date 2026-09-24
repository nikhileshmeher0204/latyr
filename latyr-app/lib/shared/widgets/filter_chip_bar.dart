import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';

/// Filter chip data model.
class FilterChipItem {
  final String label;
  final String? iconText;

  const FilterChipItem({required this.label, this.iconText});
}

/// Horizontally-scrolling pill filter bar — iOS-style segment selector.
///
/// Selected chip: solid amber pill with white text.
/// Unselected: adaptive glass/fill background with secondary label color.
/// Adapts to light and dark mode automatically.
class FilterChipBar extends StatelessWidget {
  final List<FilterChipItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FilterChipBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(width: LSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final item = items[index];
          return _FilterPill(
            item: item,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(index);
            },
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatefulWidget {
  final FilterChipItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterPill({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Selected: amber solid pill
    // Unselected: glass pill with adaptive fill
    final bgColor = widget.isSelected
        ? LColors.brandAmber
        : (widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEDECEA));

    final textColor = widget.isSelected
        ? LColors.staticWhite
        : (widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6D7A));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: LSpacing.md, vertical: LSpacing.sm),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: LSpacing.brPill,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: LColors.brandAmber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.iconText != null && !widget.isSelected) ...[
                Text(
                  widget.item.iconText!,
                  style: LTypography.caption2.copyWith(color: textColor),
                ),
                const SizedBox(width: LSpacing.xs),
              ],
              Text(
                widget.item.label,
                style: LTypography.footnoteSemibold.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
