import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/collections/domain/user_collection_model.dart';

class UserCollectionsNotifier extends AsyncNotifier<List<UserCollectionModel>> {
  @override
  Future<List<UserCollectionModel>> build() async {
    return _fetchCollections();
  }

  Future<List<UserCollectionModel>> _fetchCollections() async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.getUserCollections();
    final list = response.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => UserCollectionModel.fromJson(m))
        .toList();
  }

  Future<UserCollectionModel> createCollection({
    required String name,
    String? description,
    String? icon,
    String? colorHex,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.createCollection(
      name: name,
      description: description,
      icon: icon,
      colorHex: colorHex,
    );
    final created = UserCollectionModel.fromJson(response.data!);
    ref.invalidateSelf();
    return created;
  }

  Future<void> updateCollection(
    String id, {
    String? name,
    String? description,
    String? icon,
    String? colorHex,
    bool? isPinned,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.updateCollection(
      id,
      name: name,
      description: description,
      icon: icon,
      colorHex: colorHex,
      isPinned: isPinned,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCollection(String id) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteCollection(id);
    ref.invalidateSelf();
  }

  Future<void> addEntityToCollection(String collectionId, String entityId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.addEntityToCollection(collectionId, entityId);
    ref.invalidate(collectionEntitiesProvider(collectionId));
    ref.invalidate(entityCollectionIdsProvider(entityId));
    ref.invalidateSelf();
  }

  Future<void> removeEntityFromCollection(String collectionId, String entityId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.removeEntityFromCollection(collectionId, entityId);
    ref.invalidate(collectionEntitiesProvider(collectionId));
    ref.invalidate(entityCollectionIdsProvider(entityId));
    ref.invalidateSelf();
  }
}

final userCollectionsProvider =
    AsyncNotifierProvider<UserCollectionsNotifier, List<UserCollectionModel>>(
  UserCollectionsNotifier.new,
);

final collectionEntitiesProvider =
    FutureProvider.family<List<ExtractedEntityModel>, String>((ref, collectionId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getCollectionEntities(collectionId);
  final list = response.data;
  if (list == null) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map((m) => ExtractedEntityModel.fromJson(m))
      .toList();
});

final entityCollectionIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, entityId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getEntityCollections(entityId);
  final list = response.data;
  if (list == null) return <String>{};
  return list.map((e) => e.toString()).toSet();
});
