import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/capture/domain/taxonomy_model.dart';

void main() {
  group('TaxonomyModel Tests', () {
    test('TaxonomyResponse parses categories, subcategories, and counts', () {
      final json = {
        'categories': [
          {
            'name': 'Entertainment',
            'count': 15,
            'subCategories': [
              {
                'name': 'Movies',
                'count': 12,
              },
              {
                'name': 'TV Series',
                'count': 3,
              },
            ],
          },
          {
            'name': 'Tech',
            'count': 8,
            'subCategories': [
              {
                'name': 'AI Tools',
                'count': 6,
              },
            ],
          },
        ],
      };

      final response = TaxonomyResponse.fromJson(json);

      expect(response.categories.length, 2);

      final ent = response.categories.first;
      expect(ent.name, 'Entertainment');
      expect(ent.count, 15);
      expect(ent.subCategories.length, 2);

      final movies = ent.subCategories.first;
      expect(movies.name, 'Movies');
      expect(movies.count, 12);

      final tv = ent.subCategories[1];
      expect(tv.name, 'TV Series');
      expect(tv.count, 3);
    });

    test('TaxonomyResponse handles null or empty safely', () {
      final response = TaxonomyResponse.fromJson({});
      expect(response.categories, isEmpty);
    });
  });
}
