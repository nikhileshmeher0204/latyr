/// Strongly-typed domain metadata model for Book entities.
class BookMetadata {
  final String? author;
  final String? isbn;
  final String? publisher;
  final String? publishedYear;
  final int? pageCount;
  final String? coverUrl;
  final List<String> genres;
  final String? rating;
  final String? buyUrl;
  final String? overview;

  const BookMetadata({
    this.author,
    this.isbn,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.coverUrl,
    this.genres = const [],
    this.rating,
    this.buyUrl,
    this.overview,
  });

  factory BookMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackDescription,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    final rawGenres = meta['genres'] ?? meta['categories'];
    final List<String> genres = (rawGenres is List)
        ? rawGenres.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    int? parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return BookMetadata(
      author: meta['author']?.toString() ?? meta['authors']?.toString(),
      isbn: meta['isbn']?.toString(),
      publisher: meta['publisher']?.toString(),
      publishedYear: meta['published_year']?.toString() ?? meta['publication_date']?.toString(),
      pageCount: parseInt(meta['page_count']),
      coverUrl: meta['cover_url']?.toString() ?? meta['thumbnail']?.toString(),
      genres: genres,
      rating: meta['rating']?.toString(),
      buyUrl: meta['buy_url']?.toString() ?? meta['preview_url']?.toString(),
      overview: meta['overview']?.toString() ?? fallbackDescription,
    );
  }
}
