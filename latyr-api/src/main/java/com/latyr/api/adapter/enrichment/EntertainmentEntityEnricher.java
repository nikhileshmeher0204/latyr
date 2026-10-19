package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.domain.enums.StreamingPlatform;
import com.latyr.api.domain.enums.WatchProviderCategory;
import com.latyr.api.integration.OmdbClient;
import com.latyr.api.integration.TmdbClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Production-grade Entertainment Entity Enricher for Movies & TV Series.
 * Implements Multi-Signal Disambiguation, fetches authentic high-res CDN posters from TMDB,
 * and enriches real IMDb scores, Rotten Tomatoes, and critical metadata via OMDb.
 */
@Component
@Order(10)
public class EntertainmentEntityEnricher implements EntityEnricher {

    private static final Logger log = LoggerFactory.getLogger(EntertainmentEntityEnricher.class);

    private static final String TMDB_POSTER_BASE_W500 = "https://image.tmdb.org/t/p/w500";
    private static final String TMDB_BACKDROP_BASE_W780 = "https://image.tmdb.org/t/p/w780";
    private static final String TMDB_LOGO_BASE_W92 = "https://image.tmdb.org/t/p/w92";
    private static final String FALLBACK_POSTER = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80";

    private static final Pattern CLEAN_TITLE_PATTERN = Pattern.compile(
            "^(?:top\\s+\\d+[:\\s-]*|\\d+[.)\\s-]+|\"|'|#\\S+\\s*)*(.*?)(?:[\"']|\\s*\\(\\d{4}\\)|\\s*-\\s*(?:movie|film|series|tv show))*$",
            Pattern.CASE_INSENSITIVE
    );

    private final TmdbClient tmdbClient;
    private final OmdbClient omdbClient;
    private final StreamingBrandCatalog brandCatalog;

    @Autowired
    public EntertainmentEntityEnricher(
            TmdbClient tmdbClient,
            OmdbClient omdbClient,
            StreamingBrandCatalog brandCatalog
    ) {
        this.tmdbClient = tmdbClient;
        this.omdbClient = omdbClient;
        this.brandCatalog = brandCatalog != null
            ? brandCatalog
            : new StreamingBrandCatalog(new com.latyr.api.adapter.storage.CdnAssetStorageProvider(null));
    }

    public EntertainmentEntityEnricher(TmdbClient tmdbClient, OmdbClient omdbClient) {
        this(tmdbClient, omdbClient, null);
    }

    public EntertainmentEntityEnricher(TmdbClient tmdbClient) {
        this(tmdbClient, null, null);
    }

    @Override
    public boolean supports(EntityType entityType) {
        return entityType == EntityType.MOVIE || entityType == EntityType.TV_SHOW;
    }

    @Override
    public AIProvider.AIEntity enrich(AIProvider.AIEntity rawEntity) {
        if (!tmdbClient.isConfigured()) {
            log.debug("TMDB client is not configured with an API key. Skipping external enrichment.");
            return applyFallbackIfMissing(rawEntity);
        }

        String rawTitle = rawEntity.title();
        String cleanTitle = sanitizeTitle(rawTitle);
        Map<String, Object> rawMeta = rawEntity.metadata() != null ? rawEntity.metadata() : Map.of();

        Integer yearHint = extractYearHint(rawMeta, rawTitle);
        String mediaTypeHint = extractMediaTypeHint(rawEntity, rawMeta);
        String languageHint = extractStringHint(rawMeta, "original_language", "language");
        String directorHint = extractStringHint(rawMeta, "director");
        List<String> castHints = extractListHint(rawMeta, "lead_cast", "cast");

        try {
            // Step 1: Targeted candidate search
            List<TmdbClient.TmdbItem> candidates = queryCandidates(cleanTitle, yearHint, mediaTypeHint);

            if (candidates.isEmpty() && !cleanTitle.equalsIgnoreCase(rawTitle)) {
                // Secondary attempt with raw title if sanitized title returned nothing
                candidates = queryCandidates(rawTitle.trim(), yearHint, mediaTypeHint);
            }

            if (candidates.isEmpty()) {
                log.info("No TMDB candidates found for '{}' (hints: year={}, type={})", cleanTitle, yearHint, mediaTypeHint);
                return applyFallbackIfMissing(rawEntity);
            }

            // Step 2: Multi-Signal Candidate Scoring & Disambiguation
            TmdbClient.TmdbItem bestMatch = scoreAndSelectBestCandidate(
                    candidates, cleanTitle, yearHint, mediaTypeHint, languageHint, directorHint, castHints
            );

            if (bestMatch == null) {
                log.info("TMDB candidates for '{}' did not meet the confidence threshold.", cleanTitle);
                return applyFallbackIfMissing(rawEntity);
            }

            // Step 3: Fetch full details (runtime, IMDb ID, seasons/episodes)
            return buildEnrichedEntity(rawEntity, bestMatch, rawMeta);

        } catch (Exception e) {
            log.warn("Error during TMDB enrichment for '{}': {}. Falling back safely.", cleanTitle, e.getMessage());
            return applyFallbackIfMissing(rawEntity);
        }
    }

