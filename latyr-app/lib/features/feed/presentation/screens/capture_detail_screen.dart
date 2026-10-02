import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/entity_cards.dart';
import 'package:latyr_app/core/services/color_extraction_service.dart';

class CaptureDetailScreen extends StatefulWidget {
  final LocalCapture capture;

  const CaptureDetailScreen({super.key, required this.capture});

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  bool _isCaptionExpanded = false;
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

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    
    // Page background is the capture card color
    final colorList = [
      isDark ? const Color(0xFFC7A222) : const Color(0xFFFFE873),
      isDark ? const Color(0xFF2A9D8F) : const Color(0xFF88D4C8),
      isDark ? const Color(0xFF4C956C) : const Color(0xFFA8E6B6),
      isDark ? const Color(0xFF845EC2) : const Color(0xFFD6B5FF),
      isDark ? const Color(0xFFD65DB1) : const Color(0xFFFF9CEE),
    ];
    final cardColor = _extractedCardColor ?? colorList[capture.id.hashCode.abs() % colorList.length];
    final scaffoldBgColor = cardColor;
    
    // Containers use Home Tab background color (not pure white)
    final containerBgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9);
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    final entities = ExtractedEntityModel.parseListFromJsonString(capture.entitiesJson);
    final isProcessing = capture.status == 'PROCESSING' ||
        capture.status == 'PENDING' ||
        capture.status == 'PENDING_SYNC';

    final navTitle = capture.subCategory ?? capture.category ?? 'Moment';

    return CupertinoPageScaffold(
      backgroundColor: scaffoldBgColor,
      child: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Top and Bottom soft edge blur
                _buildHeroHeader(capture, scaffoldBgColor, textColor, isDark),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      _buildBadgesRow(capture, entities.length, textColor, isDark, containerBgColor),
                      const SizedBox(height: 24),

                      // Summary
                      if (capture.summary != null && capture.summary!.trim().isNotEmpty) ...[
                        _buildSummaryContainer(
                          summary: capture.summary!.trim(),
                          textColor: textColor,
                          isDark: isDark,
                          cardColor: containerBgColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Original Caption
                      if (capture.originalCaption != null &&
                          capture.originalCaption!.trim().isNotEmpty &&
                          capture.originalCaption!.trim() != _resolveTitle(capture).trim()) ...[
                        _buildCollapsibleCaptionContainer(
                          title: 'ORIGINAL CAPTION',
                          content: capture.originalCaption!,
                          textColor: textColor,
                          isDark: isDark,
                          cardColor: containerBgColor,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Audio Transcript
                      if (capture.audioTranscript != null &&
                          capture.audioTranscript!.isNotEmpty) ...[
                        _buildAudioTranscriptSection(capture.audioTranscript!, textColor, isDark, containerBgColor),
                        const SizedBox(height: 24),
                      ],

                      // Processing State
                      if (isProcessing) ...[
                        _buildProcessingBanner(textColor, isDark, containerBgColor),
                        const SizedBox(height: 24),
                      ],

                      // Entities
                      _buildEntitiesSection(entities, textColor, isDark, containerBgColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: containerBgColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.back, color: textColor, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              navTitle,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  BoxDecoration _buildCardDecoration(Color cardColor, bool isDark) {
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withOpacity(isDark ? 0.35 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildSummaryContainer({
    required String summary,
    required Color textColor,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(cardColor, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x33FFFFFF) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.black.withOpacity(isDark ? 0.2 : 0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.text_alignleft, size: 12, color: textColor),
                    const SizedBox(width: 4),
                    Text(
                      'SUMMARY',
                      style: LTypography.caption2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () {
                      // Placeholder for Translate functionality
                    },
                    child: Icon(
                      CupertinoIcons.globe,
                      size: 20,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () {
                      // Placeholder for Audio/Text-to-Speech functionality
                    },
                    child: Icon(
                      CupertinoIcons.speaker_2_fill,
                      size: 20,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: TextStyle(
              color: textColor.withOpacity(0.95),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCaptionContainer({
    required String title,
    required String content,
    required Color textColor,
    required bool isDark,
    required Color cardColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCaptionExpanded = !_isCaptionExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _buildCardDecoration(cardColor, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33FFFFFF) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.black.withOpacity(isDark ? 0.2 : 0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.text_quote, size: 12, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: LTypography.caption2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isCaptionExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  size: 16,
                  color: textColor.withOpacity(0.7),
                ),
              ],
            ),
            if (_isCaptionExpanded) ...[
              const SizedBox(height: 16),
              SelectableText(
                content,
                style: TextStyle(
                  color: textColor.withOpacity(0.95),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioTranscriptSection(String transcript, Color textColor, bool isDark, Color cardColor) {
    return Container(
      width: double.infinity,
      decoration: _buildCardDecoration(cardColor, isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33FFFFFF) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.black.withOpacity(isDark ? 0.2 : 0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.waveform, size: 12, color: textColor),
                const SizedBox(width: 4),
                Text(
                  'AUDIO TRANSCRIPT',
                  style: LTypography.caption2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            transcript,
            style: TextStyle(
              color: textColor.withOpacity(0.95),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
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
                    color: textColor.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(LocalCapture capture, Color scaffoldBgColor, Color textColor, bool isDark) {
    final thumbnailUrl = capture.thumbnailUrl;
    final hasImage = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final title = _resolveTitle(capture);

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        if (hasImage)
          AspectRatio(
            aspectRatio: 1 / 1, // Square aspect ratio for a larger immersive header
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Base image with smooth alpha dissipation into scaffoldBgColor
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.48, 0.72, 1.0],
                      colors: [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFFFFFFF),
                        const Color(0x80FFFFFF),
                        const Color(0x00FFFFFF),
                        const Color(0x00FFFFFF),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(color: scaffoldBgColor),
                    errorWidget: (context, url, error) => Container(color: scaffoldBgColor),
                  ),
                ),
                // 2. Gentle color wash over the transition zone for harmonious palette blending
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.20, 0.48, 0.72, 1.0],
                        colors: [
                          scaffoldBgColor.withOpacity(0.0),
                          scaffoldBgColor.withOpacity(0.0),
                          scaffoldBgColor.withOpacity(0.45),
                          scaffoldBgColor,
                          scaffoldBgColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              color: scaffoldBgColor,
              child: Center(
                child: Icon(
                  capture.contentType == 'IMAGE' ? CupertinoIcons.photo : CupertinoIcons.play_rectangle,
                  color: textColor.withOpacity(0.2),
                  size: 64,
                ),
              ),
            ),
          ),
        
        // Title Overlay
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Text(
            title,
            style: LTypography.title1.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
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
          _buildPill('$entityCount INSIGHTS', textColor, isDark, icon: CupertinoIcons.sparkles, cardColor: cardColor),
        _buildPill(capture.status == 'COMPLETED' ? 'DONE' : 'ANALYZING', textColor, isDark, cardColor: cardColor),
      ],
    );
  }

  Widget _buildPill(String text, Color textColor, bool isDark, {IconData? icon, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: LTypography.caption2.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
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





