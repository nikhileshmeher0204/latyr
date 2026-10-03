package com.latyr.api.util;

import com.latyr.api.domain.enums.SourceType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

class UrlSourceClassifierTest {

    @ParameterizedTest(name = "{0} -> {1}")
    @CsvSource({
            "https://www.instagram.com/reel/C7Xyz123/?igsh=MWx123, INSTAGRAM_REEL",
            "https://instagram.com/reels/C7Xyz123/, INSTAGRAM_REEL",
            "https://www.instagram.com/p/C7Xyz123/, INSTAGRAM_REEL",
            "https://www.instagram.com/share/reel/C7Xyz123/?igsh=MWx123, INSTAGRAM_REEL",
            "https://instagr.am/p/C7Xyz123/, INSTAGRAM_REEL",
            "https://www.youtube.com/shorts/5vJ0P2K8tZs?si=aB19xK&feature=share, YOUTUBE_SHORT",
            "https://m.youtube.com/shorts/5vJ0P2K8tZs, YOUTUBE_SHORT",
            "https://www.youtube.com/watch?v=5vJ0P2K8tZs&si=abc, YOUTUBE_VIDEO",
            "https://youtu.be/5vJ0P2K8tZs?si=abc, YOUTUBE_VIDEO",
            "https://www.youtube.com/embed/5vJ0P2K8tZs, YOUTUBE_VIDEO",
            "https://techcrunch.com/2026/10/03/startup-mindset/, WEB_URL",
            "https://medium.com/@founder/why-startups-fail-123, WEB_URL",
            "https://news.ycombinator.com/item?id=3912345, WEB_URL"
    })
    @DisplayName("Should classify standard URLs into correct SourceType")
    void testStandardUrlClassification(String url, SourceType expected) {
        assertThat(UrlSourceClassifier.classify(url)).isEqualTo(expected);
    }

    @Test
    @DisplayName("Should extract URL and classify correctly from dirty share sheet commentary")
    void testDirtyShareSheetText() {
        String dirtyInstagram = "Check out this reel! https://www.instagram.com/reel/C7Xyz123/?igsh=MWx123 it's so good.";
        assertThat(UrlSourceClassifier.classify(dirtyInstagram)).isEqualTo(SourceType.INSTAGRAM_REEL);

        String dirtyYoutubeShort = "Watch this short: https://www.youtube.com/shorts/5vJ0P2K8tZs?si=123 (via YouTube)";
        assertThat(UrlSourceClassifier.classify(dirtyYoutubeShort)).isEqualTo(SourceType.YOUTUBE_SHORT);
    }

    @Test
    @DisplayName("Should not be tricked by query parameters containing platform domains")
    void testQueryParamDomainSpoofing() {
        String spoofedUrl = "https://techcrunch.com/article?referrer=youtube.com&category=shorts";
        assertThat(UrlSourceClassifier.classify(spoofedUrl)).isEqualTo(SourceType.WEB_URL);
    }

    @Test
    @DisplayName("Should strip tracking parameters during normalization while preserving functional keys")
    void testUrlNormalization() {
        String dirtyYt = "https://www.youtube.com/watch?v=5vJ0P2K8tZs&si=aB19xK&utm_source=share&feature=share";
        String normalizedYt = UrlSourceClassifier.normalizeUrl(dirtyYt);
        assertThat(normalizedYt).isEqualTo("https://youtube.com/watch?v=5vJ0P2K8tZs");

        String dirtyIg = "https://www.instagram.com/reel/C7Xyz123/?igsh=MWx123&utm_medium=copy_link";
        String normalizedIg = UrlSourceClassifier.normalizeUrl(dirtyIg);
        assertThat(normalizedIg).isEqualTo("https://instagram.com/reel/C7Xyz123");
    }
}
