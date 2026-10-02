package com.latyr.api.adapter;

import java.util.Map;

public interface ScraperProvider {

    ScrapedMedia extractMedia(String url);

    record ScrapedMedia(
            String mediaUrl,
            String audioUrl,
            String thumbnailUrl,
            String caption,
            String title,
            Integer durationSec,
            Map<String, Object> rawMetadata
    ) {}
}
