import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/design/latyr_colors.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/collections/domain/collection_models.dart';

// Helper to assign stable icon and color based on category name
({IconData icon, Color color}) _getCategoryMetadata(String category) {
  final cat = category.trim().toLowerCase();
  if (cat.contains('tech') || cat.contains('dev')) {
    return (icon: CupertinoIcons.command, color: LColors.sageEmerald);
  } else if (cat.contains('entertain') || cat.contains('movie')) {
    return (icon: CupertinoIcons.film_fill, color: LColors.terracotta);
  } else if (cat.contains('learn') || cat.contains('edu')) {
    return (icon: CupertinoIcons.book_fill, color: LColors.royalViolet);
  } else if (cat.contains('food') || cat.contains('cook')) {
    return (icon: CupertinoIcons.flame_fill, color: LColors.warning);
  } else if (cat.contains('place') || cat.contains('travel')) {
    return (icon: CupertinoIcons.map_pin_ellipse, color: LColors.info);
  } else if (cat.contains('quote') || cat.contains('wisdom')) {
    return (icon: CupertinoIcons.text_quote, color: LColors.royalViolet);
  } else if (cat.contains('uncategorized')) {
    return (icon: CupertinoIcons.folder_fill, color: CupertinoColors.systemGrey);
  } else {
    // Generate a stable color based on string hash
    final colors = [
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPink,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
    ];
    final hash = category.hashCode.abs();
    return (icon: CupertinoIcons.folder_solid, color: colors[hash % colors.length]);
  }
}

final rootCollectionsProvider = Provider<AsyncValue<List<CategoryGroup>>>((ref) {
  final capturesAsync = ref.watch(captureListStreamProvider);

  return capturesAsync.whenData((captures) {
    final Map<String, List<LocalCapture>> grouped = {};

    for (final capture in captures) {
      final category = (capture.category == null || capture.category!.trim().isEmpty)
          ? 'Uncategorized'
          : capture.category!.trim();
          
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(capture);
    }

    final List<CategoryGroup> result = grouped.entries.map((entry) {
      final meta = _getCategoryMetadata(entry.key);
      return CategoryGroup(
        categoryName: entry.key,
        captures: entry.value,
        icon: meta.icon,
        color: meta.color,
      );
    }).toList();

    // Sort by number of captures, descending. Then alphabetically.
    result.sort((a, b) {
      final countCmp = b.captures.length.compareTo(a.captures.length);
      if (countCmp != 0) return countCmp;
      if (a.categoryName == 'Uncategorized') return 1;
      if (b.categoryName == 'Uncategorized') return -1;
      return a.categoryName.compareTo(b.categoryName);
    });

    return result;
  });
});

final subCategoriesProvider = Provider.family<List<SubCategoryGroup>, String>((ref, categoryName) {
  final capturesAsync = ref.watch(captureListStreamProvider);
  final captures = capturesAsync.valueOrNull ?? [];
  
  final categoryCaptures = captures.where((c) {
    final cat = (c.category == null || c.category!.trim().isEmpty) ? 'Uncategorized' : c.category!.trim();
    return cat == categoryName;
  }).toList();

  final Map<String, List<LocalCapture>> grouped = {};
  for (final capture in categoryCaptures) {
    final subCat = (capture.subCategory == null || capture.subCategory!.trim().isEmpty)
        ? 'Other'
        : capture.subCategory!.trim();
        
    if (!grouped.containsKey(subCat)) {
      grouped[subCat] = [];
    }
    grouped[subCat]!.add(capture);
  }

  final List<SubCategoryGroup> result = grouped.entries.map((e) {
    return SubCategoryGroup(
      subCategoryName: e.key,
      captures: e.value,
    );
  }).toList();

  // Sort subcategories alphabetically, with 'Other' at the end
  result.sort((a, b) {
    if (a.subCategoryName == 'Other') return 1;
    if (b.subCategoryName == 'Other') return -1;
    return a.subCategoryName.compareTo(b.subCategoryName);
  });

  return result;
});
