import 'dart:convert';
import 'entity_metadata/entity_metadata.dart';

export 'entity_metadata/entity_metadata.dart';

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

/// Ergonomic, type-safe getters for domain-specific metadata
extension ExtractedEntityMetadataX on ExtractedEntityModel {
  /// Typed metadata for Movie and TV Show entities.
  EntertainmentMetadata get entertainment => EntertainmentMetadata.fromMap(
        metadata,
        fallbackOverview: description,
        entityType: entityType,
      );

  /// Typed metadata for GitHub Repository entities.
  GitHubRepoMetadata get gitHubRepo => GitHubRepoMetadata.fromMap(
        metadata,
        fallbackTitle: title,
        fallbackUrl: externalUrl,
      );

  /// Typed metadata for Book entities.
  BookMetadata get book => BookMetadata.fromMap(
        metadata,
        fallbackDescription: description,
      );

  /// Typed metadata for Recipe entities.
  RecipeMetadata get recipe => RecipeMetadata.fromMap(
        metadata,
        fallbackDescription: description,
      );

  /// Typed metadata for Place / Location entities.
  PlaceMetadata get place => PlaceMetadata.fromMap(
        metadata,
        fallbackTitle: title,
      );

  /// Typed metadata for Quote entities.
  QuoteMetadata get quote => QuoteMetadata.fromMap(
        metadata,
        fallbackQuote: title,
        fallbackAuthor: description,
      );

  /// Typed metadata for Tool, Idea, and Generic entities.
  GenericEntityMetadata get generic => GenericEntityMetadata.fromMap(
        metadata,
        fallbackDescription: description,
      );
}

