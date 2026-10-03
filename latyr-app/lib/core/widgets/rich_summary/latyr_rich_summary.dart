import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'summary_action_handler.dart';
import 'summary_lexer.dart';
import 'summary_token.dart';

class _RichTokenData {
  final SummaryToken token;
  final TapGestureRecognizer? recognizer;

  const _RichTokenData({required this.token, this.recognizer});
}

/// Renders magazine-grade editorial rich summaries with pastel highlights,
/// wavy underlines, Georgia italics, inline 3D icons, and interactive smart links.
class LatyrRichSummary extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color? textColor;
  final Color? cardAccentColor;
  final bool? isDark;
  final double? fontSize;
  final double? lineHeight;

  const LatyrRichSummary({
    super.key,
    required this.text,
    this.style,
    this.textColor,
    this.cardAccentColor,
    this.isDark,
    this.fontSize,
    this.lineHeight,
  });

  @override
  State<LatyrRichSummary> createState() => _LatyrRichSummaryState();
}

class _LatyrRichSummaryState extends State<LatyrRichSummary> {
  late List<_RichTokenData> _tokenData;
  final List<GestureRecognizer> _recognizers = [];

  static const Map<String, String> _iconAliases = {
    'runner': 'runner',
    'running': 'runner',
    'fast': 'runner',
    'speed': 'runner',
    'lightning': 'lightning',
    'zap': 'lightning',
    'bolt': 'lightning',
    'energy': 'lightning',
    'rocket': 'rocket',
    'launch': 'rocket',
    'scale': 'rocket',
    'lightbulb': 'lightbulb',
    'idea': 'lightbulb',
    'insight': 'lightbulb',
    'fire': 'fire',
    'flame': 'fire',
    'hot': 'fire',
    'viral': 'fire',
    'brain': 'brain',
    'ai': 'brain',
    'ml': 'brain',
    'mind': 'brain',
    'sparkles': 'sparkles',
    'sparkle': 'sparkles',
    'magic': 'sparkles',
    'star': 'sparkles',
    'target': 'target',
    'goal': 'target',
    'focus': 'target',
    'code': 'code',
    'dev': 'code',
    'repo': 'code',
    'warning': 'warning',
    'caution': 'warning',
    'alert': 'warning',
    'bookmark': 'bookmark',
    'save': 'bookmark',
    'pin': 'pin',
    'place': 'pin',
    'location': 'pin',
    'map': 'pin',
    'calendar': 'calendar',
    'date': 'calendar',
    'schedule': 'calendar',
    'event': 'calendar',
    'globe': 'globe',
    'web': 'globe',
    'world': 'globe',
  };

  @override
  void initState() {
    super.initState();
    _initTokens();
  }

