package com.latyr.api.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class MarkupSanitizerTest {

    @Test
    @DisplayName("stripMarkup should clean highlights, wavy underlines, italics, icons, and smart links")
    void testStripMarkupComprehensive() {
        String input = "This is ==blazing fast== [icon:runner] but ~requires Docker~. Check *The Pragmatic Programmer* or [FLOCI Repo](github:FLOCI).";
        String expected = "This is blazing fast but requires Docker. Check The Pragmatic Programmer or FLOCI Repo.";

        assertEquals(expected, MarkupSanitizer.stripMarkup(input));
    }

    @Test
    @DisplayName("stripMarkup should handle null and empty input gracefully")
    void testStripMarkupEmpty() {
        assertEquals("", MarkupSanitizer.stripMarkup(null));
        assertEquals("", MarkupSanitizer.stripMarkup("   "));
    }

    @Test
    @DisplayName("stripMarkup should return plain text unchanged")
    void testStripMarkupPlain() {
        String input = "Just standard plain text without any formatting.";
        assertEquals(input, MarkupSanitizer.stripMarkup(input));
    }
}