    private List<TmdbClient.TmdbItem> queryCandidates(String title, Integer year, String mediaTypeHint) {
        if ("tv".equalsIgnoreCase(mediaTypeHint)) {
            List<TmdbClient.TmdbItem> results = tmdbClient.searchTv(title, year);
            if (!results.isEmpty()) return results;
        } else if ("movie".equalsIgnoreCase(mediaTypeHint)) {
            List<TmdbClient.TmdbItem> results = tmdbClient.searchMovies(title, year);
            if (!results.isEmpty()) return results;
        }

        // Fallback to general multi-search
        return tmdbClient.searchMulti(title);
    }

    private TmdbClient.TmdbItem scoreAndSelectBestCandidate(
            List<TmdbClient.TmdbItem> candidates,
            String targetTitle,
            Integer targetYear,
            String targetMediaType,
            String targetLanguage,
            String directorHint,
            List<String> castHints) {

        TmdbClient.TmdbItem bestCandidate = null;
        int highestScore = -1;

        String lowerTarget = targetTitle.toLowerCase(Locale.ROOT).trim();

        for (TmdbClient.TmdbItem item : candidates) {
            int score = 0;
            String itemTitle = item.getDisplayTitle().toLowerCase(Locale.ROOT).trim();
            String originalTitle = item.originalTitle != null ? item.originalTitle.toLowerCase(Locale.ROOT).trim() : "";

            // 1. Title Exactness (+35 / +20)
            if (itemTitle.equals(lowerTarget) || originalTitle.equals(lowerTarget)) {
                score += 35;
            } else if (itemTitle.contains(lowerTarget) || lowerTarget.contains(itemTitle)) {
                score += 20;
            }

            // 2. Format Match (+20)
            if (targetMediaType != null && targetMediaType.equalsIgnoreCase(item.mediaType)) {
                score += 20;
            }

            // 3. Year Proximity (+20 for exact, +10 for +-1 yr, +5 for +-3 yrs)
            Integer itemYear = parseYear(item.getDisplayDate());
            if (targetYear != null && itemYear != null) {
                int diff = Math.abs(targetYear - itemYear);
                if (diff == 0) {
                    score += 20;
                } else if (diff <= 1) {
                    score += 12;
                } else if (diff <= 3) {
                    score += 5;
                }
            }

            // 4. Language Match (+15)
            if (targetLanguage != null && targetLanguage.equalsIgnoreCase(item.originalLanguage)) {
                score += 15;
            }

            // 5. Popularity & Vote Count Weight (Weed out student films / obscure shorts)
            if (item.voteCount > 1000) {
                score += 10;
            } else if (item.voteCount > 50) {
                score += 5;
            } else if (item.voteCount == 0 && item.popularity < 1.0) {
                score -= 15; // penalty for empty unrated noise
            }

            if (score > highestScore) {
                highestScore = score;
                bestCandidate = item;
            }
        }

        // Accept if score meets confidence threshold (>= 45)
        return (highestScore >= 45) ? bestCandidate : null;
    }

