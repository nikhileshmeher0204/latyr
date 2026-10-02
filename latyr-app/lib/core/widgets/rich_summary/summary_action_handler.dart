import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles interactive smart action taps originating from [LatyrRichSummary].
class SummaryActionHandler {
  SummaryActionHandler._();

  /// Routes and executes the smart action based on [actionType] and [payload].
  static Future<void> handleAction({
    required BuildContext context,
    required String label,
    required String actionType,
    required String payload,
  }) async {
    debugPrint('[SummaryActionHandler] handleAction: label="$label", type="$actionType", payload="$payload"');
    // Provide tactile feedback on tap
    HapticFeedback.lightImpact();

    final normalizedType = actionType.toLowerCase().trim();

    switch (normalizedType) {
      case 'tip':
        _showTooltipModal(context, label: label, definition: payload);
        break;

      case 'github':
        await _handleGitHubAction(payload);
        break;

      case 'maps':
        await _handleMapsAction(payload);
        break;

      case 'reminder':
        _showReminderSheet(context, label: label, reminderCue: payload);
        break;

      case 'http':
      case 'https':
        final fullUrl = '$actionType:$payload';
        await _launchWebUrl(fullUrl);
        break;

      default:
        // Attempt generic URL launch
        final genericUrl = payload.contains('://') ? payload : '$actionType:$payload';
        await _launchWebUrl(genericUrl);
        break;
    }
  }

  /// Displays an editorial iOS-style tooltip popup with definition and context.
  static void _showTooltipModal(
    BuildContext context, {
    required String label,
    required String definition,
  }) {
    debugPrint('[SummaryActionHandler] Showing tooltip modal for "$label"');
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final decodedDefinition = Uri.decodeComponent(definition.replaceAll('+', ' '));

    showCupertinoModalPopup<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext modalContext) {
        final cardBg = isDark ? const Color(0xFF1E1E22) : CupertinoColors.white;
        final titleColor = isDark ? CupertinoColors.white : const Color(0xFF1C1C1E);
        final textColor = isDark ? const Color(0xFFD1D1D6) : const Color(0xFF3A3A3C);
        final accentColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFE5A800);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with badge and dismiss icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.lightbulb_fill, size: 12, color: accentColor),
                          const SizedBox(width: 5),
                          Text(
                            'CONCEPT EXPLAINER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.of(modalContext).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 13,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Term Title
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Definition Text
                Text(
                  decodedDefinition,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),

                // Dismiss pill button
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.of(modalContext).pop(),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Resolves GitHub requests using the Two-Tier strategy:
  /// Direct URL if provided, or search fallback that never 404s.
  static Future<void> _handleGitHubAction(String payload) async {
    final decoded = Uri.decodeComponent(payload.trim());
    Uri targetUri;

    if (decoded.startsWith('https://github.com/') || decoded.startsWith('http://github.com/')) {
      targetUri = Uri.parse(decoded);
    } else {
      targetUri = Uri.parse('https://github.com/search?q=${Uri.encodeComponent(decoded)}');
    }

    await _launchUriSafely(targetUri);
  }

  /// Resolves Maps requests with universal geo-query deep-linking.
  static Future<void> _handleMapsAction(String payload) async {
    final decoded = Uri.decodeComponent(payload.trim());
    final targetUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(decoded)}',
    );
    await _launchUriSafely(targetUri);
  }

  /// Displays the Cupertino Resurfacing Action Sheet for reminders.
  static void _showReminderSheet(
    BuildContext context, {
    required String label,
    required String reminderCue,
  }) {
    final decodedCue = Uri.decodeComponent(reminderCue.replaceAll('+', ' '));

    showCupertinoModalPopup<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: Text(
            'Schedule Reminder',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          message: Text(
            'Latyr will resurface "$label"${decodedCue.isNotEmpty ? ' ($decodedCue)' : ''}:',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmReminder(context, 'Tomorrow morning at 9:00 AM');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.sun_max_fill, size: 18),
                  SizedBox(width: 8),
                  Text('Tomorrow morning (9:00 AM)'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmReminder(context, 'This weekend (Saturday at 10:00 AM)');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.calendar, size: 18),
                  SizedBox(width: 8),
                  Text('This weekend (Saturday 10:00 AM)'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmReminder(context, 'Next Monday at 9:00 AM');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bell_fill, size: 18),
                  SizedBox(width: 8),
                  Text('Next week (Monday 9:00 AM)'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  /// Displays a subtle confirmation indicator when a reminder is selected.
  static void _confirmReminder(BuildContext context, String timeSlot) {
    debugPrint('[SummaryActionHandler] _confirmReminder: $timeSlot');
    _showToast(context, 'Reminder scheduled for $timeSlot');
  }

  /// Displays an elegant floating Cupertino toast banner using native Overlay.
  static void _showToast(BuildContext context, String message) {
    debugPrint('[SummaryActionHandler] _showToast: $message');
    HapticFeedback.mediumImpact();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      debugPrint('[SummaryActionHandler] Overlay.maybeOf returned null!');
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 84,
        left: 24,
        right: 24,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) => Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xF01C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x33FFFFFF),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF34C759),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  /// Safe browser launch wrapper.
  static Future<void> _launchWebUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      await _launchUriSafely(uri);
    }
  }

  static Future<void> _launchUriSafely(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Graceful error silence for device intent failure
    }
  }
}
