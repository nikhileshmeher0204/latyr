import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/collections/domain/user_collection_model.dart';

void main() {
  group('UserCollectionModel Tests', () {
    test('parses JSON with previewArtworkUrls, itemCount, and metadata', () {
      final json = {
        'id': 'col-123',
        'userId': 'user-456',
        'name': 'Crime Thrillers',
        'description': 'Suspenseful movies and shows',
        'icon': 'film',
        'colorHex': '#E056FD',
        'itemCount': 5,
        'previewArtworkUrls': [
          'https://image.tmdb.org/t/p/w500/poster1.jpg',
          'https://image.tmdb.org/t/p/w500/poster2.jpg',
          'https://image.tmdb.org/t/p/w500/poster3.jpg',
        ],
        'isPinned': true,
        'createdAt': '2026-10-25T10:00:00Z',
        'updatedAt': '2026-10-25T12:00:00Z',
      };

      final model = UserCollectionModel.fromJson(json);

      expect(model.id, 'col-123');
      expect(model.userId, 'user-456');
      expect(model.name, 'Crime Thrillers');
      expect(model.description, 'Suspenseful movies and shows');
      expect(model.icon, 'film');
      expect(model.colorHex, '#E056FD');
      expect(model.itemCount, 5);
      expect(model.previewArtworkUrls.length, 3);
      expect(model.previewArtworkUrls[0], 'https://image.tmdb.org/t/p/w500/poster1.jpg');
      expect(model.isPinned, isTrue);
      expect(model.createdAt, isNotNull);
    });

    test('parses snake_case backend JSON accurately', () {
      final json = {
        'id': 'col-789',
        'user_id': 'user-999',
        'name': 'Crime Thrillers',
        'description': 'Best crime thrillers',
        'icon': 'folder_fill',
        'color_hex': '#28543A',
        'item_count': 1,
        'preview_artwork_urls': [
          'https://image.tmdb.org/t/p/w500/gIClWRv5OSe8rl5Koi0AeUcCZ9Z.jpg',
        ],
        'is_pinned': false,
        'created_at': '2026-10-25T14:58:36.438Z',
        'updated_at': '2026-10-25T15:19:20.092Z',
      };

      final model = UserCollectionModel.fromJson(json);

      expect(model.id, 'col-789');
      expect(model.userId, 'user-999');
      expect(model.name, 'Crime Thrillers');
      expect(model.colorHex, '#28543A');
      expect(model.itemCount, 1);
      expect(model.previewArtworkUrls.length, 1);
      expect(model.previewArtworkUrls[0], 'https://image.tmdb.org/t/p/w500/gIClWRv5OSe8rl5Koi0AeUcCZ9Z.jpg');
      expect(model.isPinned, isFalse);
    });

    test('toJson and copyWith work accurately', () {
      const model = UserCollectionModel(
        id: '1',
        userId: 'u',
        name: 'Tech',
        itemCount: 0,
        previewArtworkUrls: [],
        isPinned: false,
      );

      final updated = model.copyWith(name: 'Dev Tools', itemCount: 3);
      expect(updated.name, 'Dev Tools');
      expect(updated.itemCount, 3);
      expect(updated.id, '1');

      final json = updated.toJson();
      expect(json['name'], 'Dev Tools');
      expect(json['itemCount'], 3);
    });
  });
}
