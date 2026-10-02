import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/services/dominant_color_service.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/entity_cards.dart';
import 'package:latyr_app/shared/widgets/apple_tv_badge.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:url_launcher/url_launcher.dart';

class CaptureDetailScreen extends StatefulWidget {
  final LocalCapture capture;

  const CaptureDetailScreen({super.key, required this.capture});

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _loadDominantColor();
  }

  Future<void> _loadDominantColor() async {
    final url = widget.capture.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      final color = await DominantColorService.instance.extractDominantColor(url);
      if (mounted) {
        setState(() {
          _dominantColor = color;
        });
      }
    }
  }

  Future<void> _openOriginalUrl() async {
    final rawUrl = widget.capture.originalUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
              cleaned = spaceIndex > 20 ? '${cleaned.substring(0, spaceIndex)}…' : '${cleaned.substring(0, 80)}…';
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
    final entities = ExtractedEntityModel.parseListFromJsonString(capture.entitiesJson);
    final tint = _dominantColor ?? const Color(0xFF161A26);
    final isProcessing = capture.status == 'PROCESSING' ||
        capture.status == 'PENDING' ||
        capture.status == 'PENDING_SYNC';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0C0F17),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF0C0F17).withValues(alpha: 0.88),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, color: Colors.white, size: 22),
              SizedBox(width: 4),
              Text('Captures', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
        trailing: capture.originalUrl != null && capture.originalUrl!.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openOriginalUrl,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        capture.contentType == 'IMAGE'
                            ? CupertinoIcons.photo
                            : CupertinoIcons.play_circle_fill,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Original',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Header with Ambient Glow & SoftEdgeBlur ─────────────────
              _buildHeroHeader(capture, tint),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Primary Headline (AI Title) First ─────────────────────
                    Text(
                      _resolveTitle(capture),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Timestamp ─────────────────────────────────────────────
                    Text(
                      _formatDate(capture.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Apple TV Badges Row (Below Title) ─────────────────────
                    _buildBadgesRow(capture, entities.length),
                    const SizedBox(height: 20),

                    // ── Creator Caption (if distinct from headline) ───────────
                    if (capture.originalCaption != null &&
                        capture.originalCaption!.trim().isNotEmpty &&
                        capture.originalCaption!.trim() != _resolveTitle(capture).trim()) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141824),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORIGINAL CAPTION',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              capture.originalCaption!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Processing Banner (if in progress) ────────────────────
                    if (isProcessing) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const CupertinoActivityIndicator(radius: 8, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AI Analysis in Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Extracting transcription, tools, repos & highlights...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Audio Transcript Card ─────────────────────────────────
                    if (capture.audioTranscript != null &&
                        capture.audioTranscript!.isNotEmpty) ...[
                      _buildAudioTranscriptSection(capture.audioTranscript!),
                      const SizedBox(height: 24),
                    ],

                    // ── Extracted Entities / Insights Section ─────────────────
                    _buildEntitiesSection(entities),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(LocalCapture capture, Color tint) {
    final thumbnailUrl = capture.thumbnailUrl;
    final hasImage = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient tint
          Container(
            color: tint.withValues(alpha: 0.3),
          ),

          if (hasImage)
            SoftEdgeBlur(
              edges: [
                EdgeBlur(
                  type: EdgeType.bottomEdge,
                  size: 80,
                  sigma: 6,
                  tintColor: const Color(0xFF0C0F17).withValues(alpha: 0.6),
                  controlPoints: [
                    ControlPoint(position: 0.5, type: ControlPointType.visible),
                    ControlPoint(position: 1.0, type: ControlPointType.transparent),
                  ],
                ),
              ],
              child: CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: tint,
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 10, color: Colors.white54),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF141824),
                  child: const Center(
                    child: Icon(CupertinoIcons.photo, color: Colors.white24, size: 48),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                capture.contentType == 'IMAGE'
                    ? CupertinoIcons.photo
                    : CupertinoIcons.play_rectangle,
                size: 56,
                color: Colors.white24,
              ),
            ),

          // Gentle top vignette for navigation bar legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0C0F17).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Tap to open indicator
          if (capture.originalUrl != null && capture.originalUrl!.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openOriginalUrl,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(CupertinoIcons.play_fill, size: 12, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Watch Reel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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


  Widget _buildBadgesRow(LocalCapture capture, int entityCount) {
    final category = capture.category;
    final intent = capture.intent;
    final hasTranscript =
        capture.audioTranscript != null && capture.audioTranscript!.isNotEmpty;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (category != null && category.isNotEmpty)
          AppleTvBadge(
            label: category,
            emoji: _getCategoryEmoji(category),
          ),
        if (intent != null &&
            intent.isNotEmpty &&
            intent.toUpperCase() != category?.toUpperCase())
          AppleTvBadge(
            label: intent,
            emoji: _getIntentEmoji(intent),
          ),
        if (hasTranscript)
          const AppleTvBadge(
            label: 'CC',
            variant: AppleTvBadgeVariant.solid,
          ),
        if (entityCount > 0)
          AppleTvBadge(
            label: '$entityCount ${entityCount == 1 ? 'INSIGHT' : 'INSIGHTS'}',
            emoji: '✨',
          ),
        _buildStatusBadge(capture.status),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_SYNC':
        return const AppleTvBadge(label: 'QUEUED', emoji: '⏳');
      case 'PROCESSING':
        return const AppleTvBadge(label: 'ANALYZING', emoji: '⚡');
      case 'FAILED':
        return const AppleTvBadge(label: 'FAILED', emoji: '✕');
      case 'COMPLETED':
      default:
        return const AppleTvBadge(
          label: 'DONE',
          emoji: '✓',
          variant: AppleTvBadgeVariant.solid,
        );
    }
  }

  Widget _buildAudioTranscriptSection(String transcript) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: LColors.brandAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.waveform,
                      size: 15,
                      color: LColors.brandAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Audio Transcript',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: transcript));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(CupertinoIcons.doc_on_doc, size: 12, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            transcript,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitiesSection(List<ExtractedEntityModel> entities) {
    if (entities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141824),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 28,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No Extracted Entities',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.sparkles, size: 16, color: LColors.brandAmber),
            const SizedBox(width: 8),
            Text(
              'Extracted Insights & Actions (${entities.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...entities.map(
          (entity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EntityCardRouter(entity: entity),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute $period';
  }

  String _getIntentEmoji(String intent) {
    switch (intent.toUpperCase()) {
      case 'WATCH':
        return '📺';
      case 'COOK':
      case 'EAT':
        return '🍳';
      case 'EXPLORE':
      case 'VISIT':
        return '📍';
      case 'BUY':
      case 'SHOP':
        return '🛍️';
      case 'REMEMBER':
      case 'SAVE':
        return '🔖';
      case 'LEARN':
      case 'READ':
        return '💡';
      default:
        return '⚡';
    }
  }

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('tech') || lower.contains('ai') || lower.contains('software')) {
      return '⚡';
    } else if (lower.contains('food') || lower.contains('cook') || lower.contains('recipe')) {
      return '🍕';
    } else if (lower.contains('travel') || lower.contains('place')) {
      return '✈️';
    } else if (lower.contains('fitness') || lower.contains('health')) {
      return '💪';
    } else if (lower.contains('music') || lower.contains('audio')) {
      return '🎵';
    } else if (lower.contains('art') || lower.contains('design')) {
      return '🎨';
    }
    return '📁';
  }
}
