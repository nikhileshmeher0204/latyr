import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:latyr_app/config/app_properties.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/enums/capture_source.dart';
import 'package:latyr_app/core/services/color_extraction_service.dart';
import 'package:latyr_app/core/util/capture_source_classifier.dart';
import 'package:latyr_app/core/widgets/capture_source_icon.dart';
import 'package:latyr_app/core/widgets/latyr_progressive_blur.dart';
import 'package:latyr_app/core/widgets/rich_summary/latyr_rich_summary.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/entity_cards.dart';

class CaptureDetailScreen extends StatefulWidget {
  final LocalCapture capture;

  const CaptureDetailScreen({super.key, required this.capture});

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  bool _isCaptionExpanded = false;
  bool _isFavorited = false;
  Color? _extractedCardColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_extractedCardColor == null) {
      final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
      ColorExtractionService.extractDominantColor(widget.capture.thumbnailUrl, isDark: isDark).then((color) {
        if (mounted) {
          setState(() {
            _extractedCardColor = color;
          });
        }
      });
    }
  }

  String _resolveTitle(LocalCapture capture) {
    if (capture.title != null && capture.title!.trim().isNotEmpty) {
      return capture.title!.trim();
    }
    final raw = capture.originalCaption;
    if (raw != null && raw.trim().isNotEmpty) {
      final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      for (final line in lines) {
        if (!line.startsWith('#') &&
            !line.toLowerCase().contains('comment') &&
            !line.toLowerCase().contains('dm me')) {
          var cleaned = line.replaceAll(RegExp(r'#\w+'), '').trim();
          if (cleaned.isNotEmpty) {
            final sentenceMatch = RegExp(r'^(.*?[.!?])(?:\s|$)').firstMatch(cleaned);
            if (sentenceMatch != null && sentenceMatch.group(1)!.length >= 10 && sentenceMatch.group(1)!.length <= 95) {
              return sentenceMatch.group(1)!.trim();
            }
            if (cleaned.length > 80) {
              final spaceIndex = cleaned.lastIndexOf(' ', 80);
              cleaned = spaceIndex > 20 ? '${cleaned.substring(0, spaceIndex)}...' : '${cleaned.substring(0, 80)}...';
            }
            return cleaned;
          }
        }
      }
    }
    return capture.originalUrl ?? 'Saved Media';
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'just now';
    final now = DateTime.now();
    final diff = now.difference(date);
    final seconds = diff.inSeconds;

    if (seconds < 60) {
      final s = seconds <= 0 ? 1 : seconds;
      return '${s}s ago';
    }
    final minutes = diff.inMinutes;
    if (minutes < 60) {
      return '${minutes}m ago';
    }
    final hours = diff.inHours;
    if (hours < 24) {
      return '${hours}h ago';
    }
    final days = diff.inDays;
    if (days < 7) {
      return '${days}d ago';
    }
    final weeks = (days / 7).floor();
    if (weeks < 4) {
      return '${weeks}w ago';
    }
    final months = (days / 30).floor();
    if (months < 12) {
      return '${months}m ago';
    }
    final years = (days / 365).floor();
    return '${years}y ago';
  }

  Color _deriveFunkyTitleColor(Color baseColor, bool isDark) {
    final hsv = HSVColor.fromColor(baseColor);
    if (isDark) {
      // In dark mode: luminous, elevated vibrant tint of the extracted color instead of plain white.
      // Moderate-to-high saturation (0.35-0.65) and bright value (0.96) so the hue radiates with elegance.
      final saturation = (hsv.saturation * 1.35).clamp(0.35, 0.65);
      const value = 0.96;
      return HSVColor.fromAHSV(1.0, hsv.hue, saturation, value).toColor();
    } else {
      // In light mode: deep, rich, saturated ink tone of the extracted color instead of plain black.
      // High saturation (0.70-0.98) and deep value (0.22-0.30) for punchy contrast against pastel background aura.
      final isYellowWarm = hsv.hue >= 35.0 && hsv.hue <= 70.0;
      final saturation = (hsv.saturation * 1.6).clamp(0.70, 0.98);
      final value = isYellowWarm ? 0.30 : 0.22;
      return HSVColor.fromAHSV(1.0, hsv.hue, saturation, value).toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    
    // Fallback pastel palette if extraction is pending
    final colorList = [
      isDark ? const Color(0xFFC7A222) : const Color(0xFFFFE873),
      isDark ? const Color(0xFF2A9D8F) : const Color(0xFF88D4C8),
      isDark ? const Color(0xFF4C956C) : const Color(0xFFA8E6B6),
      isDark ? const Color(0xFF845EC2) : const Color(0xFFD6B5FF),
      isDark ? const Color(0xFFD65DB1) : const Color(0xFFFF9CEE),
    ];
    final cardColor = _extractedCardColor ?? colorList[capture.id.hashCode.abs() % colorList.length];
    
    // Light, fresh airy canvas matching the Home Tab
    final scaffoldBgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final cardSurfaceColor = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final subtextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);
    final titleColor = _deriveFunkyTitleColor(cardColor, isDark);

    final entities = ExtractedEntityModel.parseListFromJsonString(capture.entitiesJson);
    final isProcessing = capture.status == 'PROCESSING' ||
        capture.status == 'PENDING' ||
        capture.status == 'PENDING_SYNC';

    final navTitle = capture.subCategory ?? capture.category ?? 'Moment';
    final title = _resolveTitle(capture);
    final hasImage = capture.thumbnailUrl != null && capture.thumbnailUrl!.isNotEmpty;

    final topPadding = MediaQuery.of(context).padding.top;
    final navBarHeight = topPadding + 58.0;

    return CupertinoPageScaffold(
      backgroundColor: scaffoldBgColor,
      child: Stack(
        children: [
          // 1. Continuous Ambient Pastel Aura: Flows from top (y=0) all the way down behind hero
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 520,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 0.70, 1.0],
                    colors: [
                      cardColor.withValues(alpha: isDark ? 0.38 : 0.45),
                      cardColor.withValues(alpha: isDark ? 0.22 : 0.28),
                      cardColor.withValues(alpha: isDark ? 0.07 : 0.09),
                      scaffoldBgColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top spacing so title sits with comfortable breathing room below floating bar
                SizedBox(height: topPadding + 68),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Editorial Title in Georgia Serif
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 32,
                          height: 1.16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Relative Time Pill
                      Row(
                        children: [
                          // White (light mode) / Dynamic Dark (dark mode) Pill with Colored Time Icon
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clock_fill,
                                  size: 12,
                                  color: isDark ? const Color(0xFFFFB340) : const Color(0xFFFF8A00),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _formatRelativeTime(capture.createdAt),
                                  style: LTypography.caption2.copyWith(
                                    color: textColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Source Attribution Pill (omitted cleanly if unknown)
                          Builder(
                            builder: (context) {
                              final source = CaptureSource.fromString(capture.sourceType) ??
                                  CaptureSourceClassifier.classify(capture.originalUrl ?? capture.originalCaption);
                              if (source == null) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CaptureSourceIcon(
                                        source: source,
                                        size: 13,
                                        color: textColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        source.displayName,
                                        style: LTypography.caption2.copyWith(
                                          color: textColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Curated Polaroid / Framed Hero Photo Card
                      if (hasImage) ...[
                        _buildCuratedMediaCard(
                          capture: capture,
                          cardColor: cardColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Candy Context Badges Row
                      _buildBadgesRow(capture, entities.length, textColor, isDark, cardColor),
                      const SizedBox(height: 24),

                      // Editorial Summary Card
                      if (capture.summary != null && capture.summary!.trim().isNotEmpty) ...[
                        _buildSummaryContainer(
                          summary: capture.summary!.trim(),
                          textColor: textColor,
                          subtextColor: subtextColor,
                          isDark: isDark,
                          cardColor: cardSurfaceColor,
                          accentColor: cardColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Original Caption
                      if (capture.originalCaption != null &&
                          capture.originalCaption!.trim().isNotEmpty &&
                          capture.originalCaption!.trim() != title.trim()) ...[
                        _buildCollapsibleCaptionContainer(
                          title: 'ORIGINAL CAPTION',
                          content: capture.originalCaption!,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          isDark: isDark,
                          cardColor: cardSurfaceColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Audio Transcript
                      if (capture.audioTranscript != null &&
                          capture.audioTranscript!.isNotEmpty) ...[
                        _buildAudioTranscriptSection(
                          capture.audioTranscript!,
                          textColor,
                          subtextColor,
                          isDark,
                          cardSurfaceColor,
                          cardColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Processing State Banner
                      if (isProcessing) ...[
                        _buildProcessingBanner(textColor, isDark, cardSurfaceColor),
                        const SizedBox(height: 24),
                      ],

                      // Extracted Insights & Actions
                      _buildEntitiesSection(entities, textColor, isDark, cardSurfaceColor),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. High-Performance Progressive Frosted Blur Backdrop
          if (AppProperties.enableTopBlur || AppProperties.enableTopTint)
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

          // 4. Floating Navigation Bar (Seamless, transparent backdrop without cut-off box)
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
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
                        child: Icon(CupertinoIcons.back, color: textColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Centered Sub Category Bubble Pill (WITHOUT icon)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
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
                          child: Text(
                            navTitle.toUpperCase(),
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
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right Actions: Favorite & Share
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _isFavorited = !_isFavorited;
                            });
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
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
                            child: Icon(
                              _isFavorited ? CupertinoIcons.suit_heart_fill : CupertinoIcons.suit_heart,
                              color: _isFavorited ? CupertinoColors.systemPink : textColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // Share action placeholder
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xCC1C1C1E) : CupertinoColors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
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
                            child: Icon(CupertinoIcons.share, color: textColor, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedMediaCard({
    required LocalCapture capture,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: CupertinoColors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: isDark ? 0.4 : 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: capture.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: cardColor.withValues(alpha: 0.3)),
              errorWidget: (context, url, error) => Container(color: cardColor.withValues(alpha: 0.3)),
            ),
            // Floating badge on the image
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      capture.contentType == 'VIDEO' ? CupertinoIcons.play_arrow_solid : CupertinoIcons.photo,
                      size: 11,
                      color: CupertinoColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      capture.contentType == 'VIDEO' ? 'REEL' : 'PHOTO',
                      style: LTypography.caption2.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(Color cardColor, bool isDark) {
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: isDark ? 0.35 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildSummaryContainer({
    required String summary,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    required Color cardColor,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _buildCardDecoration(cardColor, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.text_alignleft, size: 12, color: textColor),
                    const SizedBox(width: 5),
                    Text(
                      'SUMMARY',
                      style: LTypography.caption2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {},
                    child: Icon(
                      CupertinoIcons.globe,
                      size: 19,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {},
                    child: Icon(
                      CupertinoIcons.speaker_2,
                      size: 19,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LatyrRichSummary(
            text: summary,
            textColor: textColor,
            cardAccentColor: accentColor,
            isDark: isDark,
            fontSize: 15.5,
            lineHeight: 1.58,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCaptionContainer({
    required String title,
    required String content,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: _buildCardDecoration(cardColor, isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isCaptionExpanded = !_isCaptionExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.quote_bubble, size: 12, color: textColor),
                      const SizedBox(width: 5),
                      Text(
                        title,
                        style: LTypography.caption2.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isCaptionExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  size: 16,
                  color: subtextColor,
                ),
              ],
            ),
          ),
          if (_isCaptionExpanded) ...[
            const SizedBox(height: 14),
            Text(
              content,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.88),
                fontSize: 14,
                height: 1.52,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioTranscriptSection(
    String transcript,
    Color textColor,
    Color subtextColor,
    bool isDark,
    Color cardColor,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      decoration: _buildCardDecoration(cardColor, isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.waveform, size: 12, color: textColor),
                const SizedBox(width: 5),
                Text(
                  'AUDIO TRANSCRIPT',
                  style: LTypography.caption2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            transcript,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingBanner(Color textColor, bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(cardColor, isDark),
      child: Row(
        children: [
          CupertinoActivityIndicator(radius: 12, color: textColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis in Progress',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Extracting transcription, tools, repos & highlights...',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow(LocalCapture capture, int entityCount, Color textColor, bool isDark, Color cardColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (capture.category != null && capture.category!.isNotEmpty)
          _buildPill(capture.category!, textColor, isDark, cardColor: cardColor),
        if (capture.intent != null &&
            capture.intent!.isNotEmpty &&
            capture.intent!.toUpperCase() != capture.category?.toUpperCase())
          _buildPill(capture.intent!, textColor, isDark, cardColor: cardColor),
        if (entityCount > 0)
          _buildPill('$entityCount INSIGHTS', textColor, isDark, icon: CupertinoIcons.doc_on_doc, cardColor: cardColor),
        if (capture.status != 'COMPLETED')
          _buildPill('ANALYZING', textColor, isDark, cardColor: cardColor),
      ],
    );
  }

  Widget _buildPill(String text, Color textColor, bool isDark, {IconData? icon, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LTypography.caption2.copyWith(
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitiesSection(List<ExtractedEntityModel> entities, Color textColor, bool isDark, Color cardColor) {
    if (entities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.sparkles, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              'Extracted Insights & Actions',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...entities.map(
          (entity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EntityCardRouter(entity: entity, cardColor: cardColor),
          ),
        ),
      ],
    );
  }
}
