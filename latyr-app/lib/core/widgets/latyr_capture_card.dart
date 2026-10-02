import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/services/color_extraction_service.dart';
import 'package:latyr_app/features/feed/presentation/screens/capture_detail_screen.dart';

/// The single, canonical capture card used across the app —
/// Home Tab stacked carousel, Collections sub-category grid, etc.
///
/// Features dynamic dominant color extraction from thumbnail images with
/// smooth cross-fade and deterministic pastel fallback.
class LatyrCaptureCard extends StatefulWidget {
  final LocalCapture capture;

  const LatyrCaptureCard({super.key, required this.capture});

  static Color cardColorFor(LocalCapture capture, {required bool isDark}) {
    final colorList = [
      isDark ? const Color(0xFFC7A222) : const Color(0xFFFFE873),
      isDark ? const Color(0xFF2A9D8F) : const Color(0xFF88D4C8),
      isDark ? const Color(0xFF4C956C) : const Color(0xFFA8E6B6),
      isDark ? const Color(0xFF845EC2) : const Color(0xFFD6B5FF),
      isDark ? const Color(0xFFD65DB1) : const Color(0xFFFF9CEE),
    ];
    return colorList[capture.id.hashCode.abs() % colorList.length];
  }

  @override
  State<LatyrCaptureCard> createState() => _LatyrCaptureCardState();
}

class _LatyrCaptureCardState extends State<LatyrCaptureCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(covariant LatyrCaptureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capture.thumbnailUrl != widget.capture.thumbnailUrl ||
        oldWidget.capture.id != widget.capture.id) {
      _resolveColor();
    }
  }

  void _resolveColor() {
    final url = widget.capture.thumbnailUrl;
    if (url == null || url.isEmpty) {
      _extractedColor = null;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
      final cached = ColorExtractionService.getCachedColor(url, isDark: isDark);
      if (cached != null) {
        if (_extractedColor != cached) {
          setState(() => _extractedColor = cached);
        }
        return;
      }

      final fallback = LatyrCaptureCard.cardColorFor(widget.capture, isDark: isDark);
      ColorExtractionService.extractDominantColor(url, isDark: isDark, fallback: fallback).then((color) {
        if (mounted && _extractedColor != color) {
          setState(() => _extractedColor = color);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final fallbackColor = LatyrCaptureCard.cardColorFor(widget.capture, isDark: isDark);
    final bgColor = _extractedColor ?? fallbackColor;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => CaptureDetailScreen(capture: widget.capture),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left-aligned Category Pill with frosted glass feel
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x33FFFFFF) : CupertinoColors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CupertinoColors.white.withOpacity(isDark ? 0.15 : 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.circle_grid_hex,
                      size: 10,
                      color: textColor.withOpacity(0.85),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        (widget.capture.subCategory ?? widget.capture.category ?? 'Moment').toUpperCase(),
                        style: LTypography.caption2.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: textColor.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 4 Media & Activity Icons
            Row(
              children: [
                Icon(CupertinoIcons.photo_fill, size: 22, color: textColor.withOpacity(0.85)),
                const SizedBox(width: 9),
                Icon(CupertinoIcons.map_fill, size: 22, color: textColor.withOpacity(0.85)),
                const SizedBox(width: 9),
                Icon(Icons.directions_run_rounded, size: 23, color: textColor.withOpacity(0.85)),
                const SizedBox(width: 9),
                Icon(Icons.graphic_eq_rounded, size: 23, color: textColor.withOpacity(0.85)),
              ],
            ),
            const SizedBox(height: 14),
            // Title (3 lines)
            Text(
              widget.capture.title ?? 'Untitled',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
                letterSpacing: -0.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Summary
            Flexible(
              child: Text(
                widget.capture.summary ?? 'A captured moment in time.',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.70),
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
