import 'package:flutter_test/flutter_test.dart';
import 'package:latyr_app/features/capture/domain/extracted_entity_model.dart';

void main() {
  group('Entity Metadata Models Tests', () {
    test('EntertainmentMetadata: correctly parses movie data and hero image', () {
      final model = ExtractedEntityModel(
        title: 'Inception',
        description: 'A mind-bending thriller.',
        entityType: 'MOVIE',
        actionCta: 'WATCH_NOW',
        metadata: {
          'poster_url': 'https://image.tmdb.org/poster.jpg',
          'backdrop_url': 'https://image.tmdb.org/backdrop.jpg',
          'rating': '8.8',
          'rating_source': 'IMDb',
          'imdb_votes': '2,400,000',
          'director': 'Christopher Nolan',
          'lead_cast': ['Leonardo DiCaprio', 'Joseph Gordon-Levitt'],
          'genres': ['Sci-Fi', 'Action'],
          'runtime_formatted': '2h 28m',
          'release_year': '2010',
          'streaming_platform': 'Netflix',
          'watch_providers': [
            {'provider_name': 'Netflix', 'category': 'flatrate'}
          ],
        },
      );

      final movie = model.entertainment;
      expect(movie.posterUrl, 'https://image.tmdb.org/poster.jpg');
      expect(movie.backdropUrl, 'https://image.tmdb.org/backdrop.jpg');
      expect(movie.heroImage, 'https://image.tmdb.org/poster.jpg');
      expect(movie.rating, '8.8');
      expect(movie.director, 'Christopher Nolan');
      expect(movie.leadCast, contains('Leonardo DiCaprio'));
      expect(movie.genres, contains('Sci-Fi'));
      expect(movie.runtime, '2h 28m');
      expect(movie.isTv, isFalse);
      expect(movie.formatLabel, 'Movie');
      expect(movie.durationOrSeasons, '2h 28m');
      expect(movie.watchProviders.length, 1);
    });

    test('EntertainmentMetadata: correctly parses TV show data and durationOrSeasons', () {
      final model = ExtractedEntityModel(
        title: 'Severance',
        entityType: 'TV_SHOW',
        actionCta: 'STREAM',
        metadata: {
          'backdrop_url': 'https://image.tmdb.org/backdrop.jpg',
          'seasons_formatted': '2 Seasons',
          'media_type': 'tv',
        },
      );

      final tv = model.entertainment;
      expect(tv.heroImage, 'https://image.tmdb.org/backdrop.jpg');
      expect(tv.isTv, isTrue);
      expect(tv.formatLabel, 'TV Series');
      expect(tv.durationOrSeasons, '2 Seasons');
    });

    test('GitHubRepoMetadata: parses repo fields, formatted counts, and fallbacks', () {
      final model = ExtractedEntityModel(
        title: 'flutter/flutter',
        entityType: 'GITHUB_REPO',
        actionCta: 'OPEN_GITHUB',
        externalUrl: 'https://github.com/flutter/flutter',
        metadata: {
          'full_name': 'flutter/flutter',
          'stars': 165400,
          'forks': 27100,
          'watchers': 3500,
          'language': 'Dart',
          'license': 'BSD-3-Clause',
          'default_branch': 'master',
          'topics': ['flutter', 'dart', 'framework'],
        },
      );

      final repo = model.gitHubRepo;
      expect(repo.fullName, 'flutter/flutter');
      expect(repo.owner, 'flutter');
      expect(repo.repoName, 'flutter');
      expect(repo.stars, 165400);
      expect(repo.starsFormatted, '165.4k');
      expect(repo.forksFormatted, '27.1k');
      expect(repo.language, 'Dart');
      expect(repo.license, 'BSD-3-Clause');
      expect(repo.topics, contains('flutter'));
      expect(repo.repoUrl, 'https://github.com/flutter/flutter');
    });

    test('BookMetadata: parses authors, isbn, and page count', () {
      final model = ExtractedEntityModel(
        title: 'Designing Data-Intensive Applications',
        description: 'The big ideas behind reliable systems.',
        entityType: 'BOOK',
        actionCta: 'BUY_BOOK',
        metadata: {
          'author': 'Martin Kleppmann',
          'isbn': '978-1449373320',
          'publisher': "O'Reilly Media",
          'published_year': '2017',
          'page_count': 616,
          'categories': ['Computers', 'Databases'],
        },
      );

      final book = model.book;
      expect(book.author, 'Martin Kleppmann');
      expect(book.isbn, '978-1449373320');
      expect(book.pageCount, 616);
      expect(book.genres, contains('Computers'));
      expect(book.overview, 'The big ideas behind reliable systems.');
    });

    test('RecipeMetadata: parses ingredients and cook times', () {
      final model = ExtractedEntityModel(
        title: 'Authentic Carbonara',
        entityType: 'RECIPE',
        actionCta: 'VIEW_RECIPE',
        metadata: {
          'ingredients': ['Spaghetti', 'Guanciale', 'Pecorino Romano', 'Eggs', 'Black Pepper'],
          'prep_time': '10m',
          'cook_time': '15m',
          'total_time': '25m',
          'servings': '4',
          'cuisine': 'Italian',
        },
      );

      final recipe = model.recipe;
      expect(recipe.ingredients.length, 5);
      expect(recipe.totalTime, '25m');
      expect(recipe.servings, '4');
      expect(recipe.cuisine, 'Italian');
    });

    test('PlaceMetadata: parses location coordinates and address', () {
      final model = ExtractedEntityModel(
        title: 'Blue Bottle Coffee',
        entityType: 'PLACE',
        actionCta: 'GET_DIRECTIONS',
        metadata: {
          'formatted_address': '315 Linden St, San Francisco, CA',
          'city': 'San Francisco',
          'country': 'USA',
          'latitude': 37.7763,
          'longitude': -122.4233,
          'rating': '4.6',
        },
      );

      final place = model.place;
      expect(place.address, '315 Linden St, San Francisco, CA');
      expect(place.city, 'San Francisco');
      expect(place.latitude, 37.7763);
      expect(place.longitude, -122.4233);
      expect(place.rating, '4.6');
      expect(place.displayLocation, '315 Linden St, San Francisco, CA');
    });

    test('QuoteMetadata: parses quote text and attribution', () {
      final model = ExtractedEntityModel(
        title: 'Stay hungry, stay foolish.',
        description: 'Steve Jobs',
        entityType: 'QUOTE',
        actionCta: 'EXPLORE',
        metadata: {
          'source_work': 'Stanford Commencement Address',
          'year': '2005',
        },
      );

      final quote = model.quote;
      expect(quote.quoteText, 'Stay hungry, stay foolish.');
      expect(quote.author, 'Steve Jobs');
      expect(quote.sourceWork, 'Stanford Commencement Address');
      expect(quote.year, '2005');
    });

    test('GenericEntityMetadata: parses generic properties and tags', () {
      final model = ExtractedEntityModel(
        title: 'Superpowers Framework',
        description: 'Agentic skills framework.',
        entityType: 'TOOL',
        actionCta: 'EXPLORE',
        metadata: {
          'category': 'Developer Tool',
          'tags': ['agentic', 'tdd', 'skills'],
          'source_domain': 'github.com',
          'confidence_score': 0.95,
        },
      );

      final generic = model.generic;
      expect(generic.category, 'Developer Tool');
      expect(generic.tags, contains('agentic'));
      expect(generic.confidenceScore, 0.95);
      expect(generic.summary, 'Agentic skills framework.');
    });
  });
}