  @override
  void didUpdateWidget(covariant LatyrRichSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _initTokens();
    }
  }

  void _initTokens() {
    _clearRecognizers();
    final rawTokens = SummaryLexer.tokenize(widget.text);
    _tokenData = rawTokens.map((token) {
      if (token.type == SummaryTokenType.smartLink) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            debugPrint('[LatyrRichSummary] Tap detected on "${token.text}"');
            SummaryActionHandler.handleAction(
              context: context,
              label: token.text,
              actionType: token.actionScheme ?? 'https',
              payload: token.actionPayload ?? '',
            );
          };
        _recognizers.add(recognizer);
        return _RichTokenData(token: token, recognizer: recognizer);
      }
      return _RichTokenData(token: token);
    }).toList();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark ??
        (CupertinoTheme.of(context).brightness == Brightness.dark);
    final primaryTextColor = widget.textColor ??
        (isDark ? CupertinoColors.white : const Color(0xFF1C1C1E));

    final baseStyle = widget.style ??
        TextStyle(
          color: primaryTextColor.withValues(alpha: 0.92),
          fontSize: widget.fontSize ?? 15.5,
          height: widget.lineHeight ?? 1.58,
          fontWeight: FontWeight.w400,
        );

    final spans = <InlineSpan>[];

    for (final item in _tokenData) {
      final token = item.token;
      switch (token.type) {
        case SummaryTokenType.plain:
          spans.add(TextSpan(text: token.text, style: baseStyle));
          break;

        case SummaryTokenType.highlight:
          final highlightBg = isDark
              ? const Color(0x55FFD54F) // warm luminous gold
              : const Color(0x66FFE082); // soft pastel canary yellow
          final highlightText = isDark
              ? const Color(0xFFFFF9C4)
              : const Color(0xFF261C00);

          spans.add(
            TextSpan(
              text: token.text,
              style: baseStyle.copyWith(
                backgroundColor: highlightBg,
                color: highlightText,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
          break;

        case SummaryTokenType.wavyUnderline:
          final underlineColor = isDark
              ? const Color(0xFFFF6961)
              : CupertinoColors.systemRed;

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _HandwrittenWavyText(
                text: token.text,
                style: baseStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                waveColor: underlineColor,
              ),
            ),
          );
          break;

        case SummaryTokenType.italic:
          spans.add(
            TextSpan(
              text: token.text,
              style: baseStyle.copyWith(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
          );
          break;

        case SummaryTokenType.icon3d:
          final rawName = token.iconName?.toLowerCase().trim() ?? '';
          final assetName = _iconAliases[rawName] ?? rawName;

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  label: '$assetName icon',
                  child: Image.asset(
                    'assets/icons/3d/$assetName.png',
                    width: 17.5,
                    height: 17.5,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
          break;

        case SummaryTokenType.smartLink:
          final actionType = (token.actionScheme ?? 'https').toLowerCase().trim();
          final payload = token.actionPayload ?? '';

          Color linkColor;
          IconData prefixIcon;

          switch (actionType) {
            case 'github':
              linkColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
              prefixIcon = CupertinoIcons.chevron_left_slash_chevron_right;
              break;
            case 'maps':
              linkColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
              prefixIcon = CupertinoIcons.location_solid;
              break;
            case 'reminder':
              linkColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
              prefixIcon = CupertinoIcons.bell_fill;
              break;
            case 'tip':
              linkColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFD48800);
              prefixIcon = CupertinoIcons.info_circle_fill;
              break;
            default:
              linkColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
              prefixIcon = CupertinoIcons.arrow_up_right_square;
              break;
          }

          // Prepend interactive micro-icon badge
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () {
                  SummaryActionHandler.handleAction(
                    context: context,
                    label: token.text,
                    actionType: actionType,
                    payload: payload,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 3),
                  child: Icon(prefixIcon, size: 12.5, color: linkColor),
                ),
              ),
            ),
          );

          // Interactive text span
          final isTip = actionType == 'tip';
          final decorationStyle = isTip
              ? TextDecorationStyle.dotted
              : TextDecorationStyle.solid;

          spans.add(
            TextSpan(
              text: token.text,
              recognizer: item.recognizer,
              style: baseStyle.copyWith(
                color: linkColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationStyle: decorationStyle,
                decorationColor: linkColor.withValues(alpha: isTip ? 0.88 : 0.65),
                decorationThickness: isTip ? 2.2 : 1.3,
              ),
            ),
          );
          break;
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}

/// A text widget that renders the given [text] with a handwritten-style
/// wavy underline drawn via [CustomPainter] — larger amplitude, low frequency
/// cubic-Bézier S-curves with a breathing gap below the text baseline.
class _HandwrittenWavyText extends StatelessWidget {
  const _HandwrittenWavyText({
    required this.text,
    required this.style,
    required this.waveColor,
  });

  final String text;
  final TextStyle style;
  final Color waveColor;

  // Wave geometry constants — bold handwritten look without expanding line height
  static const double _amplitude  = 3.2;   // height of crest / trough in px
  static const double _strokeWidth = 2.4;   // bold pen stroke thickness in px
  static const double _wavelength  = 18.0;  // px per full S-cycle (longer = fewer curves)

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _HandwrittenWavePainter(
        color:       waveColor,
        strokeWidth: _strokeWidth,
        amplitude:   _amplitude,
        wavelength:  _wavelength,
      ),
      // No extra bottom padding: preserves natural paragraph line-height and eliminates line gap
      child: Text(text, style: style),
    );
  }
}

/// Draws a handwritten-style wavy underline using cubic Bézier S-curves.
///
/// Draws snugly beneath the text baseline without inflating the layout box,
/// keeping paragraph leading 100% uniform.
class _HandwrittenWavePainter extends CustomPainter {
  const _HandwrittenWavePainter({
    required this.color,
    required this.strokeWidth,
    required this.amplitude,
    required this.wavelength,
  });

  final Color  color;
  final double strokeWidth;
  final double amplitude;
  final double wavelength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // Position wave center 1.2px into the natural line leading valley.
    // Because the WidgetSpan layout box is unchanged, space below does NOT increase.
    final double cy = size.height + 1.2;
    final double w  = wavelength;

    final path = Path()..moveTo(0, cy);

    double x = 0;
    while (x < size.width) {
      final double end = (x + w).clamp(0.0, size.width);

      // Crest half (x → x+w/2): bulge above centre
      path.cubicTo(
        x + w * 0.20, cy - amplitude,
        x + w * 0.45, cy - amplitude,
        x + w * 0.50, cy,
      );
      // Trough half (x+w/2 → x+w): dip below centre
      path.cubicTo(
        x + w * 0.55, cy + amplitude,
        x + w * 0.80, cy + amplitude,
        end,          cy,
      );

      x += w;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HandwrittenWavePainter old) =>
      old.color       != color       ||
      old.strokeWidth != strokeWidth ||
      old.amplitude   != amplitude   ||
      old.wavelength  != wavelength;
}