    private AIProvider.AIEntity buildEnrichedEntity(
            AIProvider.AIEntity raw,
            TmdbClient.TmdbItem match,
            Map<String, Object> rawMeta) {

        Map<String, Object> enrichedMeta = new HashMap<>(rawMeta);
        String mediaType = match.mediaType != null ? match.mediaType.toLowerCase(Locale.ROOT) : "movie";
        EntityType entityType = "tv".equals(mediaType) ? EntityType.TV_SHOW : EntityType.MOVIE;

        String posterUrl = match.posterPath != null ? TMDB_POSTER_BASE_W500 + match.posterPath : null;
        String backdropUrl = match.backdropPath != null ? TMDB_BACKDROP_BASE_W780 + match.backdropPath : null;

        enrichedMeta.put("tmdb_id", match.id);
        enrichedMeta.put("media_type", mediaType);
        enrichedMeta.put("title", match.getDisplayTitle());
        enrichedMeta.put("overview", match.overview != null ? match.overview : raw.description());

        if (posterUrl != null) enrichedMeta.put("poster_url", posterUrl);
        if (backdropUrl != null) enrichedMeta.put("backdrop_url", backdropUrl);

        double rating = Math.round(match.voteAverage * 10.0) / 10.0;
        enrichedMeta.put("rating", rating);
        enrichedMeta.put("vote_count", match.voteCount);

        Integer releaseYear = parseYear(match.getDisplayDate());
        if (releaseYear != null) {
            enrichedMeta.put("release_year", String.valueOf(releaseYear));
        }

        // Compliant Rating Source Attribution
        enrichedMeta.put("rating_source", "TMDB");

        // Preserve / populate overview from TMDB
        if (match.overview != null && !match.overview.isBlank() && !enrichedMeta.containsKey("overview")) {
            enrichedMeta.put("overview", match.overview);
        }

        String externalUrl = raw.externalUrl();

        if ("movie".equals(mediaType)) {
            Optional<TmdbClient.TmdbMovieDetails> detailsOpt = tmdbClient.getMovieDetails(match.id);
            if (detailsOpt.isPresent()) {
                TmdbClient.TmdbMovieDetails details = detailsOpt.get();
                if (details.runtime != null && details.runtime > 0) {
                    enrichedMeta.put("runtime_minutes", details.runtime);
                    enrichedMeta.put("runtime_formatted", formatRuntime(details.runtime));
                }
                if (details.tagline != null && !details.tagline.isBlank()) {
                    enrichedMeta.put("tagline", details.tagline);
                }
                if (details.overview != null && !details.overview.isBlank()) {
                    enrichedMeta.put("overview", details.overview);
                }
                if (details.externalIds != null && details.externalIds.imdbId != null) {
                    enrichedMeta.put("imdb_id", details.externalIds.imdbId);
                    if (externalUrl == null || externalUrl.isBlank()) {
                        externalUrl = "https://www.imdb.com/title/" + details.externalIds.imdbId + "/";
                    }
                }
                if (details.genres != null && !details.genres.isEmpty()) {
                    enrichedMeta.put("genres", details.genres.stream().map(g -> g.name).toList());
                }
                if (details.credits != null) {
                    if (details.credits.crew != null) {
                        details.credits.crew.stream()
                                .filter(c -> "Director".equalsIgnoreCase(c.job))
                                .map(c -> c.name)
                                .findFirst()
                                .ifPresent(dir -> enrichedMeta.put("director", dir));
                    }
                    if (details.credits.cast != null && !details.credits.cast.isEmpty()) {
                        List<String> cast = details.credits.cast.stream()
                                .map(c -> c.name)
                                .limit(5)
                                .toList();
                        enrichedMeta.put("lead_cast", cast);
                    }
                }
                if (details.watchProviders != null && details.watchProviders.results != null) {
                    attachWatchProviders(enrichedMeta, details.watchProviders.results);
                }
            }
        } else {
            Optional<TmdbClient.TmdbTvDetails> tvDetailsOpt = tmdbClient.getTvDetails(match.id);
            if (tvDetailsOpt.isPresent()) {
                TmdbClient.TmdbTvDetails tvDetails = tvDetailsOpt.get();
                if (tvDetails.numberOfSeasons != null) {
                    enrichedMeta.put("total_seasons", tvDetails.numberOfSeasons);
                }
                if (tvDetails.numberOfEpisodes != null) {
                    enrichedMeta.put("total_episodes", tvDetails.numberOfEpisodes);
                }
                enrichedMeta.put("seasons_formatted", formatSeasons(tvDetails.numberOfSeasons, tvDetails.numberOfEpisodes));
                if (tvDetails.status != null) {
                    enrichedMeta.put("status", tvDetails.status);
                }
                if (tvDetails.tagline != null && !tvDetails.tagline.isBlank()) {
                    enrichedMeta.put("tagline", tvDetails.tagline);
                }
                if (tvDetails.overview != null && !tvDetails.overview.isBlank()) {
                    enrichedMeta.put("overview", tvDetails.overview);
                }
                if (tvDetails.externalIds != null && tvDetails.externalIds.imdbId != null) {
                    enrichedMeta.put("imdb_id", tvDetails.externalIds.imdbId);
                    if (externalUrl == null || externalUrl.isBlank()) {
                        externalUrl = "https://www.imdb.com/title/" + tvDetails.externalIds.imdbId + "/";
                    }
                }
                if (tvDetails.genres != null && !tvDetails.genres.isEmpty()) {
                    enrichedMeta.put("genres", tvDetails.genres.stream().map(g -> g.name).toList());
                }
                if (tvDetails.networks != null && !tvDetails.networks.isEmpty()) {
                    enrichedMeta.put("networks", tvDetails.networks.stream().map(n -> n.name).toList());
                }
                if (tvDetails.credits != null && tvDetails.credits.cast != null && !tvDetails.credits.cast.isEmpty()) {
                    List<String> cast = tvDetails.credits.cast.stream()
                            .map(c -> c.name)
                            .limit(5)
                            .toList();
                    enrichedMeta.put("lead_cast", cast);
                }
                if (tvDetails.watchProviders != null && tvDetails.watchProviders.results != null) {
                    attachWatchProviders(enrichedMeta, tvDetails.watchProviders.results);
                }
            }
        }

        // Step 3b: Enrich with authentic IMDb ratings, Rotten Tomatoes, and deep metadata from OMDb
        Object imdbIdObj = enrichedMeta.get("imdb_id");
        if (imdbIdObj != null && !imdbIdObj.toString().isBlank()) {
            enrichFromOmdb(enrichedMeta, imdbIdObj.toString());
        } else {
            enrichFromOmdbByTitle(enrichedMeta, match.getDisplayTitle(), releaseYear);
        }

        if (enrichedMeta.containsKey("imdb_id") && enrichedMeta.get("imdb_id") != null) {
            String resolvedImdbId = enrichedMeta.get("imdb_id").toString();
            if (externalUrl == null || externalUrl.isBlank() || externalUrl.contains("themoviedb.org")) {
                externalUrl = "https://www.imdb.com/title/" + resolvedImdbId + "/";
            }
        }

        // Resolve Streaming Platform and create deep search link
        String platformHint = extractStringHint(rawMeta, "streaming_platform", "platform", "provider");
        if (enrichedMeta.containsKey("streaming_platform") && enrichedMeta.get("streaming_platform") != null) {
            platformHint = enrichedMeta.get("streaming_platform").toString();
        }
        StreamingPlatform platform = StreamingPlatform.parse(platformHint);
        enrichedMeta.put("streaming_platform", platform.getDisplayName());
        enrichedMeta.put("streaming_color", platform.getBrandColorHex());
        if (!enrichedMeta.containsKey("provider_logo_url") && platform.getIconUrl() != null) {
            enrichedMeta.put("streaming_icon", platform.getIconUrl());
        }
        enrichedMeta.put("streaming_deep_link", platform.generateSearchUrl(match.getDisplayTitle()));

        if (externalUrl == null || externalUrl.isBlank()) {
            externalUrl = "https://www.themoviedb.org/" + mediaType + "/" + match.id;
        }

        // Ensure poster_url fallback if TMDB had no poster path
        if (!enrichedMeta.containsKey("poster_url") || enrichedMeta.get("poster_url") == null) {
            enrichedMeta.put("poster_url", FALLBACK_POSTER);
        }

        return new AIProvider.AIEntity(
                entityType,
                match.getDisplayTitle(),
                raw.description(),
                externalUrl,
                ActionCTA.WATCH,
                enrichedMeta
        );
    }

