package com.latyr.api.service;

import java.util.*;

/**
 * Deterministic normalization engine for Latyr capture taxonomy.
 * Converts variable, free-form AI sub-category outputs into standardized,
 * predictable sub-categories, preserving granular creator keywords into tags.
 */
public final class TaxonomyNormalizer {

    private TaxonomyNormalizer() {}

    public static String normalizeSubCategory(String category, String rawSubCategory) {
        if (rawSubCategory == null || rawSubCategory.isBlank()) {
            return category != null && !category.isBlank() ? capitalize(category.trim()) : "General";
        }

        String rawLower = rawSubCategory.toLowerCase(Locale.ROOT).trim();
        String catLower = category != null ? category.toLowerCase(Locale.ROOT).trim() : "";

        if (catLower.contains("entertainment")) {
            if (rawLower.contains("series") || rawLower.contains("show") || rawLower.contains("tv")) {
                return "TV Series";
            }
            if (rawLower.contains("documentar")) {
                return "Documentaries";
            }
            return "Movies";
        }

        if (catLower.contains("tech")) {
            if (rawLower.contains("ai") || rawLower.contains("llm") || rawLower.contains("agent")) {
                return "AI Tools";
            }
            if (rawLower.contains("developer") || rawLower.contains("github") || rawLower.contains("software") || rawLower.contains("code") || rawLower.contains("open source")) {
                return "Developer Tools";
            }
            if (rawLower.contains("cyber") || rawLower.contains("security")) {
                return "Cybersecurity";
            }
            if (rawLower.contains("cloud") || rawLower.contains("devops") || rawLower.contains("system design") || rawLower.contains("infrastructure")) {
                return "Cloud Architecture";
            }
            if (rawLower.contains("data") || rawLower.contains("analytics") || rawLower.contains("sql") || rawLower.contains("python")) {
                return "Data & Analytics";
            }
            return "Developer Tools";
        }

        if (catLower.contains("learning")) {
            if (rawLower.contains("interview") || rawLower.contains("job") || rawLower.contains("career") || rawLower.contains("resume") || rawLower.contains("remote")) {
                return "Career & Interviews";
            }
            if (rawLower.contains("cert")) {
                return "Certifications";
            }
            if (rawLower.contains("business") || rawLower.contains("entrepreneur") || rawLower.contains("marketing") || rawLower.contains("strategy")) {
                return "Business Strategy";
            }
            return "Career & Interviews";
        }

        if (catLower.contains("food")) {
            if (rawLower.contains("recipe") || rawLower.contains("cook") || rawLower.contains("dish") || rawLower.contains("food") || rawLower.contains("shawarma")) {
                return "Recipes";
            }
            if (rawLower.contains("restaurant") || rawLower.contains("dining") || rawLower.contains("cafe")) {
                return "Restaurants";
            }
            return "Recipes";
        }

        if (catLower.contains("lifestyle")) {
            if (rawLower.contains("network")) {
                return "Networking";
            }
            return capitalize(rawSubCategory.trim());
        }

        return capitalize(rawSubCategory.trim());
    }

    public static List<String> extractTags(String category, String rawSubCategory, List<String> providedTags) {
        Set<String> tagSet = new LinkedHashSet<>();

        if (providedTags != null) {
            for (String tag : providedTags) {
                if (tag != null && !tag.isBlank()) {
                    tagSet.add(capitalize(tag.trim()));
                }
            }
        }

        // Parse comma/pipe-separated tokens in rawSubCategory to extract keywords as tags
        if (rawSubCategory != null && (rawSubCategory.contains(",") || rawSubCategory.contains("|"))) {
            String[] tokens = rawSubCategory.split("[,|]");
            for (String token : tokens) {
                String clean = token.trim();
                if (!clean.isEmpty() && clean.length() < 35) {
                    tagSet.add(capitalize(clean));
                }
            }
        }

        if (tagSet.isEmpty()) {
            if (rawSubCategory != null && !rawSubCategory.isBlank()) {
                tagSet.add(capitalize(rawSubCategory.trim()));
            } else if (category != null && !category.isBlank()) {
                tagSet.add(capitalize(category.trim()));
            }
        }

        return new ArrayList<>(tagSet);
    }

    private static String capitalize(String text) {
        if (text == null || text.isBlank()) return text;
        if (text.length() == 1) return text.toUpperCase(Locale.ROOT);
        return Character.toUpperCase(text.charAt(0)) + text.substring(1);
    }
}
