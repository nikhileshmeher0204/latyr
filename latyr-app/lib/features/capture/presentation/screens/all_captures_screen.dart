import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_spacing.dart';
import 'package:latyr_app/core/design/latyr_typography.dart';
import 'package:latyr_app/core/widgets/latyr_capture_card.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_app_bar.dart';
import 'package:latyr_app/core/widgets/navigation/latyr_scaffold.dart';
import 'package:latyr_app/features/capture/domain/taxonomy_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/capture/presentation/taxonomy_providers.dart';

class AllCapturesScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialSubCategory;

  const AllCapturesScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
  });

  @override
  ConsumerState<AllCapturesScreen> createState() => _AllCapturesScreenState();
}

class _AllCapturesScreenState extends ConsumerState<AllCapturesScreen> {
  late String _selectedCategory;
  String? _selectedSubCategory;
  bool _isDescending = true; // Most Recent (Descending) timestamp by default

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'ALL';
    _selectedSubCategory = widget.initialSubCategory;
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return (month >= 1 && month <= 12) ? months[month] : '';
  }

  String _getTimelineTitle(DateTime createdAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diffDays = today.difference(itemDate).inDays;

    if (diffDays <= 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays <= 7) return 'Last Week';
    if (diffDays <= 30) return 'Last Month';
    return '${_getMonthName(itemDate.month)} ${itemDate.year}';
  }

  void _showSortActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Sort Captures'),
        message: const Text('Order by creation timestamp'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!_isDescending) setState(() => _isDescending = true);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isDescending) ...[
                  const Icon(CupertinoIcons.check_mark, size: 16, color: Color(0xFF78E4A5)),
                  const SizedBox(width: 8),
                ],
                const Text('Most Recent (Latest First)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (_isDescending) setState(() => _isDescending = false);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isDescending) ...[
                  const Icon(CupertinoIcons.check_mark, size: 16, color: Color(0xFF78E4A5)),
                  const SizedBox(width: 8),
                ],
                const Text('Oldest First'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final topPadding = MediaQuery.paddingOf(context).top;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);

    final capturesAsync = ref.watch(captureListStreamProvider);
    final allCaptures = (capturesAsync.valueOrNull ?? [])
        .where((c) => c.status == 'COMPLETED')
        .toList();

    final taxonomy = ref.watch(localTaxonomyProvider);

    // Filter captures based on active category & subcategory
    final filteredCaptures = allCaptures.where((c) {
      if (_selectedCategory != 'ALL') {
        final catMatch = (c.category ?? '').toLowerCase() == _selectedCategory.toLowerCase();
        if (!catMatch) return false;
      }
      if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty) {
        final subMatch = (c.subCategory ?? '').toLowerCase() == _selectedSubCategory!.toLowerCase();
        if (!subMatch) return false;
      }
      return true;
    }).toList();

    // Sort captures based on _isDescending timestamp
    filteredCaptures.sort((a, b) {
      final cmp = b.createdAt.compareTo(a.createdAt);
      return _isDescending ? cmp : -cmp;
    });

    // Group sorted captures into ordered timeline buckets
    final Map<String, List<LocalCapture>> timelineGroups = {};
    final now = DateTime.now();
    for (final capture in filteredCaptures) {
      final groupTitle = _getTimelineTitle(capture.createdAt, now);
      timelineGroups.putIfAbsent(groupTitle, () => []).add(capture);
    }

    // Find subcategories for the active root category
    final activeTaxonomyCategory = taxonomy.cast<TaxonomyCategory?>().firstWhere(
      (cat) => cat?.name.toLowerCase() == _selectedCategory.toLowerCase(),
      orElse: () => null,
    );

    return LatyrScaffold(
      backgroundColor: scaffoldBg,
      appBar: LatyrAppBar(
        title: 'CAPTURES',
        titleLeading: const Icon(CupertinoIcons.square_grid_2x2_fill, size: 16),
        isDark: isDark,
        scaffoldBgColor: scaffoldBg,
        isPersistent: false,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isDescending = !_isDescending;
              });
            },
            child: GestureDetector(
              onLongPress: () => _showSortActionSheet(context),
              child: Container(
                width: LatyrAppBar.kActionButtonSize,
                height: LatyrAppBar.kActionButtonSize,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xCC1C1C1E)
                      : CupertinoColors.white.withValues(alpha: 0.95),
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
                  _isDescending ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                  size: 19,
                  color: _isDescending
                      ? const Color(0xFF78E4A5) // Light green icon color when applied
                      : textColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        slivers: [
          // Filter Bar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 68.0,
                bottom: LSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Root Categories
                  _buildRootCategoryBar(
                    taxonomy: taxonomy,
                    totalAllCount: allCaptures.length,
                    isDark: isDark,
                  ),

                  // Row 2: Cascading Sub-Categories (smooth animated expansion)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _selectedCategory == 'ALL' || activeTaxonomyCategory == null
                        ? const SizedBox.shrink()
                        : _buildSubCategoryBar(
                            category: activeTaxonomyCategory,
                            isDark: isDark,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Captures Grid grouped by Timelines
          if (filteredCaptures.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(LSpacing.xl2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(LSpacing.lg),
                        decoration: BoxDecoration(
                          color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.tray,
                          size: 38,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: LSpacing.base),
                      Text(
                        'No captures in this view',
                        style: LTypography.roundedTitle2.copyWith(
                          color: isDark ? CupertinoColors.white : const Color(0xFF1A1A1A),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            for (final entry in timelineGroups.entries) ...[
              // Section Header: Editorial Georgia Font
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: LSpacing.screenH,
                    right: LSpacing.screenH,
                    top: 20.0,
                    bottom: 10.0,
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              // 2-Column Captures Grid for this Timeline
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final capture = entry.value[index];
                      return LatyrCaptureCard(
                        key: ValueKey(capture.id),
                        capture: capture,
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildRootCategoryBar({
    required List<TaxonomyCategory> taxonomy,
    required int totalAllCount,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH, vertical: 6),
      child: Row(
        children: [
          // "ALL" Filter Pill
          _buildPill(
            label: 'ALL',
            count: totalAllCount,
            isSelected: _selectedCategory == 'ALL',
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = 'ALL';
                _selectedSubCategory = null;
              });
            },
          ),
          const SizedBox(width: 8),

          // Dynamic Category Pills
          ...taxonomy.map((cat) {
            final isSelected = _selectedCategory.toLowerCase() == cat.name.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPill(
                label: cat.name.toUpperCase(),
                count: cat.count,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = cat.name;
                    _selectedSubCategory = null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubCategoryBar({
    required TaxonomyCategory category,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: LSpacing.screenH),
        child: Row(
          children: [
            // "All <Category>" subcategory reset pill
            _buildSubPill(
              label: 'All ${category.name}',
              isSelected: _selectedSubCategory == null,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSubCategory = null);
              },
            ),
            const SizedBox(width: 6),

            // Dynamic Subcategory Pills
            ...category.subCategories.map((sub) {
              final isSelected = _selectedSubCategory?.toLowerCase() == sub.name.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildSubPill(
                  label: sub.name,
                  count: sub.count,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedSubCategory = null;
                      } else {
                        _selectedSubCategory = sub.name;
                      }
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required int count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final activeBg = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final activeText = isDark ? CupertinoColors.black : CupertinoColors.white;
    final inactiveText = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeBg : borderColor,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeText : inactiveText.withValues(alpha: 0.85),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
                letterSpacing: 0.4,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0x22000000) : const Color(0x25FFFFFF))
                      : (isDark ? const Color(0x33FFFFFF) : const Color(0x18000000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeText : inactiveText.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubPill({
    required String label,
    int? count,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : CupertinoColors.white.withValues(alpha: 0.95);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
    final activeBg = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final activeText = isDark ? CupertinoColors.black : CupertinoColors.white;
    final inactiveText = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBg : borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeText : inactiveText.withValues(alpha: 0.85),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? activeText.withValues(alpha: 0.85) : inactiveText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
