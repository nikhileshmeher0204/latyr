package com.latyr.api.adapter;

import com.latyr.api.exception.LatyrException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class ApifyScraperAdapter implements ScraperProvider {

    private static final Logger log = LoggerFactory.getLogger(ApifyScraperAdapter.class);
    private static final String APIFY_ACTOR_URL = "https://api.apify.com/v2/acts/apify~instagram-scraper/run-sync-get-dataset-items";

    @Value("${apify.api.token:}")
    private String apiToken;

    private final WebClient webClient;
    private final java.util.concurrent.Semaphore concurrencyLimiter;

    public ApifyScraperAdapter(
            WebClient.Builder webClientBuilder,
            @Value("${apify.api.max-concurrency:1}") int maxConcurrency) {
        this.webClient = webClientBuilder
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
                .build();
        this.concurrencyLimiter = new java.util.concurrent.Semaphore(maxConcurrency);
        log.info("Initialized ApifyScraperAdapter with max-concurrency: {}", maxConcurrency);
    }

    @Override
    @SuppressWarnings("unchecked")
    public ScrapedMedia extractMedia(String url) {
        if (apiToken == null || apiToken.trim().isEmpty()) {
            log.info("Apify API token is not configured. Extracting public OpenGraph metadata for URL: {}", url);
            OgMetadata og = fetchInstagramOgMetadata(url);
            String caption = (og.caption() != null && !og.caption().isBlank()) ? og.caption() : ("Instagram Reel: " + url);
            return new ScrapedMedia(url, null, og.imageUrl(), caption, "Instagram Reel", 30, Map.of("fallback", true, "url", url, "scraped_og", og.caption() != null));
        }

        log.info("Executing live Apify Instagram Scraper for URL: {}", url);
        try {
            concurrencyLimiter.acquire();
            Map<String, Object> requestBody = Map.of(
                    "directUrls", List.of(url),
                    "resultsType", "posts",
                    "resultsLimit", 1,
                    "commentsLimit", 0,
                    "commentsMode", "none"
            );

            List<Map<String, Object>> responseList = webClient.post()
                    .uri(APIFY_ACTOR_URL + "?token=" + apiToken.trim())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToFlux(new org.springframework.core.ParameterizedTypeReference<Map<String, Object>>() {})
                    .collectList()
                    .block(Duration.ofSeconds(90));

            if (responseList == null || responseList.isEmpty()) {
                throw new LatyrException("Apify returned empty dataset items for URL: " + url, "SCRAPING_FAILED", HttpStatus.BAD_GATEWAY);
            }

            Map<String, Object> item = responseList.get(0);
            String caption = (String) item.getOrDefault("caption", "");
            String videoUrl = (String) item.get("videoUrl");
            String audioUrl = (String) item.getOrDefault("audioUrl", videoUrl);
            String title = (String) item.getOrDefault("title", "Saved Reel");

            String thumbnailUrl = (String) item.get("displayUrl");
            if (thumbnailUrl == null || thumbnailUrl.isBlank()) {
                thumbnailUrl = (String) item.get("thumbnailUrl");
            }
            if (thumbnailUrl == null || thumbnailUrl.isBlank()) {
                thumbnailUrl = (String) item.get("displayResource");
            }
            if ((thumbnailUrl == null || thumbnailUrl.isBlank()) && item.get("images") instanceof List<?> imgList && !imgList.isEmpty()) {
                thumbnailUrl = String.valueOf(imgList.get(0));
            }

            Integer duration = null;
            Object durObj = item.get("videoDuration");
            if (durObj instanceof Number num) {
                duration = num.intValue();
            }

            // Explicitly exclude any comment data from raw metadata
            Map<String, Object> sanitizedMetadata = new LinkedHashMap<>();
            for (Map.Entry<String, Object> entry : item.entrySet()) {
                String key = entry.getKey();
                if (!key.toLowerCase().contains("comment")) {
                    sanitizedMetadata.put(key, entry.getValue());
                }
            }

            return new ScrapedMedia(videoUrl, audioUrl, thumbnailUrl, caption, title, duration, sanitizedMetadata);
        } catch (LatyrException le) {
            throw le;
        } catch (Exception e) {
            log.error("Live Apify scraping failed for URL {}: {}", url, e.getMessage());
            throw new LatyrException("Failed to scrape media from Instagram: " + e.getMessage(), "SCRAPING_FAILED", HttpStatus.BAD_GATEWAY);
        } finally {
            concurrencyLimiter.release();
        }
    }

    private record OgMetadata(String caption, String imageUrl) {}

    private OgMetadata fetchInstagramOgMetadata(String url) {
        String caption = null;
        String imageUrl = null;
        try {
            String html = webClient.get()
                    .uri(url)
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(10));

            if (html != null) {
                // Find og:description or description
                java.util.regex.Pattern descPattern = java.util.regex.Pattern.compile("<meta\\s+(?:property|name)=[\"'](?:og:description|description)[\"']\\s+content=[\"'](.*?)[\"']", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.DOTALL);
                java.util.regex.Matcher descMatcher = descPattern.matcher(html);
                if (descMatcher.find()) {
                    caption = org.springframework.web.util.HtmlUtils.htmlUnescape(descMatcher.group(1)).trim();
                }

                // Find og:image
                java.util.regex.Pattern imgPattern = java.util.regex.Pattern.compile("<meta\\s+(?:property|name)=[\"']og:image[\"']\\s+content=[\"'](.*?)[\"']", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.DOTALL);
                java.util.regex.Matcher imgMatcher = imgPattern.matcher(html);
                if (imgMatcher.find()) {
                    imageUrl = org.springframework.web.util.HtmlUtils.htmlUnescape(imgMatcher.group(1)).trim();
                }
            }
        } catch (Exception e) {
            log.warn("Could not extract public OG tags from Instagram URL {}: {}", url, e.getMessage());
        }
        return new OgMetadata(caption, imageUrl);
    }
}
