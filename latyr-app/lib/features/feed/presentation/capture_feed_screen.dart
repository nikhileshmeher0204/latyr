import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

class CaptureFeedScreen extends ConsumerStatefulWidget {
  const CaptureFeedScreen({super.key});

  @override
  ConsumerState<CaptureFeedScreen> createState() => _CaptureFeedScreenState();
}

class _CaptureFeedScreenState extends ConsumerState<CaptureFeedScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'All',
    'Entertainment',
    'Technology',
    'Food',
    'Places',
    'Books',
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleCaptureSubmit() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSubmitting = true);
    _urlController.clear();
    FocusScope.of(context).unfocus();

    try {
      await ref.read(captureRepositoryProvider).captureUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Latyr! Analyzing in background...'),
            backgroundColor: AppTheme.surfaceElevated,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline. Will sync when online.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capturesAsync = ref.watch(captureListStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Latyr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.textSecondary),
            tooltip: 'Sync feed',
            onPressed: () => ref.read(captureRepositoryProvider).fetchRemoteFeed(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Quick Capture Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Paste Instagram Reel or article URL...',
                      prefixIcon: Icon(Icons.add_link_rounded, color: AppTheme.textMuted),
                    ),
                    onSubmitted: (_) => _handleCaptureSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSubmitting ? null : _handleCaptureSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 3. Reactive Capture Feed List
          Expanded(
            child: capturesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (err, _) => Center(
                child: Text('Error loading feed: $err', style: const TextStyle(color: AppTheme.error)),
              ),
              data: (captures) {
                final filtered = _selectedCategory == 'All'
                    ? captures
                    : captures.where((c) => c.category?.toLowerCase() == _selectedCategory.toLowerCase()).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceElevated,
                  onRefresh: () => ref.read(captureRepositoryProvider).fetchRemoteFeed(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return CaptureCardWidget(capture: filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No captures yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share a Reel from Instagram or paste a link above to extract entities and AI transcripts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
