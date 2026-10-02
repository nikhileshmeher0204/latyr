import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/services/dominant_color_service.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/screens/capture_detail_screen.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

enum MediaBadgeType {
  reel,
  video,
  web,
  image,
  audio,
  note,
}

class CaptureCardWidget extends StatefulWidget {
  final LocalCapture capture;
  final bool isGrid;

  const CaptureCardWidget({
    super.key,
    required this.capture,
    this.isGrid = true,
  });

  @override
  State<CaptureCardWidget> createState() => _CaptureCardWidgetState();
}

class _CaptureCardWidgetState extends State<CaptureCardWidget> {
  DominantPalette? _palette;

  Color get _dominantBackground => _palette?.background ?? const Color(0xFF141824);
  Color get _titleColor => _palette?.titleColor ?? const Color(0xFFF5F9FF).withValues(alpha: 0.96);
  Color get _subtitleColor => _palette?.subtitleColor ?? const Color(0xFFEAF2FF).withValues(alpha: 0.88);
  Color get _separatorColor => _palette?.separatorColor ?? const Color(0xFFEAF2FF).withValues(alpha: 0.55);

  static final List<Shadow> _textShadows = [
    Shadow(
      color: Colors.black.withValues(alpha: 0.80),
      offset: const Offset(0, 1.2),
      blurRadius: 3.5,
    ),
    Shadow(
      color: Colors.black.withValues(alpha: 0.40),
      offset: const Offset(0, 2.0),
      blurRadius: 6.5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final url = widget.capture.thumbnailUrl;
    _palette = DominantColorService.instance.getCachedPalette(url);
    if (_palette == null) {
      _loadDominantColor();
    }
  }

  @override
  void didUpdateWidget(CaptureCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capture.thumbnailUrl != widget.capture.thumbnailUrl) {
      final url = widget.capture.thumbnailUrl;
      final cached = DominantColorService.instance.getCachedPalette(url);
      if (cached != null) {
        _palette = cached;
      } else {
        _loadDominantColor();
      }
    }
  }

