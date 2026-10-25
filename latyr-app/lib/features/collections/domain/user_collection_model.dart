class UserCollectionModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? icon;
  final String? colorHex;
  final int itemCount;
  final List<String> previewArtworkUrls;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserCollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon,
    this.colorHex,
    required this.itemCount,
    required this.previewArtworkUrls,
    required this.isPinned,
    this.createdAt,
    this.updatedAt,
  });

  factory UserCollectionModel.fromJson(Map<String, dynamic> json) {
    final rawArtwork = json['preview_artwork_urls'] ?? json['previewArtworkUrls'];
    final rawItemCount = json['item_count'] ?? json['itemCount'];
    final rawUserId = json['user_id'] ?? json['userId'];
    final rawColorHex = json['color_hex'] ?? json['colorHex'];
    final rawIsPinned = json['is_pinned'] ?? json['isPinned'];
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    final rawUpdatedAt = json['updated_at'] ?? json['updatedAt'];

    return UserCollectionModel(
      id: json['id'] as String,
      userId: (rawUserId ?? '') as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      colorHex: rawColorHex as String?,
      itemCount: (rawItemCount as num?)?.toInt() ?? 0,
      previewArtworkUrls: (rawArtwork as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((u) => u.isNotEmpty)
              .toList() ??
          const [],
      isPinned: rawIsPinned as bool? ?? false,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt as String)
          : null,
      updatedAt: rawUpdatedAt != null
          ? DateTime.tryParse(rawUpdatedAt as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': ?description,
      'icon': ?icon,
      'colorHex': ?colorHex,
      'itemCount': itemCount,
      'previewArtworkUrls': previewArtworkUrls,
      'isPinned': isPinned,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserCollectionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    String? colorHex,
    int? itemCount,
    List<String>? previewArtworkUrls,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCollectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      itemCount: itemCount ?? this.itemCount,
      previewArtworkUrls: previewArtworkUrls ?? this.previewArtworkUrls,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
