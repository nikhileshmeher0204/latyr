import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'ALL';
    _selectedSubCategory = widget.initialSubCategory;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final topPadding = MediaQuery.paddingOf(context).top;

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
                bottom: LSpacing.sm,
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

          // 2-Column Captures Grid
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
          else
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
                    final capture = filteredCaptures[index];
                    return LatyrCaptureCard(
                      key: ValueKey(capture.id),
                      capture: capture,
                    );
                  },
                  childCount: filteredCaptures.length,
                ),
              ),
            ),

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
    final activeBg = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final activeText = isDark ? CupertinoColors.black : CupertinoColors.white;
    final inactiveBg = isDark ? const Color(0x22FFFFFF) : const Color(0x0C000000);
    final inactiveText = isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);
    final borderColor = isSelected
        ? activeBg
        : (isDark ? const Color(0x33FFFFFF) : const Color(0x18000000));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeText : inactiveText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
    final activeBg = const Color(0xFF28543A); // Latyr signature green
    final activeText = CupertinoColors.white;
    final inactiveBg = isDark ? const Color(0x18FFFFFF) : const Color(0x08000000);
    final inactiveText = isDark
        ? CupertinoColors.white.withValues(alpha: 0.85)
        : const Color(0xFF2C2C2C);
    final borderColor = isSelected
        ? activeBg
        : (isDark ? const Color(0x25FFFFFF) : const Color(0x14000000));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeText : inactiveText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