  Future<void> _loadDominantColor() async {
    final url = widget.capture.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      final palette = await DominantColorService.instance.extractPalette(url);
      if (mounted) {
        setState(() {
          _palette = palette;
        });
      }
    }
  }

  void _navigateToDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CaptureDetailScreen(capture: widget.capture),
      ),
    );
  }

  String _resolveTitle(LocalCapture capture) {
    final rawTitle = capture.title?.trim();
    if (rawTitle != null && rawTitle.isNotEmpty) {
      final isPlaceholderUrl = rawTitle.startsWith('http://') ||
          rawTitle.startsWith('https://') ||
          rawTitle.toLowerCase().contains('http://') ||
          rawTitle.toLowerCase().contains('https://');
      if (!isPlaceholderUrl) {
        return rawTitle;
      }
    }
    final raw = capture.originalCaption;
    if (raw != null && raw.trim().isNotEmpty) {
      final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      for (final line in lines) {
        if (!line.startsWith('#') &&
            !line.toLowerCase().contains('comment') &&
            !line.toLowerCase().contains('dm me') &&
            !line.toLowerCase().contains('http://') &&
            !line.toLowerCase().contains('https://')) {
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
    // Editorial fallback: never show raw URLs in user-facing cards
    if (capture.contentType == 'IMAGE') {
      return 'Saved Image';
    }
    return 'Instagram Reel';
  }

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    final entities = ExtractedEntityModel.parseListFromJsonString(capture.entitiesJson);
    final tint = _dominantBackground;
    final titleColor = _titleColor;
    final subtitleColor = _subtitleColor;
    final separatorColor = _separatorColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _navigateToDetails,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141722),
          borderRadius: BorderRadius.circular(widget.isGrid ? 16 : 18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: widget.isGrid ? 12 : 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.isGrid
            ? _buildGridCard(capture, entities, tint, titleColor, subtitleColor, separatorColor)
            : _buildListCard(capture, entities, tint, titleColor, subtitleColor, separatorColor),
      ),
    );
  }

  // ─── 2-Column Grid Card Pattern ─────────────────────────────────────────────

  Widget _buildGridCard(
    LocalCapture capture,
    List<ExtractedEntityModel> entities,
    Color tint,
    Color titleColor,
    Color subtitleColor,
    Color separatorColor,
  ) {
    final title = _resolveTitle(capture);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cover Image filling the whole card with SoftEdgeBlur at the bottom
          _buildBlurredCoverImage(tint, isGrid: true),

          // 2. Subtle gradient overlay for contrast over any image
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.22, 0.46, 1.0],
                ),
              ),
            ),
          ),

          // 3. Card Content: Top status badge + Bottom text & metadata
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Loading indicator on right ONLY when analyzing
                Align(
                  alignment: Alignment.topRight,
                  child: _buildCompactStatusBadge(capture.status),
                ),

                // Bottom Content: Title first, then clean dot-separated metadata below
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.32,
                        height: 1.18,
                        shadows: _textShadows,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _buildMetadataRow(
                      capture,
                      entities.length,
                      subtitleColor: subtitleColor,
                      separatorColor: separatorColor,
                      isGrid: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Single-Column Wide Cinematic Tile ──────────────────────────────────────

  Widget _buildListCard(
    LocalCapture capture,
    List<ExtractedEntityModel> entities,
    Color tint,
    Color titleColor,
    Color subtitleColor,
    Color separatorColor,
  ) {
    final title = _resolveTitle(capture);

    return AspectRatio(
      aspectRatio: 16 / 9.5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredCoverImage(tint, isGrid: false),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.74),
                  ],
                  stops: const [0.0, 0.26, 0.56, 1.0],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _buildStatusBadge(capture.status),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.35,
                        height: 1.18,
                        shadows: _textShadows,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildMetadataRow(
                      capture,
                      entities.length,
                      subtitleColor: subtitleColor,
                      separatorColor: separatorColor,
                      isGrid: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredCoverImage(Color tint, {required bool isGrid}) {
    final thumbnailUrl = widget.capture.thumbnailUrl;
    final hasImage = thumbnailUrl != null && thumbnailUrl.isNotEmpty;

    if (!hasImage) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint,
              const Color(0xFF181E2C),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            widget.capture.contentType == 'IMAGE'
                ? CupertinoIcons.photo
                : CupertinoIcons.play_rectangle,
            size: isGrid ? 32 : 42,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      );
    }

    return SoftEdgeBlur(
      edges: [
        EdgeBlur(
          type: EdgeType.bottomEdge,
          size: isGrid ? 85 : 85,
          sigma: isGrid ? 8 : 7,
          tintColor: tint.withValues(alpha: 0.35),
          controlPoints: [
            ControlPoint(position: 0.50, type: ControlPointType.visible),
            ControlPoint(position: 1.0, type: ControlPointType.transparent),
          ],
        ),
      ],
      child: CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: 600,
        placeholder: (context, url) => Container(
          color: tint,
          child: const Center(
            child: CupertinoActivityIndicator(radius: 8, color: Colors.white54),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1C2230),
          child: Center(
            child: Icon(
              CupertinoIcons.photo,
              size: isGrid ? 28 : 36,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  MediaBadgeType _resolveMediaBadgeType(LocalCapture capture) {
    final contentType = capture.contentType.toUpperCase();
    final url = (capture.originalUrl ?? '').toLowerCase();

    if (contentType == 'IMAGE' ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp') ||
        url.endsWith('.gif')) {
      return MediaBadgeType.image;
    }

    if (url.contains('instagram.com/reel') ||
        url.contains('instagram.com/reels') ||
        url.contains('/reel/') ||
        url.contains('/reels/')) {
      return MediaBadgeType.reel;
    }

    if (contentType == 'VIDEO' ||
        url.contains('tiktok.com') ||
        url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.m3u8')) {
      return MediaBadgeType.video;
    }

    // Instagram posts in Latyr default to reels
    if (url.contains('instagram.com')) {
      return MediaBadgeType.reel;
    }

    if (contentType == 'TEXT') {
      return MediaBadgeType.note;
    }

    if (contentType == 'AUDIO') {
      return MediaBadgeType.audio;
    }

    return MediaBadgeType.web;
  }

  IconData _getMediaBadgeIcon(MediaBadgeType type) {
    switch (type) {
      case MediaBadgeType.reel:
      case MediaBadgeType.video:
        return CupertinoIcons.play_fill;
      case MediaBadgeType.web:
        return CupertinoIcons.globe;
      case MediaBadgeType.image:
        return CupertinoIcons.photo;
      case MediaBadgeType.audio:
        return CupertinoIcons.waveform;
      case MediaBadgeType.note:
        return CupertinoIcons.doc_text;
    }
  }

  Widget _buildMediaIcon(MediaBadgeType type, Color color, {required bool isGrid}) {
    final icon = _getMediaBadgeIcon(type);
    final iconSize = isGrid ? 8.5 : 10.0;

    return Icon(
      icon,
      size: iconSize,
      color: color,
      shadows: _textShadows,
    );
  }

  Widget _buildCompactStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_SYNC':
      case 'PROCESSING':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: const CupertinoActivityIndicator(radius: 4, color: Colors.white),
        );
      case 'FAILED':
        return Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(CupertinoIcons.exclamationmark, size: 8, color: Colors.white),
        );
      case 'COMPLETED':
      default:
        // Declutter: show nothing when done
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_SYNC':
      case 'PROCESSING':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 4.5, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'Analyzing…',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        );
      case 'FAILED':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Failed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'COMPLETED':
      default:
        // Declutter: show nothing when done
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetadataRow(
    LocalCapture capture,
    int entityCount, {
    required Color subtitleColor,
    required Color separatorColor,
    bool isGrid = false,
  }) {
    final category = capture.category;
    final intent = capture.intent;
    final hasTranscript =
        capture.audioTranscript != null && capture.audioTranscript!.isNotEmpty;
    final mediaType = _resolveMediaBadgeType(capture);

    final fontSize = isGrid ? 9.5 : 11.0;
    final spans = <InlineSpan>[];

    void addSeparator() {
      if (spans.isNotEmpty) {
        spans.add(
          TextSpan(
            text: '  •  ',
            style: TextStyle(
              color: separatorColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              shadows: _textShadows,
            ),
          ),
        );
      }
    }

    // 1. Primary Category (Clean typography, no emojis)
    if (category != null && category.trim().isNotEmpty) {
      spans.add(
        TextSpan(
          text: category.toUpperCase(),
          style: TextStyle(
            color: subtitleColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.35,
            shadows: _textShadows,
          ),
        ),
      );
    }

    // 2. Intent (if distinct, no emojis)
    if (intent != null &&
        intent.trim().isNotEmpty &&
        intent.toUpperCase() != category?.toUpperCase()) {
      addSeparator();
      spans.add(
        TextSpan(
          text: intent.toUpperCase(),
          style: TextStyle(
            color: subtitleColor.withValues(alpha: 0.80),
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
            shadows: _textShadows,
          ),
        ),
      );
    }

    // 3. Transcript indicator (CC)
    if (hasTranscript) {
      addSeparator();
      spans.add(
        TextSpan(
          text: 'CC',
          style: TextStyle(
            color: subtitleColor.withValues(alpha: 0.80),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            shadows: _textShadows,
          ),
        ),
      );
    }

    // 4. Extracted items count with stacked cards icon (Option 2)
    if (entityCount > 0) {
      addSeparator();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Transform.translate(
            offset: Offset(0, isGrid ? 2.6 : 1.4),
            child: Padding(
              padding: const EdgeInsets.only(right: 2.5),
              child: Icon(
                CupertinoIcons.square_on_square,
                size: fontSize * (isGrid ? 0.90 : 0.82),
                color: subtitleColor.withValues(alpha: 0.85),
                shadows: _textShadows,
              ),
            ),
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: '$entityCount',
          style: TextStyle(
            color: subtitleColor.withValues(alpha: 0.80),
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            shadows: _textShadows,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMediaIcon(mediaType, subtitleColor, isGrid: isGrid),
        if (spans.isNotEmpty) ...[
          SizedBox(width: isGrid ? 4.5 : 5.5),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
