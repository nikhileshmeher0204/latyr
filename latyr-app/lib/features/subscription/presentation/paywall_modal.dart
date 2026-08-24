import 'package:flutter/material.dart';
import 'package:latyr_app/core/theme/app_theme.dart';

class PaywallModal extends StatelessWidget {
  final int usedCaptures;
  final int quotaLimit;

  const PaywallModal({
    super.key,
    this.usedCaptures = 12,
    this.quotaLimit = 30,
  });

  static void show(BuildContext context, {int used = 12, int limit = 30}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallModal(usedCaptures: used, quotaLimit: limit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (usedCaptures / quotaLimit).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pro Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LATYR PRO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Unlock Unlimited Knowledge',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture every Reel, recipe, and tool without monthly limits.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Quota Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Free Quota', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('$usedCaptures / $quotaLimit captures', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation(progress >= 0.8 ? AppTheme.warning : AppTheme.primaryLight),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Perks List
          _buildPerk(Icons.all_inclusive_rounded, '1,000 Captures / Month', 'Save unlimited Reels, Shorts & web links'),
          _buildPerk(Icons.bolt_rounded, 'Priority Gemini 1.5 Multimodal AI', 'Instant audio transcription & OCR vision extraction'),
          _buildPerk(Icons.notifications_active_rounded, 'Personalized Push Resurfacing', 'Smart Friday watchlist & Sunday recipe digests'),
          _buildPerk(Icons.offline_pin_rounded, 'Full Offline SQLite Sync', 'Instant capture from share sheet in <300ms'),

          const SizedBox(height: 24),

          // Subscribe Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('RevenueCat Sandbox: Upgraded to PRO tier!'),
                  backgroundColor: AppTheme.accent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: const Text(
              'Upgrade to Pro — \$4.99 / month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Cancel anytime. Powered by RevenueCat.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPerk(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
