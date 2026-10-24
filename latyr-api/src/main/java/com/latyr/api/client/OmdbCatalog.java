package com.latyr.api.client;

import java.util.*;

/** Immutable catalogue contract; vendor JSON stays inside its integration adapter. */
public interface OmdbCatalog {
    boolean isConfigured();
    Optional<OmdbMovieResponse> getByImdbId(String id);
    Optional<OmdbMovieResponse> getByTitle(String title, Integer year);

    record OmdbMovieResponse(
            String title,
            String year,
            String rated,
            String released,
            String runtime,
            String genre,
            String director,
            String writer,
            String actors,
            String plot,
            String language,
            String country,
            String awards,
            String poster,
            List<OmdbRating> ratings,
            String metascore,
            String imdbRating,
            String imdbVotes,
            String imdbId,
            String type,
            String boxOffice
    ) {
        public OmdbMovieResponse {
            ratings = ratings == null ? List.of() : List.copyOf(ratings);
        }

        public boolean hasValue(String val) {
            return val != null && !val.isBlank() && !"N/A".equalsIgnoreCase(val.trim());
        }

        public Double getParsedImdbRating() {
            if (hasValue(imdbRating)) {
                try {
                    return Double.parseDouble(imdbRating.trim());
                } catch (NumberFormatException ignored) {}
            }
            return null;
        }

        public String getRottenTomatoesRating() {
            if (ratings != null) {
                for (OmdbRating r : ratings) {
                    if ("Rotten Tomatoes".equalsIgnoreCase(r.source)) {
                        return r.value;
                    }
                }
            }
            return null;
        }

        public String getMetacriticRating() {
            if (ratings != null) {
                for (OmdbRating r : ratings) {
                    if ("Metacritic".equalsIgnoreCase(r.source)) {
                        return r.value;
                    }
                }
            }
            if (hasValue(metascore)) {
                return metascore + "/100";
            }
            return null;
        }

        public List<String> getActorList() {
            if (!hasValue(actors)) return Collections.emptyList();
            return Arrays.stream(actors.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        public List<String> getGenreList() {
            if (!hasValue(genre)) return Collections.emptyList();
            return Arrays.stream(genre.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        public List<String> getWriterList() {
            if (!hasValue(writer)) return Collections.emptyList();
            return Arrays.stream(writer.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }
    }

    record OmdbRating(
            String source,
            String value
    ) {
    }
}
