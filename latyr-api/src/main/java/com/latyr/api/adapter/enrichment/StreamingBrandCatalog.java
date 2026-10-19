package com.latyr.api.adapter.enrichment;

import com.latyr.api.adapter.storage.AssetStorageProvider;
import org.springframework.stereotype.Component;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/**
 * Server-driven dynamic catalog for streaming provider brand metadata.
 * 
 * Uses decoupled AssetStorageProvider to resolve CDN URLs dynamically from
 * environment configuration properties without hardcoded domains.
 */
@Component
public class StreamingBrandCatalog {

    private final AssetStorageProvider storageProvider;

    public record BrandMetadata(
        String brandColor,
        String tileColor,
        String svgAsset,
        String svgUrl,
        String deepLinkTemplate
    ) {}

    public StreamingBrandCatalog(AssetStorageProvider storageProvider) {
        this.storageProvider = storageProvider;
    }

    /**
     * Resolves canonical brand metadata by TMDB provider ID or provider name.
     */
    public BrandMetadata resolve(int providerId, String providerName) {
        String name = (providerName != null) ? providerName.toLowerCase(Locale.ROOT) : "";

        // 1. Netflix (TMDB ID 8)
        if (providerId == 8 || name.contains("netflix")) {
            return new BrandMetadata(
                "#E50914",
                "#000000",
                "assets/icons/streaming/netflix.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("netflix.svg") : null,
                "https://www.netflix.com/search?q=%s"
            );
        }

        // 2. Amazon Prime Video (TMDB ID 9, 119)
        if (providerId == 9 || providerId == 119 || name.contains("prime") || name.contains("amazon")) {
            return new BrandMetadata(
                "#00A8E1",
                "#00A8E1",
                "assets/icons/streaming/prime_video.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("prime_video.svg") : null,
                "https://www.amazon.com/s?k=%s&i=instant-video"
            );
        }

        // 3. Apple TV / Apple TV+ (TMDB ID 350, 2)
        if (providerId == 350 || providerId == 2 || name.contains("apple")) {
            return new BrandMetadata(
                "#000000",
                "#000000",
                "assets/icons/streaming/apple_tv.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("apple_tv.svg") : null,
                "https://tv.apple.com/search?term=%s"
            );
        }

        // 4. Disney+ (TMDB ID 337)
        if (providerId == 337 || (name.contains("disney") && !name.contains("hotstar"))) {
            return new BrandMetadata(
                "#040714",
                "#040714",
                "assets/icons/streaming/disney_plus.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("disney_plus.svg") : null,
                "https://www.disneyplus.com/search?q=%s"
            );
        }

        // 5. Hotstar / JioHotstar (TMDB ID 122, 390)
        if (providerId == 122 || providerId == 390 || name.contains("hotstar")) {
            return new BrandMetadata(
                "#14805E",
                "#0C111B",
                "assets/icons/streaming/hotstar.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("hotstar.svg") : null,
                "https://www.hotstar.com/in/explore?search_query=%s"
            );
        }

        // 6. HBO Max / Max (TMDB ID 384, 1899)
        if (providerId == 384 || providerId == 1899 || name.contains("max") || name.contains("hbo")) {
            return new BrandMetadata(
                "#002BE7",
                "#002BE7",
                "assets/icons/streaming/hbo_max.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("hbo_max.svg") : null,
                "https://play.max.com/search?q=%s"
            );
        }

        // 7. Hulu (TMDB ID 15)
        if (providerId == 15 || name.contains("hulu")) {
            return new BrandMetadata(
                "#1CE783",
                "#000000",
                "assets/icons/streaming/hulu.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("hulu.svg") : null,
                "https://www.hulu.com/search?q=%s"
            );
        }

        // 8. Paramount+ (TMDB ID 531)
        if (providerId == 531 || name.contains("paramount")) {
            return new BrandMetadata(
                "#0064FF",
                "#0064FF",
                "assets/icons/streaming/paramount_plus.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("paramount_plus.svg") : null,
                "https://www.paramountplus.com/search/?query=%s"
            );
        }

        // 9. Peacock (TMDB ID 386, 387)
        if (providerId == 386 || providerId == 387 || name.contains("peacock")) {
            return new BrandMetadata(
                "#000000",
                "#000000",
                "assets/icons/streaming/peacock.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("peacock.svg") : null,
                "https://www.peacocktv.com/search?q=%s"
            );
        }

        // 10. YouTube / YouTube Premium (TMDB ID 192)
        if (providerId == 192 || name.contains("youtube")) {
            return new BrandMetadata(
                "#FF0000",
                "#FFFFFF",
                "assets/icons/streaming/youtube.svg",
                storageProvider != null ? storageProvider.resolveAssetUrl("youtube.svg") : null,
                "https://www.youtube.com/results?search_query=%s"
            );
        }

        // Fallback for uncataloged or regional providers
        return new BrandMetadata(
            "#1C1C1E",
            "#1C1C1E",
            null,
            null,
            "https://www.google.com/search?q=watch+%s"
        );
    }

    /**
     * Builds a deep link or search URL using the provider template and movie title.
     */
    public String buildWatchUrl(BrandMetadata meta, String title) {
        if (meta == null || meta.deepLinkTemplate() == null) {
            return null;
        }
        String query = (title != null && !title.isBlank())
            ? URLEncoder.encode(title.trim(), StandardCharsets.UTF_8)
            : "";
        return String.format(meta.deepLinkTemplate(), query);
    }
}
