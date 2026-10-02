package com.latyr.api.util;

import java.util.regex.Pattern;

/**
 * Utility for stripping semantic markup tags from editorial summaries
 * for search indexing, embeddings, and notification copies.
 */
public final class MarkupSanitizer {

    private static final Pattern MARKDOWN_LINK_PATTERN = Pattern.compile("\\[([^\\]]+)\\]\\([^)]+\\)");
    private static final Pattern ICON_PATTERN = Pattern.compile("\\[icon:[a-zA-Z0-9_-]+\\]");
    private static final Pattern HIGHLIGHT_PATTERN = Pattern.compile("==([^=]+)==");
    private static final Pattern WAVY_PATTERN = Pattern.compile("~([^~]+)~");
    private static final Pattern ITALIC_PATTERN = Pattern.compile("\\*([^\\*]+)\\*");
    private static final Pattern MULTI_SPACE_PATTERN = Pattern.compile(" {2,}");

    private MarkupSanitizer() {}

    /**
     * Strips all Latyr semantic formatting tags and returns clean plain text.
     *
     * @param text Raw summary string containing markup tags
     * @return Clean text free of markup delimiters and inline icon tokens
     */
    public static String stripMarkup(String text) {
        if (text == null || text.isBlank()) {
            return "";
        }
        String result = MARKDOWN_LINK_PATTERN.matcher(text).replaceAll("$1");
        result = ICON_PATTERN.matcher(result).replaceAll("");
        result = HIGHLIGHT_PATTERN.matcher(result).replaceAll("$1");
        result = WAVY_PATTERN.matcher(result).replaceAll("$1");
        result = ITALIC_PATTERN.matcher(result).replaceAll("$1");
        result = MULTI_SPACE_PATTERN.matcher(result).replaceAll(" ");
        return result.trim();
    }
}
