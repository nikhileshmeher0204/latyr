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
import java.util.List;
import java.util.Map;

@Component
public class ApifyScraperAdapter implements ScraperProvider {

    private static final Logger log = LoggerFactory.getLogger(ApifyScraperAdapter.class);
    private static final String APIFY_ACTOR_URL = "https://api.apify.com/v2/acts/apify~instagram-reel-scraper/run-sync-get-dataset-items";

    @Value("${apify.api.token:}")
    private String apiToken;

    @Value("${apify.mock.enabled:false}")
    private boolean mockEnabled;

    private final WebClient webClient;

    public ApifyScraperAdapter(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    @Override
    @SuppressWarnings("unchecked")
    public ScrapedMedia extractMedia(String url) {
        if (mockEnabled || apiToken == null || apiToken.trim().isEmpty()) {
            log.info("ApifyScraperAdapter running in MOCK mode for URL: {}", url);
            return new ScrapedMedia(
                    "https://mock-cdn.latyr.internal/reels/video.mp4",
                    "https://mock-cdn.latyr.internal/reels/audio.mp3",
                    "5 mind-bending thriller shows you must watch on Netflix! #recommendations #dark",
                    "Top 5 Thriller Shows",
                    45,
                    Map.of("platform", "Instagram", "mock", true)
            );
        }

        log.info("Invoking Apify Instagram Reel Scraper for URL: {}", url);
        try {
            Map<String, Object> requestBody = Map.of(
                    "directUrls", List.of(url),
                    "includeTranscript", false
            );

            List<Map<String, Object>> responseList = webClient.post()
                    .uri(APIFY_ACTOR_URL + "?token=" + apiToken.trim())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToFlux(new org.springframework.core.ParameterizedTypeReference<Map<String, Object>>() {})
                    .collectList()
                    .block(Duration.ofSeconds(60));

            if (responseList == null || responseList.isEmpty()) {
                throw new LatyrException("Apify returned empty dataset items for URL: " + url, "SCRAPING_FAILED", HttpStatus.BAD_GATEWAY);
            }

            Map<String, Object> item = responseList.get(0);
            String caption = (String) item.getOrDefault("caption", "");
            String videoUrl = (String) item.get("videoUrl");
            String audioUrl = (String) item.getOrDefault("audioUrl", videoUrl);
            String title = (String) item.getOrDefault("title", "Saved Reel");

            Integer duration = null;
            Object durObj = item.get("videoDuration");
            if (durObj instanceof Number num) {
                duration = num.intValue();
            }

            return new ScrapedMedia(videoUrl, audioUrl, caption, title, duration, item);
        } catch (Exception e) {
            log.error("Apify scraping failed for URL {}: {}", url, e.getMessage());
            throw new LatyrException("Failed to scrape media from Instagram: " + e.getMessage(), "SCRAPING_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }
}
