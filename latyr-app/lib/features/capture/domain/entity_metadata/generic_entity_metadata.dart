/// Strongly-typed domain metadata model for Tool, Idea, and Generic entities.
class GenericEntityMetadata {
  final String? category;
  final List<String> tags;
  final String? sourceDomain;
  final String? targetPlatform;
  final double? confidenceScore;
  final String? summary;
  final Map<String, dynamic> rawProperties;

  const GenericEntityMetadata({
    this.category,
    this.tags = const [],
    this.sourceDomain,
    this.targetPlatform,
    this.confidenceScore,
    this.summary,
    this.rawProperties = const {},
  });

  factory GenericEntityMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackDescription,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    final rawTags = meta['tags'] ?? meta['keywords'];
    final List<String> tags = (rawTags is List)
        ? rawTags.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return GenericEntityMetadata(
      category: meta['category']?.toString(),
      tags: tags,
      sourceDomain: meta['source_domain']?.toString(),
      targetPlatform: meta['target_platform']?.toString(),
      confidenceScore: parseDouble(meta['confidence_score']),
      summary: meta['summary']?.toString() ?? fallbackDescription,
      rawProperties: Map<String, dynamic>.unmodifiable(meta),
    );
  }
}