    private AIProvider.AIEntity applyFallbackIfMissing(AIProvider.AIEntity raw) {
        Map<String, Object> meta = new HashMap<>(raw.metadata() != null ? raw.metadata() : Map.of());
        if (!meta.containsKey("poster_url") || meta.get("poster_url") == null) {
            meta.put("poster_url", FALLBACK_POSTER);
        }
        return new AIProvider.AIEntity(
                raw.entityType(),
                raw.title(),
                raw.description(),
                raw.externalUrl(),
                raw.actionCta() != null ? raw.actionCta() : ActionCTA.WATCH,
                meta
        );
    }

    private String sanitizeTitle(String raw) {
        if (raw == null) return "";
        Matcher matcher = CLEAN_TITLE_PATTERN.matcher(raw.trim());
        if (matcher.find() && matcher.group(1) != null && !matcher.group(1).isBlank()) {
            return matcher.group(1).trim();
        }
        return raw.replaceAll("[\"']", "").trim();
    }

    private Integer extractYearHint(Map<String, Object> meta, String rawTitle) {
        if (meta.containsKey("release_year") && meta.get("release_year") != null) {
            try {
                return Integer.parseInt(meta.get("release_year").toString().trim());
            } catch (Exception ignored) {}
        }
        Pattern yearPattern = Pattern.compile("\\b(19\\d{2}|20\\d{2})\\b");
        Matcher m = yearPattern.matcher(rawTitle);
        if (m.find()) {
            try {
                return Integer.parseInt(m.group(1));
            } catch (Exception ignored) {}
        }
        return null;
    }

