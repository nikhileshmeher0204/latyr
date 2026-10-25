class TaxonomyResponse {
  final List<TaxonomyCategory> categories;

  const TaxonomyResponse({required this.categories});

  factory TaxonomyResponse.fromJson(Map<String, dynamic> json) {
    final list = json['categories'] as List<dynamic>? ?? [];
    return TaxonomyResponse(
      categories: list
          .map((c) => TaxonomyCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TaxonomyCategory {
  final String name;
  final int count;
  final List<TaxonomySubCategory> subCategories;

  const TaxonomyCategory({
    required this.name,
    required this.count,
    required this.subCategories,
  });

  factory TaxonomyCategory.fromJson(Map<String, dynamic> json) {
    final subs = json['subCategories'] as List<dynamic>? ?? [];
    return TaxonomyCategory(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      subCategories: subs
          .map((s) => TaxonomySubCategory.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TaxonomySubCategory {
  final String name;
  final int count;

  const TaxonomySubCategory({
    required this.name,
    required this.count,
  });

  factory TaxonomySubCategory.fromJson(Map<String, dynamic> json) {
    return TaxonomySubCategory(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
