package com.latyr.api.adapter;

import com.latyr.api.exception.LatyrException;
import com.latyr.api.exception.ProviderOperationException;
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
            throw new ProviderOperationException("MISSING_CONFIGURATION", ProviderOperationException.Outcome.PERMANENT);
        }

        boolean acquired = false;
        try {
            concurrencyLimiter.acquire();
            acquired = true;
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
                throw new ProviderOperationException("SOURCE_UNAVAILABLE", ProviderOperationException.Outcome.PERMANENT);
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
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new ProviderOperationException("SCRAPER_INTERRUPTED", ProviderOperationException.Outcome.RETRYABLE);
        } catch (org.springframework.web.reactive.function.client.WebClientResponseException rejected) {
            int status = rejected.getStatusCode().value();
            throw new ProviderOperationException(status == 429 ? "SCRAPER_RATE_LIMITED" : "SCRAPER_REQUEST_REJECTED",
                    status == 429 ? ProviderOperationException.Outcome.RETRYABLE :
                    status >= 400 && status < 500 ? ProviderOperationException.Outcome.PERMANENT : ProviderOperationException.Outcome.AMBIGUOUS);
        } catch (Exception e) {
            throw new ProviderOperationException("SCRAPER_OUTCOME_UNKNOWN", ProviderOperationException.Outcome.AMBIGUOUS);
        } finally {
            if (acquired) concurrencyLimiter.release();
        }
    }

}