    private String extractMediaTypeHint(AIProvider.AIEntity entity, Map<String, Object> meta) {
        if (entity.entityType() == EntityType.TV_SHOW) return "tv";
        if (entity.entityType() == EntityType.MOVIE) return "movie";
        if (meta.containsKey("media_type") && meta.get("media_type") != null) {
            String val = meta.get("media_type").toString().toLowerCase(Locale.ROOT);
            if (val.contains("tv") || val.contains("series") || val.contains("show")) return "tv";
            if (val.contains("movie") || val.contains("film")) return "movie";
        }
        return null;
    }

    private String extractStringHint(Map<String, Object> meta, String... keys) {
        for (String k : keys) {
            if (meta.containsKey(k) && meta.get(k) != null) {
                String val = meta.get(k).toString().trim();
                if (!val.isBlank()) return val;
            }
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    private List<String> extractListHint(Map<String, Object> meta, String... keys) {
        for (String k : keys) {
            if (meta.containsKey(k) && meta.get(k) instanceof List<?> list) {
                return list.stream().map(Object::toString).toList();
            }
        }
        return Collections.emptyList();
    }

    private Integer parseYear(String dateStr) {
        if (dateStr == null || dateStr.length() < 4) return null;
        try {
            return Integer.parseInt(dateStr.substring(0, 4));
        } catch (Exception e) {
            return null;
        }
    }

    private String formatRuntime(int minutes) {
        int hours = minutes / 60;
        int mins = minutes % 60;
        if (hours > 0 && mins > 0) return hours + "h " + mins + "m";
        if (hours > 0) return hours + "h";
        return mins + "m";
    }

    private String formatSeasons(Integer seasons, Integer episodes) {
        if (seasons == null || seasons <= 0) return "Series";
        String sLabel = seasons == 1 ? "1 Season" : seasons + " Seasons";
        if (episodes != null && episodes > 0) {
            return sLabel + " (" + episodes + " Ep)";
        }
        return sLabel;
    }

    private void enrichFromOmdb(Map<String, Object> enrichedMeta, String imdbId) {
        if (omdbClient == null || !omdbClient.isConfigured() || imdbId == null || imdbId.isBlank()) return;

        try {
            Optional<OmdbClient.OmdbMovieResponse> omdbOpt = omdbClient.getByImdbId(imdbId);
            if (omdbOpt.isPresent()) {
                applyOmdbMetadata(enrichedMeta, omdbOpt.get());
            }
        } catch (Exception e) {
            log.warn("OMDb enrichment by IMDb ID '{}' failed: {}", imdbId, e.getMessage());
        }
    }

    private void enrichFromOmdbByTitle(Map<String, Object> enrichedMeta, String title, Integer year) {
        if (omdbClient == null || !omdbClient.isConfigured() || title == null || title.isBlank()) return;

        try {
            Optional<OmdbClient.OmdbMovieResponse> omdbOpt = omdbClient.getByTitle(title, year);
            if (omdbOpt.isPresent()) {
                applyOmdbMetadata(enrichedMeta, omdbOpt.get());
            }
        } catch (Exception e) {
            log.warn("OMDb enrichment by title '{}' failed: {}", title, e.getMessage());
        }
    }

    private void applyOmdbMetadata(Map<String, Object> enrichedMeta, OmdbClient.OmdbMovieResponse omdb) {
        // 1. Authentic IMDb User Rating & Votes
        Double imdbRating = omdb.getParsedImdbRating();
        if (imdbRating != null) {
            enrichedMeta.put("rating", imdbRating);
            enrichedMeta.put("rating_source", "IMDb");
        }
        if (omdb.hasValue(omdb.imdbVotes)) {
            enrichedMeta.put("imdb_votes", omdb.imdbVotes.trim());
        }

        // 2. Critic Ratings (Rotten Tomatoes & Metacritic)
        String rt = omdb.getRottenTomatoesRating();
        if (rt != null) {
            enrichedMeta.put("rotten_tomatoes_rating", rt);
        }
        String mc = omdb.getMetacriticRating();
        if (mc != null) {
            enrichedMeta.put("metascore_rating", mc);
        }

        // 3. Content Maturity Rating (e.g. TV-MA, R, PG-13)
        if (omdb.hasValue(omdb.rated)) {
            enrichedMeta.put("content_rating", omdb.rated.trim());
        }

        // 4. Awards & Accolades
        if (omdb.hasValue(omdb.awards)) {
            enrichedMeta.put("awards", omdb.awards.trim());
        }

        // 5. Director & Writers
        if (omdb.hasValue(omdb.director)) {
            enrichedMeta.put("director", omdb.director.trim());
        }
        if (omdb.hasValue(omdb.writer)) {
            enrichedMeta.put("writers", omdb.writer.trim());
        }

        // 6. Lead Cast
        List<String> omdbActors = omdb.getActorList();
        if (!omdbActors.isEmpty()) {
            enrichedMeta.put("lead_cast", omdbActors);
        }

        // 7. Box Office
        if (omdb.hasValue(omdb.boxOffice)) {
            enrichedMeta.put("box_office", omdb.boxOffice.trim());
        }

        // 8. Country, Language & Release Date
        if (omdb.hasValue(omdb.country)) {
            enrichedMeta.put("country", omdb.country.trim());
        }
        if (omdb.hasValue(omdb.language)) {
            enrichedMeta.put("language", omdb.language.trim());
        }
        if (omdb.hasValue(omdb.released)) {
            enrichedMeta.put("released_date", omdb.released.trim());
        }

        // 9. Preserve IMDb ID if not already present
        if (omdb.hasValue(omdb.imdbId) && !enrichedMeta.containsKey("imdb_id")) {
            enrichedMeta.put("imdb_id", omdb.imdbId.trim());
        }
    }

    private void attachWatchProviders(Map<String, Object> enrichedMeta, Map<String, TmdbClient.TmdbCountryWatchProviders> results) {
        if (results == null || results.isEmpty()) return;

        // Preference: IN (India) -> US -> First available country with watch providers
        TmdbClient.TmdbCountryWatchProviders country = results.get("IN");
        if (!hasAnyWatchProviders(country)) {
            country = results.get("US");
        }
        if (!hasAnyWatchProviders(country)) {
            for (TmdbClient.TmdbCountryWatchProviders c : results.values()) {
                if (hasAnyWatchProviders(c)) {
                    country = c;
                    break;
                }
            }
        }

        if (country == null) return;

        if (country.link != null) {
            enrichedMeta.put("watch_link", country.link);
        }

        String mediaTitle = enrichedMeta.get("title") != null ? enrichedMeta.get("title").toString() : "";
        List<Map<String, Object>> providersList = new ArrayList<>();

        // 1. Subscription (Flatrate / SVOD)
        appendProvidersForCategory(providersList, country.flatrate, WatchProviderCategory.FLATRATE, mediaTitle);

        // 2. Rent (TVOD)
        appendProvidersForCategory(providersList, country.rent, WatchProviderCategory.RENT, mediaTitle);

        // 3. Buy (EST)
        appendProvidersForCategory(providersList, country.buy, WatchProviderCategory.BUY, mediaTitle);

        // 4. Free & Ad-supported (AVOD)
        List<TmdbClient.TmdbProviderInfo> freeAndAds = new ArrayList<>();
        if (country.free != null) freeAndAds.addAll(country.free);
        if (country.ads != null) freeAndAds.addAll(country.ads);
        appendProvidersForCategory(providersList, freeAndAds, WatchProviderCategory.FREE, mediaTitle);

        if (!providersList.isEmpty()) {
            Map<String, Object> top = providersList.get(0);
            enrichedMeta.put("streaming_platform", top.get("provider_name"));
            if (top.containsKey("brand_color")) {
                enrichedMeta.put("streaming_brand_color", top.get("brand_color"));
            }
            if (top.containsKey("tile_color")) {
                enrichedMeta.put("streaming_tile_color", top.get("tile_color"));
            }
            if (top.containsKey("watch_url")) {
                enrichedMeta.put("watch_url", top.get("watch_url"));
                enrichedMeta.put("streaming_deep_link", top.get("watch_url"));
            }
            if (top.containsKey("logo_url")) {
                enrichedMeta.put("provider_logo_url", top.get("logo_url"));
                enrichedMeta.put("streaming_icon", top.get("logo_url"));
            }
            enrichedMeta.put("watch_providers", providersList);
        }
    }

    private void appendProvidersForCategory(
            List<Map<String, Object>> targetList,
            List<TmdbClient.TmdbProviderInfo> rawProviders,
            WatchProviderCategory category,
            String mediaTitle) {
        if (rawProviders == null || rawProviders.isEmpty()) return;

        Set<String> seenInCat = new HashSet<>();
        for (TmdbClient.TmdbProviderInfo p : rawProviders) {
            if (p.providerName != null && seenInCat.add(p.providerName.toLowerCase(Locale.ROOT))) {
                Map<String, Object> pMap = new HashMap<>();
                pMap.put("provider_id", p.providerId);
                pMap.put("provider_name", p.providerName);
                pMap.put("type", category.getCode()); // "subscription", "rent", "buy", "free"
                pMap.put("category", category.name()); // "FLATRATE", "RENT", "BUY", "FREE"
                pMap.put("category_display", category.getDisplayName()); // "Subscription", "Rent", "Buy", "Free"
                if (p.logoPath != null) {
                    pMap.put("logo_url", TMDB_LOGO_BASE_W92 + p.logoPath);
                }
                StreamingBrandCatalog.BrandMetadata brandMeta = brandCatalog.resolve(p.providerId, p.providerName);
                pMap.put("brand_color", brandMeta.brandColor());
                pMap.put("tile_color", brandMeta.tileColor());
                if (brandMeta.svgAsset() != null) {
                    pMap.put("svg_asset", brandMeta.svgAsset());
                }
                if (brandMeta.svgUrl() != null) {
                    pMap.put("svg_url", brandMeta.svgUrl());
                }
                String watchUrl = brandCatalog.buildWatchUrl(brandMeta, mediaTitle);
                if (watchUrl != null) {
                    pMap.put("watch_url", watchUrl);
                }
                targetList.add(pMap);
            }
        }
    }

    private boolean hasAnyWatchProviders(TmdbClient.TmdbCountryWatchProviders c) {
        return c != null && (!isEmpty(c.flatrate) || !isEmpty(c.rent) || !isEmpty(c.buy) || !isEmpty(c.free) || !isEmpty(c.ads));
    }

    private boolean isEmpty(List<?> list) {
        return list == null || list.isEmpty();
    }
}

