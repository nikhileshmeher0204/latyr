import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latyr_app/core/widgets/latyr_expandable_text.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/github_language_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/features/collections/presentation/user_collections_provider.dart';
import 'package:latyr_app/features/collections/presentation/widgets/add_to_collection_bottom_sheet.dart';
import 'package:latyr_app/features/feed/presentation/widgets/intent_detail_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

const String _fontFamily = 'Inter';
const String _roundedFontFamily = 'InterRounded';

/// Dedicated GitHub Application style detail screen.
/// Developer tool aesthetic with live stars, forks, language badges, and deep-link actions.
class GitHubRepoDetailScreen extends ConsumerStatefulWidget {
  final ExtractedEntityModel entity;
  final String? categoryTitle;

  const GitHubRepoDetailScreen({
    super.key,
    required this.entity,
    this.categoryTitle,
  });

  @override
  ConsumerState<GitHubRepoDetailScreen> createState() => _GitHubRepoDetailScreenState();
}

class _GitHubRepoDetailScreenState extends ConsumerState<GitHubRepoDetailScreen> {

  void _toggleAdd(BuildContext context) {
    HapticFeedback.lightImpact();
    AddToCollectionBottomSheet.show(
      context,
      entity: widget.entity,
      suggestedCollectionName: widget.categoryTitle ?? 'Developer Tools',
    );
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final entityId = entity.id;
    final entityCollectionIdsAsync = entityId != null
        ? ref.watch(entityCollectionIdsProvider(entityId))
        : const AsyncValue.data(<String>{});
    final isInAnyCollection = (entityCollectionIdsAsync.valueOrNull ?? <String>{}).isNotEmpty;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final textColor = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1F2328);
    final subtextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);

    // Strongly-typed metadata extraction
    final repo = entity.gitHubRepo;
    final owner = repo.owner;
    final repoName = repo.repoName;
    final avatarUrl = repo.avatarUrl;
    final starsFormatted = repo.starsFormatted;
    final forksFormatted = repo.forksFormatted;
    final watchersFormatted = repo.watchersFormatted;
    final openIssues = repo.openIssues;
    final language = repo.language;
    final license = repo.license;
    final homepage = repo.homepage;
    final defaultBranch = repo.defaultBranch;
    final isArchived = repo.isArchived;
    final relativeTime = GitHubLanguageColors.formatRelativeTime(repo.pushedAt);
    final List<String> topics = repo.topics;
    final audit = repo.audit;
    final repoUrl = repo.repoUrl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scaffoldBg,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: scaffoldBg,
        child: Stack(
          children: [
            // 1. Main Scrollable Developer View (scrolls cleanly under the progressive blur)
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 68,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Repository Identity Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Owner Avatar Squircle
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEEF2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor, width: 0.8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: avatarUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => _buildAvatarFallback(owner),
                                        )
                                      : _buildAvatarFallback(owner),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (owner.isNotEmpty)
                                        Text(
                                          owner,
                                          style: TextStyle(
                                            fontFamily: _fontFamily,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: subtextColor,
                                            letterSpacing: -0.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        repoName,
                                        style: TextStyle(
                                          fontFamily: _roundedFontFamily,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isArchived)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD29922).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFD29922).withValues(alpha: 0.5), width: 0.8),
                                    ),
                                    child: const Text(
                                      'Archived',
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD29922),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // Description
                            if (entity.description != null && entity.description!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              LatyrExpandableText(
                                text: entity.description!,
                                maxLines: 3,
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: textColor.withValues(alpha: 0.9),
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            Divider(height: 1, thickness: 0.6, color: borderColor),
                            const SizedBox(height: 14),

                            // Compact Metrics Row (Language \u00B7 Stars \u00B7 Forks \u00B7 License \u00B7 Recency)
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (language.isNotEmpty) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: GitHubLanguageColors.resolve(language),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        language,
                                        style: TextStyle(
                                          fontFamily: _fontFamily,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.star_fill, size: 12, color: Color(0xFFE3B341)),
                                    const SizedBox(width: 4),
                                    Text(
                                      starsFormatted,
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.arrow_branch, size: 12, color: subtextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      forksFormatted,
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (license.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: borderColor, width: 0.8),
                                    ),
                                    child: Text(
                                      license,
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ),
                                ],
                                if (relativeTime.isNotEmpty) ...[
                                  Text(
                                    relativeTime,
                                    style: TextStyle(
                                      fontFamily: _fontFamily,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // High-Contrast Action Buttons
                      // Primary: "Open on GitHub \u2197" (Launch external application / GitHub Mobile)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _launchExternalUrl(repoUrl),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF238636) : const Color(0xFF1F2328),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? const Color(0xFF238636) : Colors.black).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/github_mark.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Open on GitHub',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '\u2197',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Secondary: "Website & Docs \u2197" (if homepage exists)
                      if (homepage != null && homepage.isNotEmpty && homepage.startsWith('http')) ...[
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchExternalUrl(homepage),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.globe, size: 14, color: textColor),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Documentation & Website',
                                    style: TextStyle(
                                      fontFamily: _fontFamily,
                                      color: textColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('\u2197', style: TextStyle(color: subtextColor, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Topics & Tags
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TOPICS',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: subtextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: topics.map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF388BFD) : const Color(0xFF0969DA)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (isDark ? const Color(0xFF388BFD) : const Color(0xFF0969DA)).withValues(alpha: 0.25),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                topic,
                                style: TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Specifications Table
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'REPOSITORY SPECS',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: subtextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            if (owner.isNotEmpty)
                              _buildSpecRow(label: 'Owner / Org', value: owner, textColor: textColor, subtextColor: subtextColor, isLast: false, borderColor: borderColor),
                            _buildSpecRow(label: 'Default Branch', value: defaultBranch, textColor: textColor, subtextColor: subtextColor, isLast: false, borderColor: borderColor),
                            if (openIssues != null)
                              _buildSpecRow(label: 'Open Issues', value: openIssues, textColor: textColor, subtextColor: subtextColor, isLast: false, borderColor: borderColor),
                            _buildSpecRow(label: 'Watchers', value: watchersFormatted, textColor: textColor, subtextColor: subtextColor, isLast: false, borderColor: borderColor),
                            if (language.isNotEmpty)
                              _buildSpecRow(label: 'Primary Language', value: language, textColor: textColor, subtextColor: subtextColor, isLast: false, borderColor: borderColor),
                            if (license.isNotEmpty)
                              _buildSpecRow(label: 'License', value: license, textColor: textColor, subtextColor: subtextColor, isLast: true, borderColor: borderColor),
                          ],
                        ),
                      ),

                      // Audit Telemetry (Observable Provenance)
                      if (audit != null) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'RESOLUTION TELEMETRY',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: subtextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.6),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.checkmark_shield_fill, size: 14, color: isDark ? const Color(0xFF3FB950) : const Color(0xFF1A7F37)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Strategy: ${audit['strategy_applied'] ?? 'DIRECT_LOOKUP'} (${audit['latency_ms'] ?? 0}ms) \u00B7 Source: ${audit['source_provider'] ?? 'GITHUB_REST_V3'}',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: subtextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 48),
                    ],
                  ),
                ),

                // 2. Floating Navigation Bar (Identical byte-to-byte architecture with CaptureDetailScreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IntentDetailAppBar(
                    title: widget.categoryTitle ?? 'GITHUB REPOSITORY',
                    titleLeading: null,
                    isDark: isDark,
                    scaffoldBgColor: scaffoldBg,
                    actions: [
                      // Share Button (Action 1)
                      IntentDetailAppBar.buildActionButton(
                        isDark: isDark,
                        onPressed: () => _copyToClipboard(context, repoUrl),
                        child: Icon(
                          CupertinoIcons.share,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                      // Add (+) Button (Action 2)
                      IntentDetailAppBar.buildActionButton(
                        isDark: isDark,
                        onPressed: () => _toggleAdd(context),
                        child: Icon(
                          isInAnyCollection ? CupertinoIcons.check_mark : CupertinoIcons.add,
                          color: isInAnyCollection ? CupertinoColors.activeGreen : textColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildAvatarFallback(String owner) {
    return Center(
      child: Text(
        owner.isNotEmpty ? owner[0].toUpperCase() : 'G',
        style: const TextStyle(
          fontFamily: _roundedFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64D2FF),
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required String label,
    required String value,
    required Color textColor,
    required Color subtextColor,
    required bool isLast,
    required Color borderColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.6, color: borderColor),
      ],
    );
  }

  void _launchExternalUrl(String url) async {
    debugPrint('[GitHubRepoDetail] _launchExternalUrl called with: $url');
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('[GitHubRepoDetail] launchUrl externalApplication result: $launched');
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        debugPrint('[GitHubRepoDetail] launchUrl error: $e');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Link Copied'),
        content: Text(url),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
