import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/features/capture/domain/taxonomy_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';

/// Fetches dynamic taxonomy from the Latyr API.
final taxonomyRemoteProvider = FutureProvider<TaxonomyResponse>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getTaxonomy();
  if (response.data != null) {
    return TaxonomyResponse.fromJson(response.data!);
  }
  return const TaxonomyResponse(categories: []);
});

/// Reactive provider that derives taxonomy directly from the local Drift captures database,
/// guaranteeing zero-latency instant rendering and 100% data-driven subcategory counts.
final localTaxonomyProvider = Provider<List<TaxonomyCategory>>((ref) {
  final capturesAsync = ref.watch(captureListStreamProvider);
  final captures = capturesAsync.valueOrNull ?? [];

  // Group captures by category -> subCategory -> count
  final Map<String, Map<String, int>> map = {};

  for (final capture in captures) {
    final cat = capture.category?.trim();
    if (cat == null || cat.isEmpty) continue;

    final sub = capture.subCategory?.trim();
    final effectiveSub = (sub != null && sub.isNotEmpty) ? sub : cat;

    map.putIfAbsent(cat, () => {})[effectiveSub] =
        (map[cat]![effectiveSub] ?? 0) + 1;
  }

  final List<TaxonomyCategory> result = [];

  for (final entry in map.entries) {
    final catName = entry.key;
    final subMap = entry.value;

    int totalCatCount = 0;
    final List<TaxonomySubCategory> subs = [];

    for (final subEntry in subMap.entries) {
      totalCatCount += subEntry.value;
      subs.add(TaxonomySubCategory(
        name: subEntry.key,
        count: subEntry.value,
      ));
    }

    // Sort subcategories descending by count
    subs.sort((a, b) => b.count.compareTo(a.count));

    result.add(TaxonomyCategory(
      name: catName,
      count: totalCatCount,
      subCategories: subs,
    ));
  }

  // Sort categories descending by count
  result.sort((a, b) => b.count.compareTo(a.count));

  return result;
});
