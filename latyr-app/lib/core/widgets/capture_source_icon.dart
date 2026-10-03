import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/enums/capture_source.dart';

/// Renders a crisp, vector-drawn monochrome brand glyph or category icon for a [CaptureSource].
///
/// Ensures compliance with brand guidelines: strictly monochrome, pure vector rendering,
/// resolution-independent, and perfectly sized for headers and card rows.
class CaptureSourceIcon extends StatelessWidget {
  final CaptureSource source;
  final double size;
  final Color color;

  const CaptureSourceIcon({
    super.key,
    required this.source,
    this.size = 20,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (source) {
      case CaptureSource.instagramReel:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _InstagramGlyphPainter(color: color),
          ),
        );
      case CaptureSource.youtubeShort:
      case CaptureSource.youtubeVideo:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _YouTubeGlyphPainter(color: color),
          ),
        );
      case CaptureSource.webPage:
        return Icon(
          CupertinoIcons.globe,
          size: size,
          color: color,
        );
      case CaptureSource.image:
        return Icon(
          CupertinoIcons.photo_fill,
          size: size,
          color: color,
        );
    }
  }
}

/// Draws the official Instagram camera contour glyph:
/// - Outer rounded rectangle
/// - Concentric center camera circle
/// - Upper right lens dot
class _InstagramGlyphPainter extends CustomPainter {
  final Color color;

  const _InstagramGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.10;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Outer rounded rectangle (inset by half stroke width)
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.28));
    canvas.drawRRect(rrect, strokePaint);

    // 2. Center circle
    final center = Offset(size.width / 2, size.height / 2);
    final centerRadius = size.width * 0.24;
    canvas.drawCircle(center, centerRadius, strokePaint);

    // 3. Top-right flash / lens dot
    final dotCenter = Offset(size.width * 0.76, size.height * 0.24);
    final dotRadius = size.width * 0.06;
    canvas.drawCircle(dotCenter, dotRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _InstagramGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Draws the official YouTube play contour glyph:
/// - Rounded rectangle container
/// - Centered right-pointing play triangle
class _YouTubeGlyphPainter extends CustomPainter {
  final Color color;

  const _YouTubeGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.10;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Outer rounded rectangle
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset + (size.height * 0.1),
      size.width - strokeWidth,
      size.height * 0.8 - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22));
    canvas.drawRRect(rrect, strokePaint);

    // 2. Play triangle in center (facing right)
    final triangleWidth = size.width * 0.26;
    final triangleHeight = size.height * 0.30;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - (triangleWidth * 0.42), cy - (triangleHeight / 2))
      ..lineTo(cx + (triangleWidth * 0.58), cy)
      ..lineTo(cx - (triangleWidth * 0.42), cy + (triangleHeight / 2))
      ..close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _YouTubeGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
