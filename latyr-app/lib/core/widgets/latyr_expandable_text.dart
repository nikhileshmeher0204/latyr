import 'package:flutter/cupertino.dart';

/// LatyrExpandableText
///
/// An editorial-grade expandable text widget that smoothly clamps to [maxLines]
/// with an animated "Show more / Show less" toggle. Only displays the toggle
/// when the text genuinely exceeds the specified line clamp.
class LatyrExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? toggleStyle;
  final Duration animationDuration;

  const LatyrExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.toggleStyle,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<LatyrExpandableText> createState() => _LatyrExpandableTextState();
}

class _LatyrExpandableTextState extends State<LatyrExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final defaultStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12.5,
      height: 1.4,
      letterSpacing: -0.1,
      color: isDark ? const Color(0xB3FFFFFF) : const Color(0x99000000),
    );
    final effectiveStyle = widget.style ?? defaultStyle;

    final effectiveToggleStyle = widget.toggleStyle ??
        TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: effectiveStyle);
        final tp = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool exceedsMaxLines = tp.didExceedMaxLines;

        return AnimatedSize(
          duration: widget.animationDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: effectiveStyle,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (exceedsMaxLines) ...[
                const SizedBox(height: 3),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  minimumSize: Size.zero,
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: effectiveToggleStyle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
