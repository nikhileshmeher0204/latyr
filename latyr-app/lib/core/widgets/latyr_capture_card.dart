import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/enums/capture_source.dart';
import 'package:latyr_app/core/services/color_extraction_service.dart';
import 'package:latyr_app/core/util/capture_source_classifier.dart';
import 'package:latyr_app/core/widgets/capture_source_icon.dart';
import 'package:latyr_app/features/feed/presentation/screens/capture_detail_screen.dart';

/// The single, canonical capture card used across the app —
/// Home Tab stacked carousel, Collections sub-category grid, etc.
///
/// Features dynamic dominant color extraction from thumbnail images with
/// smooth cross-fade and deterministic pastel fallback.
class LatyrCaptureCard extends StatefulWidget {
  final LocalCapture capture;
  final bool? isDark;

  const LatyrCaptureCard({
    super.key,
    required this.capture,
    this.isDark,
  });

  static Color cardColorFor(LocalCapture capture, {required bool isDark}) {
    final colorList = [
      isDark ? const Color(0xFF382E18) : const Color(0xFFFFE873), // Warm bronze / Amber
      isDark ? const Color(0xFF1E3A36) : const Color(0xFF88D4C8), // Deep teal / Seafoam
      isDark ? const Color(0xFF224430) : const Color(0xFFA8E6B6), // Deep forest / Sage
      isDark ? const Color(0xFF2C2044) : const Color(0xFFD6B5FF), // Deep plum / Lavender
      isDark ? const Color(0xFF421E36) : const Color(0xFFFF9CEE), // Deep wine / Rose
    ];
    return colorList[capture.id.hashCode.abs() % colorList.length];
  }

  @override
  State<LatyrCaptureCard> createState() => _LatyrCaptureCardState();
}

class _LatyrCaptureCardState extends State<LatyrCaptureCard> {
  Color? _extractedColor;
  bool? _lastIsDark;

  bool _computeIsDark() {
    return widget.isDark ??
        (MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark ||
            CupertinoTheme.of(context).brightness == Brightness.dark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = _computeIsDark();
    if (_lastIsDark != isDark) {
      _lastIsDark = isDark;
      _resolveColor(isDark);
    }
  }

  @override
  void didUpdateWidget(covariant LatyrCaptureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isDark = _computeIsDark();
    if (oldWidget.capture.thumbnailUrl != widget.capture.thumbnailUrl ||
        oldWidget.capture.id != widget.capture.id ||
        oldWidget.isDark != widget.isDark ||
        _lastIsDark != isDark) {
      _lastIsDark = isDark;
      _resolveColor(isDark);
    }
  }

  void _resolveColor(bool isDark) {
    final url = widget.capture.thumbnailUrl;
    if (url == null || url.isEmpty) {
      if (_extractedColor != null) {
        setState(() => _extractedColor = null);
      }
      return;
    }

    final cached = ColorExtractionService.getCachedColor(url, isDark: isDark);
    if (cached != null) {
      if (_extractedColor != cached) {
        setState(() => _extractedColor = cached);
      }
      return;
    }

    final fallback = LatyrCaptureCard.cardColorFor(widget.capture, isDark: isDark);
    ColorExtractionService.extractDominantColor(url, isDark: isDark, fallback: fallback).then((color) {
      if (mounted && _lastIsDark == isDark && _extractedColor != color) {
        setState(() => _extractedColor = color);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _computeIsDark();
    final borderColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.16)
        : CupertinoColors.white;
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
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: isDark ? 20 : 18,
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
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.12)
                      : CupertinoColors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.18)
                        : CupertinoColors.white.withValues(alpha: 0.60),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.circle_grid_hex,
                      size: 10,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        (widget.capture.subCategory ?? widget.capture.category ?? 'Moment').toUpperCase(),
                        style: LTypography.caption2.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: textColor.withValues(alpha: 0.85),
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
            // Dynamic 4-Slot Media & Metadata Row:
            // 1. Source Brand Glyph (Instagram, YouTube, Web globe, Photo) - omitted if unidentified
            // 2. Action Trigger (Play triangle, Open Link, Viewfinder)
            // 3. Compact Relative Time (e.g. 2m, 3h, 1d)
            // 4. Insights Sparkle Counter (e.g. ✨ 3)
            Builder(
              builder: (context) {
                final source = CaptureSource.fromString(widget.capture.sourceType) ??
                    CaptureSourceClassifier.classify(widget.capture.originalUrl ?? widget.capture.originalCaption);
                final insightsCount = _getInsightsCount();

                return Row(
                  children: [
                    // Slot 1: Source Brand Glyph (omitted cleanly if unknown)
                    if (source != null) ...[
                      CaptureSourceIcon(
                        source: source,
                        size: 19,
                        color: textColor.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 9),
                    ],
                    // Slot 2: Action Icon (optically balanced with brand glyph)
                    Icon(
                      source?.actionIcon ?? CupertinoIcons.arrow_up_right,
                      size: 21.5,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 9),
                    // Slot 3: Time since added
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 15.5,
                          color: textColor.withValues(alpha: 0.82),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCompactTime(widget.capture.createdAt),
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.85),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 9),
                    // Slot 4: Insights Counter with Document List Copy Icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.doc_on_doc,
                          size: 15.0,
                          color: textColor.withValues(alpha: 0.82),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$insightsCount',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.85),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
                _cleanPreviewSummary(widget.capture.summary ?? 'A captured moment in time.'),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: isDark ? 0.75 : 0.70),
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

  String _cleanPreviewSummary(String raw) {
    var cleaned = raw;
    // Strip custom icon tags like [icon:brain]
    cleaned = cleaned.replaceAll(RegExp(r'\[icon:[^\]]+\]'), '');
    // Strip markdown links/tips [Text](url) -> Text
    cleaned = cleaned.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '');
    // Strip ==highlight== -> highlight
    cleaned = cleaned.replaceAllMapped(RegExp(r'==([^=]+)=='), (m) => m.group(1) ?? '');
    // Strip bold/italics
    cleaned = cleaned.replaceAllMapped(RegExp(r'(\*\*|\*|__|_)(.*?)\1'), (m) => m.group(2) ?? '');
    // Clean up multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  String _formatCompactTime(DateTime? date) {
    if (date == null) return 'now';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds <= 0 ? 1 : diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  int _getInsightsCount() {
    final raw = widget.capture.entitiesJson;
    if (raw == null || raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.length;
    } catch (_) {}
    return 0;
  }
}
