import 'package:flutter/material.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Source icon, category pill, status indicator
            Row(
              children: [
                _buildSourceIcon(capture.contentType),
                const SizedBox(width: 8),
                if (capture.intent != null)
                  _buildIntentBadge(capture.intent!),
                const SizedBox(width: 6),
                if (capture.category != null)
                  _buildCategoryPill(capture.category!),
                const Spacer(),
                _buildStatusBadge(capture.status),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Caption or URL
            if (capture.originalCaption != null && capture.originalCaption!.isNotEmpty)
              Text(
                capture.originalCaption!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            else if (capture.originalUrl != null)
              Text(
                capture.originalUrl!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            // 3. Audio Transcript Collapsible
            if (capture.audioTranscript != null && capture.audioTranscript!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showTranscript = !_showTranscript),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showTranscript ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 16,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showTranscript ? 'Hide audio transcript' : 'Show audio transcript',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showTranscript)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    capture.audioTranscript!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ),
            ],

            // 4. Extracted Entities
            if (entities.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(color: AppTheme.border, height: 16),
              ...entities.map((e) => EntityCardRouter(entity: e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(String contentType) {
    return Icon(
      contentType == 'IMAGE' ? Icons.image_rounded : Icons.link_rounded,
      size: 18,
      color: AppTheme.textMuted,
    );
  }

  Widget _buildIntentBadge(String intent) {
    Color badgeColor = AppTheme.primary;
    switch (intent.toUpperCase()) {
      case 'WATCH': badgeColor = AppTheme.primary; break;
      case 'COOK': badgeColor = AppTheme.warning; break;
      case 'EXPLORE': badgeColor = AppTheme.info; break;
      case 'REMEMBER': badgeColor = const Color(0xFFA855F7); break;
      default: badgeColor = AppTheme.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        intent.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'PENDING_SYNC':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Pending Sync', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
          ],
        );
      case 'PROCESSING':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.info)),
            SizedBox(width: 6),
            Text('Analyzing...', style: TextStyle(fontSize: 11, color: AppTheme.info)),
          ],
        );
      case 'FAILED':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 12, color: AppTheme.error),
            SizedBox(width: 4),
            Text('Failed', style: TextStyle(fontSize: 11, color: AppTheme.error)),
          ],
        );
      default: // COMPLETED
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.accent),
            SizedBox(width: 4),
            Text('Processed', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
          ],
        );
    }
  }
}
