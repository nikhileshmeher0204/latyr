/// Strongly-typed domain metadata model for Movie and TV Show entities.
class EntertainmentMetadata {
  final String? posterUrl;
  final String? backdropUrl;
  final String? rating;
  final String ratingSource;
  final String? imdbVotes;
  final String? rottenTomatoesRating;
  final String? metascoreRating;
  final String? contentRating;
  final String? awards;
  final String? writers;
  final String? country;
  final String? language;
  final String? releasedDate;
  final String? boxOffice;
  final String? releaseYear;
  final String? runtime;
  final String? seasons;
  final String? tagline;
  final String? overview;
  final String? streamingPlatform;
  final String? streamingDeepLink;
  final String? imdbId;
  final String? director;
  final List<String> leadCast;
  final List<String> genres;
  final bool isTv;
  final String formatLabel;
  final String? durationOrSeasons;
  final String? providerLogoUrl;
  final List<Map<String, dynamic>> watchProviders;
  final Map<String, dynamic>? resolutionAudit;

  const EntertainmentMetadata({
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.ratingSource = 'IMDb',
    this.imdbVotes,
    this.rottenTomatoesRating,
    this.metascoreRating,
    this.contentRating,
    this.awards,
    this.writers,
    this.country,
    this.language,
    this.releasedDate,
    this.boxOffice,
    this.releaseYear,
    this.runtime,
    this.seasons,
    this.tagline,
    this.overview,
    this.streamingPlatform,
    this.streamingDeepLink,
    this.imdbId,
    this.director,
    this.leadCast = const [],
    this.genres = const [],
    this.isTv = false,
    this.formatLabel = 'Movie',
    this.durationOrSeasons,
    this.providerLogoUrl,
    this.watchProviders = const [],
    this.resolutionAudit,
  });

  /// Best hero visual: returns poster if available, otherwise backdrop image.
  String? get heroImage => (posterUrl != null && posterUrl!.isNotEmpty)
      ? posterUrl
      : ((backdropUrl != null && backdropUrl!.isNotEmpty) ? backdropUrl : null);

  /// Factory constructor to safely extract and normalize typed fields from untyped map.
  factory EntertainmentMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackOverview,
    String? entityType,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};
    final isTv = (meta['media_type']?.toString().toLowerCase() == 'tv' ||
        entityType?.toUpperCase() == 'TV_SHOW');
    final seasons = meta['seasons_formatted']?.toString();
    final runtime = meta['runtime_formatted']?.toString();

    final rawCast = meta['lead_cast'];
    final List<String> leadCast = (rawCast is List)
        ? rawCast.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    final rawGenres = meta['genres'];
    final List<String> genres = (rawGenres is List)
        ? rawGenres.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    final rawProviders = meta['watch_providers'];
    final List<Map<String, dynamic>> watchProviders = (rawProviders is List)
        ? rawProviders.whereType<Map<String, dynamic>>().toList()
        : const [];

    final audit = meta['resolution_audit'];

    return EntertainmentMetadata(
      posterUrl: meta['poster_url']?.toString(),
      backdropUrl: meta['backdrop_url']?.toString(),
      rating: meta['rating']?.toString(),
      ratingSource: meta['rating_source']?.toString() ?? 'IMDb',
      imdbVotes: meta['imdb_votes']?.toString(),
      rottenTomatoesRating: meta['rotten_tomatoes_rating']?.toString(),
      metascoreRating: meta['metascore_rating']?.toString(),
      contentRating: meta['content_rating']?.toString(),
      awards: meta['awards']?.toString(),
      writers: meta['writers']?.toString(),
      country: meta['country']?.toString(),
      language: meta['language']?.toString(),
      releasedDate: meta['released_date']?.toString(),
      boxOffice: meta['box_office']?.toString(),
      releaseYear: meta['release_year']?.toString(),
      runtime: runtime,
      seasons: seasons,
      tagline: meta['tagline']?.toString(),
      overview: meta['overview']?.toString() ?? fallbackOverview,
      streamingPlatform: meta['streaming_platform']?.toString(),
      streamingDeepLink: meta['streaming_deep_link']?.toString(),
      imdbId: meta['imdb_id']?.toString(),
      director: meta['director']?.toString(),
      leadCast: leadCast,
      genres: genres,
      isTv: isTv,
      formatLabel: isTv ? 'TV Series' : 'Movie',
      durationOrSeasons: isTv ? seasons : runtime,
      providerLogoUrl: meta['provider_logo_url']?.toString() ?? meta['streaming_icon']?.toString(),
      watchProviders: watchProviders,
      resolutionAudit: audit is Map<String, dynamic> ? audit : null,
    );
  }
}
