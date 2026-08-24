import 'dart:convert';

class ExtractedEntityModel {
  final String? id;
  final String title;
  final String? description;
  final String? externalUrl;
  final String entityType;
  final String actionCta;
  final Map<String, dynamic> metadata;

  ExtractedEntityModel({
    this.id,
    required this.title,
    this.description,
    this.externalUrl,
    required this.entityType,
    required this.actionCta,
    this.metadata = const {},
  });

  factory ExtractedEntityModel.fromJson(Map<String, dynamic> json) {
    return ExtractedEntityModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Entity',
      description: json['description']?.toString(),
      externalUrl: json['external_url']?.toString() ?? json['externalUrl']?.toString(),
      entityType: json['entity_type']?.toString() ?? json['entityType']?.toString() ?? 'IDEA',
      actionCta: json['action_cta']?.toString() ?? json['actionCta']?.toString() ?? 'EXPLORE',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
    );
  }

  static List<ExtractedEntityModel> parseListFromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => ExtractedEntityModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
