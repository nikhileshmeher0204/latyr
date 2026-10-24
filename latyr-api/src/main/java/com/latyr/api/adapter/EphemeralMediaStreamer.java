package com.latyr.api.adapter;

import com.latyr.api.exception.ProviderOperationException;
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

        try {
            return webClient.get()
                    .uri(mediaUrl)
                    .retrieve()
                    .bodyToMono(byte[].class)
                    .block(Duration.ofSeconds(30));
        } catch (org.springframework.web.reactive.function.client.WebClientResponseException rejected) {
            int status = rejected.getStatusCode().value();
            throw new ProviderOperationException("MEDIA_UNAVAILABLE", status == 429 || status >= 500
                    ? ProviderOperationException.Outcome.RETRYABLE : ProviderOperationException.Outcome.PERMANENT);
        } catch (org.springframework.core.io.buffer.DataBufferLimitException oversized) {
            throw new ProviderOperationException("MEDIA_TOO_LARGE", ProviderOperationException.Outcome.PERMANENT);
        } catch (Exception failure) {
            throw new ProviderOperationException("MEDIA_STREAM_FAILED", ProviderOperationException.Outcome.RETRYABLE);
        }
    }
}
