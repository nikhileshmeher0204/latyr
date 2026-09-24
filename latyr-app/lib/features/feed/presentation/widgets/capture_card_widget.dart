import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/feed/presentation/widgets/entity_cards.dart';

class CaptureCardWidget extends StatefulWidget {
  final LocalCapture capture;

  const CaptureCardWidget({super.key, required this.capture});

  @override
  State<CaptureCardWidget> createState() => _CaptureCardWidgetState();
}

class _CaptureCardWidgetState extends State<CaptureCardWidget> {
  bool _showTranscript = false;

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    final entities = ExtractedEntityModel.parseListFromJsonString(capture.entitiesJson);
    debugPrint('[CardRender] id=${capture.id} status=${capture.status} intent=${capture.intent} cap=${capture.originalCaption} entCount=${entities.length}');
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final transcriptBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: separatorColor.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(LSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: source icon + intent + category + status ──────────────
          Row(
            children: [
              Icon(
                capture.contentType == 'IMAGE'
                    ? CupertinoIcons.photo
                    : CupertinoIcons.play_rectangle_fill,
                size: 16,
                color: LColors.brandAmber,
              ),
              const SizedBox(width: LSpacing.sm),
              if (capture.intent != null) ...[
                _buildIntentBadge(capture.intent!),
                const SizedBox(width: LSpacing.xs + 2),
              ],
              if (capture.category != null) _buildCategoryPill(capture.category!, isDark, secondaryColor),
              const Spacer(),
              _buildStatusBadge(capture.status),
            ],
          ),
          const SizedBox(height: LSpacing.md),

          // ── Caption or URL ────────────────────────────────────────────────
          if (capture.originalCaption != null && capture.originalCaption!.isNotEmpty)
            Text(
              capture.originalCaption!,
              style: LTypography.body.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else if (capture.originalUrl != null)
            Text(
              capture.originalUrl!,
              style: LTypography.footnote.copyWith(color: secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          // ── Transcript Toggle ─────────────────────────────────────────────
          if (capture.audioTranscript != null && capture.audioTranscript!.isNotEmpty) ...[
            const SizedBox(height: LSpacing.sm),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showTranscript = !_showTranscript),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: LSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTranscript
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 13,
                      color: LColors.brandAmber,
                    ),
                    const SizedBox(width: LSpacing.xs),
                    Text(
                      _showTranscript ? 'Hide AI Transcript' : 'Show AI Transcript',
                      style: LTypography.caption1.copyWith(
                        color: LColors.brandAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTranscript)
              Container(
                margin: const EdgeInsets.only(top: LSpacing.xs),
                padding: const EdgeInsets.all(LSpacing.md - 2),
                decoration: BoxDecoration(
                  color: transcriptBg,
                  borderRadius: LSpacing.brSM,
                ),
                child: Text(
                  capture.audioTranscript!,
                  style: LTypography.footnote.copyWith(
                    color: secondaryColor,
                    height: 1.45,
                  ),
                ),
              ),
          ],

          // ── Extracted Entities or In-Progress State ────────────────────────
          if (entities.isNotEmpty) ...[
            const SizedBox(height: LSpacing.sm),
            Container(height: 0.5, color: separatorColor),
            const SizedBox(height: LSpacing.sm),
            ...entities.map((e) => EntityCardRouter(entity: e)),
          ] else if (capture.status.toUpperCase() == 'PROCESSING' ||
              capture.status.toUpperCase() == 'PENDING' ||
              capture.status.toUpperCase() == 'PENDING_SYNC') ...[
            const SizedBox(height: LSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: LSpacing.md, vertical: LSpacing.sm + 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: separatorColor.withValues(alpha: isDark ? 0.3 : 0.5),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 6),
                  const SizedBox(width: LSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      capture.status.toUpperCase() == 'PROCESSING'
                          ? 'AI is analyzing media & extracting entities...'
                          : 'Queued for AI analysis...',
                      style: LTypography.footnote.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntentBadge(String intent) {
    Color badgeColor;
    switch (intent.toUpperCase()) {
      case 'WATCH':
        badgeColor = LColors.brandAmber;
        break;
      case 'COOK':
        badgeColor = LColors.warning;
        break;
      case 'EXPLORE':
      case 'VISIT':
        badgeColor = LColors.info;
        break;
      case 'REMEMBER':
        badgeColor = LColors.royalViolet;
        break;
      default:
        badgeColor = LColors.sageEmerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        intent.toUpperCase(),
        style: LTypography.caption2Bold.copyWith(
          color: badgeColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category, bool isDark, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: LTypography.caption2.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_SYNC':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: LColors.brandAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LSpacing.xs),
            Text(
              'Queued',
              style: LTypography.caption2.copyWith(
                color: LColors.brandAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'PROCESSING':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 5),
            const SizedBox(width: LSpacing.xs + 2),
            Text(
              'Analyzing...',
              style: LTypography.caption2.copyWith(
                color: LColors.brandAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'FAILED':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 13,
              color: LColors.error,
            ),
            const SizedBox(width: LSpacing.xs),
            Text(
              'Failed',
              style: LTypography.caption2.copyWith(
                color: LColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'COMPLETED':
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 13,
              color: LColors.success,
            ),
            const SizedBox(width: LSpacing.xs),
            Text(
              'Done',
              style: LTypography.caption2.copyWith(
                color: LColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}
