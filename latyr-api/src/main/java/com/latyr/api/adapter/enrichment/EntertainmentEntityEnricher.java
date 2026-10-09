package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.domain.enums.ActionCTA;
import com.latyr.api.domain.enums.EntityType;
import com.latyr.api.integration.TmdbClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Production-grade Entertainment Entity Enricher for Movies & TV Series.
 * Implements Multi-Signal Disambiguation and fetches authentic high-res CDN posters from TMDB.
 */
@Component
@Order(10)
public class EntertainmentEntityEnricher implements EntityEnricher {

    private static final Logger log = LoggerFactory.getLogger(EntertainmentEntityEnricher.class);

    private static final String TMDB_POSTER_BASE_W500 = "https://image.tmdb.org/t/p/w500";
    private static final String TMDB_BACKDROP_BASE_W780 = "https://image.tmdb.org/t/p/w780";
    private static final String FALLBACK_POSTER = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80";

    private static final Pattern CLEAN_TITLE_PATTERN = Pattern.compile(
            "^(?:top\\s+\\d+[:\\s-]*|\\d+[.)\\s-]+|\"|'|#\\S+\\s*)*(.*?)(?:[\"']|\\s*\\(\\d{4}\\)|\\s*-\\s*(?:movie|film|series|tv show))*$",
            Pattern.CASE_INSENSITIVE
    );

    private final TmdbClient tmdbClient;

    public EntertainmentEntityEnricher(TmdbClient tmdbClient) {
        this.tmdbClient = tmdbClient;
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
                if (details.externalIds != null && details.externalIds.imdbId != null) {
                    enrichedMeta.put("imdb_id", details.externalIds.imdbId);
                    if (externalUrl == null || externalUrl.isBlank()) {
                        externalUrl = "https://www.imdb.com/title/" + details.externalIds.imdbId + "/";
                    }
                }
                if (details.genres != null && !details.genres.isEmpty()) {
                    enrichedMeta.put("genres", details.genres.stream().map(g -> g.name).toList());
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
            }
        }

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
}
