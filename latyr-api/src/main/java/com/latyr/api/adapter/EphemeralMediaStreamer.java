package com.latyr.api.adapter;

import com.latyr.api.exception.LatyrException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;

@Component
public class EphemeralMediaStreamer {

    private static final Logger log = LoggerFactory.getLogger(EphemeralMediaStreamer.class);
    private static final int MAX_IN_MEMORY_SIZE = 15 * 1024 * 1024; // 15 MB strict limit

    private final WebClient webClient;

    public EphemeralMediaStreamer() {
        ExchangeStrategies strategies = ExchangeStrategies.builder()
                .codecs(codecs -> codecs.defaultCodecs().maxInMemorySize(MAX_IN_MEMORY_SIZE))
                .build();
        this.webClient = WebClient.builder()
                .exchangeStrategies(strategies)
                .build();
    }

    public byte[] streamMedia(String mediaUrl) {
        if (mediaUrl == null || mediaUrl.trim().isEmpty()) {
            return new byte[0];
        }

        log.info("Streaming media in-memory from URL: {}", mediaUrl);
        try {
            return webClient.get()
                    .uri(mediaUrl)
                    .retrieve()
                    .bodyToMono(byte[].class)
                    .block(Duration.ofSeconds(30));
        } catch (Exception e) {
            log.error("Failed to stream media from {}: {}", mediaUrl, e.getMessage());
            throw new LatyrException("Failed to stream media: " + e.getMessage(), "MEDIA_STREAM_FAILED", HttpStatus.BAD_GATEWAY);
        }
    }
}
