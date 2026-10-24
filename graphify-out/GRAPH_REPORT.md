# Graph Report - latyr  (2026-10-24)

## Corpus Check
- 248 files · ~1,696,795 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 57 file(s) not represented in the graph (top: (none) 9, .properties 8, .xml 7)

## Summary
- 2907 nodes · 5968 edges · 156 communities (95 shown, 61 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 647 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5520a0a2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package:flutter/cupertino.dart
- ExtractedEntity
- app_database.dart
- app_database.g.dart
- CaptureServiceTest.java
- entertainment_detail_screen.dart
- Language
- glass_card.dart
- capture_detail_screen.dart
- CanonicalSource
- collections_providers.dart
- latyr_colors.dart
- latyr_progressive_blur.dart
- search_screen.dart
- latyr_spacing.dart
- entity_cards.dart
- github_repo_detail_screen.dart
- GitHubEntityEnricherTest.java
- latyr_typography.dart
- app_colors.dart
- latyr_rich_summary.dart
- EntertainmentEntityEnricher
- entertainment_metadata.dart
- UserSubscriptionHistory
- .createUrlCapture
- sse_auth_test.dart
- where_to_watch_card.dart
- filter_chip_bar.dart
- Capture
- capture_providers.dart
- capture_repository.dart
- CaptureService
- NotificationLog
- JsonbTypeHandler.java
- WatchProviderCategory
- UserCollection
- home_screen.dart
- sse_client.dart
- .processJob
- org.junit.jupiter.api.Test
- TmdbClient
- LatyrException
- Live visual verification showcase / Latyr Flutter package manifest
- SubscriptionQuotaService
- V1__init_schema.sql
- CurrentUserArgumentResolver
- CaptureControllerTest.java
- extracted_entity_model.dart
- User
- api_client.dart
- intent_detail_app_bar.dart
- github_repo_metadata.dart
- AuthenticatedUser
- movie_show_entity_card.dart
- dominant_color_service.dart
- SecurityConfig.java
- FirebaseSecurityChainTest.java
- org.springframework.http.ResponseEntity
- app_theme.dart
- collections
- UserMapper
- org.springframework.stereotype.Component
- Intent
- summary_token.dart
- CaptureCollection
- capture_repository_test.dart
- GoogleGenAIConfig.java
- AppDelegate
- UserSubscription
- instant
- AIEntity
- home_providers.dart
- CaptureMapper
- sync_service.dart
- Collection
- CaptureController.java
- place_metadata.dart
- capture_source_icon.dart
- app_switcher_scroll_physics.dart
- latyr_capture_card.dart
- latyr_expandable_text.dart
- String?
- ApifyScraperAdapter
- recipe_metadata.dart
- brand_registry.dart
- app.dart
- List
- library_1x2_grid_widget.dart
- RestGitHubClient
- State
- CaptureStreamController.java
- EntertainmentEntityEnricher
- Intent
- UrlNormalizationService
- CollectionMapper
- .resolveArgument
- capture_source_classifier.dart
- summary_lexer.dart
- SubscriptionQuotaService
- github_language_colors.dart
- LocalCapture
- token_provider_test.dart
- app_properties.dart
- watch_provider_category.dart
- TypographyContext
- LocalCaptures
- Latyr backend REST API / Latyr Flutter mobile application
- Orchestrated layered architecture / External adapter facades
- iOS launch screen assets / Xcode asset catalog launch image customization
- Flutter getting started resources / Latyr personal knowledge application
- Graphify query-first workflow
- PostgreSQL SKIP LOCKED worker queue
- Latryl home screen design reference
- Resolution provenance JSONB metadata
- Share extension 300ms local write target
- Stateless token authentication
- Java 21 virtual threads
- com.latyr:latyr-api
- pill_badge.dart
- WeatherIntegrationClient
- floating_nav_island.dart
- summary_action_handler.dart
- apple_tv_badge.dart
- Dart Flutter DevTools extension settings
- LatyrException
- streaming_branding.dart
- RemovedDiagnosticRoutesTest.java
- Document
- color_extraction_service.dart
- EntertainmentEntityEnricher.java
- ResurfacingScheduler.java
- EntityController
- PagedResponse
- Document
- org.slf4j.Logger

## God Nodes (most connected - your core abstractions)
1. `Capture` - 73 edges
2. `ExtractedEntity` - 42 edges
3. `IngestionJob` - 42 edges
4. `EntityType` - 36 edges
5. `User` - 36 edges
6. `AIEntity` - 32 edges
7. `EntertainmentEntityEnricher` - 32 edges
8. `CanonicalSource` - 32 edges
9. `UserSubscription` - 32 edges
10. `TmdbClient` - 32 edges

## Surprising Connections (you probably didn't know these)
- `Latyr owned progressive blur fragment shader` --semantically_similar_to--> `Pure progressive blur cinema hero architecture`  [INFERRED] [semantically similar]
  latyr-app/pubspec.yaml → VISUAL_VERIFICATION_SHOWCASE.md
- `Flutter runtime dependency catalog` --references--> `Riverpod AsyncNotifier and StateNotifier`  [EXTRACTED]
  latyr-app/pubspec.yaml → AGENTS.md
- `Flutter runtime dependency catalog` --references--> `Offline-first Drift SQLite caching`  [EXTRACTED]
  latyr-app/pubspec.yaml → AGENTS.md
- `GoogleGenAIAdapter` --implements--> `AIProvider`  [EXTRACTED]
  latyr-api/src/main/java/com/latyr/api/adapter/GoogleGenAIAdapter.java → latyr-api/src/main/java/com/latyr/api/adapter/AIProvider.java
- `AIAnalysisResult` --references--> `Intent`  [EXTRACTED]
  latyr-api/src/main/java/com/latyr/api/adapter/AIProvider.java → latyr-api/src/main/java/com/latyr/api/domain/enums/Intent.java

## Import Cycles
- None detected.

## Communities (156 total, 61 thin omitted)

### Community 0 - "package:flutter/cupertino.dart"
Cohesion: 0.06
Nodes (38): build, CaptureBannerWidget, onTap, build, HomeMetricsWidget, onProcessingTap, processedCount, processingCount (+30 more)

### Community 2 - "app_database.dart"
Cohesion: 0.04
Nodes (39): _, custom, _sourceTypeMeta, toColumns, audioTranscript, category, contentType, createdAt (+31 more)

### Community 3 - "app_database.g.dart"
Cohesion: 0.04
Nodes (52): actualTableName, _alias, aliasedName, allSchemaEntities, allTables, attachedDatabase, _audioTranscriptMeta, _categoryMeta (+44 more)

### Community 4 - "CaptureServiceTest.java"
Cohesion: 0.09
Nodes (19): ActionCTA, COOK, EXPLORE, OPEN_GITHUB, READ, REMEMBER, VISIT, WATCH (+11 more)

### Community 5 - "entertainment_detail_screen.dart"
Cohesion: 0.09
Nodes (22): _AppleTvImdbLinkTile, _AppleTvImdbLinkTileState, build, _buildDetailRow, createState, entity, _fontFamily, imdbId (+14 more)

### Community 6 - "Language"
Cohesion: 0.17
Nodes (8): AIAnalysisResult, TypeReference<Map<String, Object>>, Language, ENGLISH, HINDI, HINGLISH, ORIGINAL, UpdatePreferencesRequest

### Community 7 - "glass_card.dart"
Cohesion: 0.09
Nodes (20): borderRadius, build, child, _controller, createState, customBorder, dispose, GlassCardVariant (+12 more)

### Community 8 - "capture_detail_screen.dart"
Cohesion: 0.08
Nodes (24): apiClientProvider, appDatabaseProvider, build, _buildCaptureIntentsSection, _buildCardDecoration, _buildCuratedMediaCard, _buildMediaTextSection, _buildProcessingBanner (+16 more)

### Community 9 - "CanonicalSource"
Cohesion: 0.09
Nodes (7): SourceType, IMAGE, INSTAGRAM_REEL, WEB_URL, YOUTUBE_SHORT, YOUTUBE_VIDEO, CanonicalSource

### Community 10 - "collections_providers.dart"
Cohesion: 0.06
Nodes (24): fromString, image, CategoryGroup, build, CategoryDetailScreen, categoryGroup, captures, capturesAsync (+16 more)

### Community 11 - "latyr_colors.dart"
Cohesion: 0.05
Nodes (42): amberBorder, amberFill, ambientHoney, ambientWarmGlow, ambientWheat, brandAmber, brandAmberDark, brandAmberLight (+34 more)

### Community 12 - "latyr_progressive_blur.dart"
Cohesion: 0.05
Nodes (26): alwaysNeedsCompositing, begin, build, child, _configureShader, createRenderObject, createState, devicePixelRatio (+18 more)

### Community 13 - "search_screen.dart"
Cohesion: 0.08
Nodes (22): captureListStreamProvider, _buildOverlappingFeed, build, _buildEmptyState, _buildEntityWidget, createState, _filters, LibraryScreen (+14 more)

### Community 14 - "latyr_spacing.dart"
Cohesion: 0.05
Nodes (38): base, blurCard, blurNav, brLG, brMD, brPill, brSheet, brSM (+30 more)

### Community 15 - "entity_cards.dart"
Cohesion: 0.06
Nodes (38): _DottedUnderlineText, _HandwrittenWavyText, EntertainmentDetailScreen, _MaturityBadge, _MetascoreText, _RatingText, _RottenTomatoesText, _VibrantText (+30 more)

### Community 16 - "github_repo_detail_screen.dart"
Cohesion: 0.11
Nodes (12): ExtractedEntityMetadataX, ExtractedEntityModel, build, _buildAvatarFallback, _buildSpecRow, _copyToClipboard, entity, _fontFamily (+4 more)

### Community 17 - "GitHubEntityEnricherTest.java"
Cohesion: 0.18
Nodes (8): GitHubEntityEnricher, GitHubRepoDetailsDTO, LicenseDTO, OwnerDTO, GitHubSearchResultDTO, ItemDTO, GitHubClient, GitHubEntityEnricherTest

### Community 18 - "latyr_typography.dart"
Cohesion: 0.05
Nodes (36): body, buttonLabel, callout, caption1, caption1Bold, caption2, caption2Bold, eyebrow (+28 more)

### Community 19 - "app_colors.dart"
Cohesion: 0.05
Nodes (38): alabaster, alabasterBorder, alabasterGlass, amberBorder, amberGlow, amberSubtle, ambientHoney, ambientWarmGlow (+30 more)

### Community 20 - "latyr_rich_summary.dart"
Cohesion: 0.05
Nodes (31): _amplitude, build, cardAccentColor, _clearRecognizers, color, createState, didUpdateWidget, dispose (+23 more)

### Community 21 - "EntertainmentEntityEnricher"
Cohesion: 0.11
Nodes (10): StreamingPlatform, APPLE_TV, DISNEY_HOTSTAR, NETFLIX, OTHER, PRIME_VIDEO, SONY_LIV, THEATRICAL (+2 more)

### Community 22 - "entertainment_metadata.dart"
Cohesion: 0.06
Nodes (34): awards, backdropUrl, boxOffice, contentRating, country, director, durationOrSeasons, EntertainmentMetadata (+26 more)

### Community 23 - "UserSubscriptionHistory"
Cohesion: 0.09
Nodes (6): SubscriptionEventType, CANCELLATION, DOWNGRADE, RENEWAL, UPGRADE, UserSubscriptionHistory

### Community 25 - "sse_auth_test.dart"
Cohesion: 0.07
Nodes (14): AuthInterceptor, onError, onRequest, TokenProvider, AuthenticationRequiredException, toString, main, close (+6 more)

### Community 26 - "where_to_watch_card.dart"
Cohesion: 0.07
Nodes (29): brandColor, build, _buildCategoryRow, _buildFallbackInitial, _buildLogoContent, _buildSecondaryFallback, category, createState (+21 more)

### Community 27 - "filter_chip_bar.dart"
Cohesion: 0.06
Nodes (29): build, _controller, createState, dispose, FilterChipBar, FilterChipItem, iconText, initState (+21 more)

### Community 29 - "capture_providers.dart"
Cohesion: 0.11
Nodes (16): auth, client, db, firebaseAuthProvider, repo, service, shareIntentServiceProvider, sseClientProvider (+8 more)

### Community 31 - "capture_repository.dart"
Cohesion: 0.11
Nodes (17): SseClient, apiClient, captureUrl, checkProcessingCaptures, db, dispose, fetchRemoteFeed, hasActiveProcessingCaptures (+9 more)

### Community 32 - "CaptureService"
Cohesion: 0.11
Nodes (6): CanonicalSourceMapper, IngestionJobMapper, CanonicalDeduplicationService, CaptureService, IngestionQueueWorker, CaptureServiceTest

### Community 34 - "JsonbTypeHandler.java"
Cohesion: 0.15
Nodes (3): JsonbTypeHandler, StringArrayTypeHandler, UuidTypeHandler

### Community 35 - "WatchProviderCategory"
Cohesion: 0.09
Nodes (9): BrandMetadata, StreamingBrandCatalog, AssetStorageProvider, CdnAssetStorageProvider, WatchProviderCategory, BUY, FLATRATE, FREE (+1 more)

### Community 37 - "home_screen.dart"
Cohesion: 0.05
Nodes (37): build, captureRepositoryProvider, CaptureDetailScreen, build, homeStatsProvider, weatherProvider, build, _buildAnimatedCard (+29 more)

### Community 38 - "sse_client.dart"
Cohesion: 0.08
Nodes (19): _cancelToken, connect, data, _dio, disconnect, dispose, _eventController, events (+11 more)

### Community 39 - ".processJob"
Cohesion: 0.07
Nodes (6): JobStatus, COMPLETED, FAILED, PENDING, PROCESSING, IngestionJob

### Community 40 - "org.junit.jupiter.api.Test"
Cohesion: 0.07
Nodes (9): UrlSourceClassifier, ApifyScraperAdapterTest, EntertainmentEntityEnricherTest, EphemeralMediaStreamerTest, GoogleGenAIAdapterTest, LatyrApiApplicationTests, SseNotificationServiceTest, MarkupSanitizerTest (+1 more)

### Community 41 - "TmdbClient"
Cohesion: 0.23
Nodes (14): TmdbCast, TmdbClient, TmdbCountryWatchProviders, TmdbCredits, TmdbCrew, TmdbExternalIds, TmdbGenre, TmdbItem (+6 more)

### Community 43 - "Live visual verification showcase / Latyr Flutter package manifest"
Cohesion: 0.09
Nodes (21): Feature-First MVVM, Dynamic palette extraction and Brand Token Registry, Riverpod AsyncNotifier and StateNotifier, Pure stateless presentation renderers, Dart analyzer configuration, Flutter recommended analyzer lints, Flutter lint test and Drift build dependencies, Bundled icon assets (+13 more)

### Community 45 - "V1__init_schema.sql"
Cohesion: 0.16
Nodes (26): canonical_sources, capture_collections, captures, extracted_entities, idx_canonical_sources_hash, idx_captures_resurface, idx_captures_user_status_created, idx_extracted_entities_metadata_gin (+18 more)

### Community 47 - "CaptureControllerTest.java"
Cohesion: 0.11
Nodes (5): CaptureControllerTest, HandlerMethodArgumentResolver, CaptureStreamControllerTest, CurrentUserArgumentResolver, UserControllerTest

### Community 48 - "extracted_entity_model.dart"
Cohesion: 0.08
Nodes (16): actionCta, book, description, entertainment, entityType, externalUrl, fromJson, generic (+8 more)

### Community 50 - "api_client.dart"
Cohesion: 0.09
Nodes (15): cdnBaseUrl, environment, EnvironmentConfig, isLocal, isProd, isUat, _rawApiUrl, ApiClient (+7 more)

### Community 51 - "intent_detail_app_bar.dart"
Cohesion: 0.08
Nodes (20): captures, categoryName, color, icon, SubCategoryGroup, subCategoryName, build, parentCategoryColor (+12 more)

### Community 52 - "github_repo_metadata.dart"
Cohesion: 0.08
Nodes (24): audit, avatarUrl, defaultBranch, forks, forksFormatted, formatCount, fromMap, fullName (+16 more)

### Community 53 - "AuthenticatedUser"
Cohesion: 0.14
Nodes (4): PlanTier, FREE, PRO, AuthenticatedUser

### Community 54 - "movie_show_entity_card.dart"
Cohesion: 0.09
Nodes (19): build, categoryTag, ForYouCardWidget, onOpen, posterUrl, subtitle, title, build (+11 more)

### Community 55 - "dominant_color_service.dart"
Cohesion: 0.09
Nodes (20): accent, background, DominantColorService, DominantPalette, extractDominantColor, extractPalette, fallback, getCachedPalette (+12 more)

### Community 56 - "SecurityConfig.java"
Cohesion: 0.09
Nodes (5): AsyncConfig, JacksonConfig, LatyrApiApplication, SecurityConfig, TestConfiguration

### Community 58 - "org.springframework.http.ResponseEntity"
Cohesion: 0.15
Nodes (3): CaptureController, UserController, UserProfileResponse

### Community 60 - "app_theme.dart"
Cohesion: 0.09
Nodes (18): accent, AppTheme, background, border, cupertinoTheme, darkTheme, error, info (+10 more)

### Community 61 - "collections"
Cohesion: 0.22
Nodes (4): OmdbClient, OmdbMovieResponse, OmdbRating, collections

### Community 62 - "UserMapper"
Cohesion: 0.18
Nodes (3): UserMapper, ResurfacingScheduler, ResurfacingSchedulerTest

### Community 63 - "org.springframework.stereotype.Component"
Cohesion: 0.10
Nodes (6): FirebaseIdentityTokenVerifier, IdentityTokenVerifier, VerifiedIdentity, PathNormalizationFilter, HttpServletRequestWrapper, FirebaseAuthFilter

### Community 65 - "summary_token.dart"
Cohesion: 0.10
Nodes (17): actionPayload, actionScheme, actionType, hashCode, highlight, icon3d, iconName, italic (+9 more)

### Community 67 - "capture_repository_test.dart"
Cohesion: 0.09
Nodes (13): AppDatabase, db, main, main, calls, close, db, fetch (+5 more)

### Community 68 - "GoogleGenAIConfig.java"
Cohesion: 0.16
Nodes (3): GoogleGenAIAdapter, GoogleGenAIConfig, FirebaseConfig

### Community 69 - "AppDelegate"
Cohesion: 0.12
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 72 - "AIEntity"
Cohesion: 0.18
Nodes (4): AIEntity, DefaultEntityEnrichmentAdapter, EntityEnricher, DefaultEntityEnrichmentAdapterTest

### Community 73 - "home_providers.dart"
Cohesion: 0.14
Nodes (13): apiClient, capturesToday, categoriesDiscovered, city, condition, db, fromJson, HomeStats (+5 more)

### Community 74 - "CaptureMapper"
Cohesion: 0.14
Nodes (7): CaptureStatus, COMPLETED, FAILED, PENDING, PROCESSING, CaptureDetailResponse, CaptureMapper

### Community 75 - "sync_service.dart"
Cohesion: 0.07
Nodes (20): captureRepository, _channel, dispose, _extractUrl, _handleSharedText, _init, _lastHandledAt, _lastHandledUrl (+12 more)

### Community 78 - "place_metadata.dart"
Cohesion: 0.12
Nodes (15): address, city, country, fromMap, latitude, location, longitude, mapsUrl (+7 more)

### Community 79 - "capture_source_icon.dart"
Cohesion: 0.14
Nodes (13): CaptureSource, build, CaptureSourceIcon, color, _InstagramGlyphPainter, paint, shouldRepaint, size (+5 more)

### Community 80 - "app_switcher_scroll_physics.dart"
Cohesion: 0.13
Nodes (8): applyPhysicsToUserOffset, applyTo, AppSwitcherScrollPhysics, createBallisticSimulation, _kOverScrollSpring, minFlickVelocity, velocityPerCard, main

### Community 81 - "latyr_capture_card.dart"
Cohesion: 0.10
Nodes (14): capture, cardColorFor, _cleanPreviewSummary, _computeIsDark, createState, didChangeDependencies, didUpdateWidget, _extractedColor (+6 more)

### Community 82 - "latyr_expandable_text.dart"
Cohesion: 0.15
Nodes (11): RoundedTextStyle, animationDuration, build, createState, _isExpanded, LatyrExpandableText, _LatyrExpandableTextState, maxLines (+3 more)

### Community 83 - "String?"
Cohesion: 0.06
Nodes (28): author, BookMetadata, buyUrl, coverUrl, fromMap, genres, isbn, overview (+20 more)

### Community 84 - "ApifyScraperAdapter"
Cohesion: 0.28
Nodes (3): ApifyScraperAdapter, org.springframework.core.ParameterizedTypeReference<Map<String, Object>>, OgMetadata

### Community 85 - "recipe_metadata.dart"
Cohesion: 0.14
Nodes (13): calories, cookTime, cuisine, difficulty, fromMap, imageUrl, ingredients, instructions (+5 more)

### Community 86 - "brand_registry.dart"
Cohesion: 0.15
Nodes (12): brandColor, BrandRegistry, BrandToken, colorFromHex, iconColor, logoUrl, name, resolve (+4 more)

### Community 87 - "app.dart"
Cohesion: 0.10
Nodes (13): build, _buildFloatingNavBar, _buildNavItem, createState, _currentIndex, dispose, initState, LatyrApp (+5 more)

### Community 88 - "List"
Cohesion: 0.17
Nodes (9): category, confidenceScore, fromMap, GenericEntityMetadata, rawProperties, sourceDomain, summary, tags (+1 more)

### Community 89 - "library_1x2_grid_widget.dart"
Cohesion: 0.17
Nodes (11): bgColor, build, color, icon, _IconBadge, isDark, Library1x2GridWidget, moviesCount (+3 more)

### Community 92 - "State"
Cohesion: 0.14
Nodes (18): LatyrCaptureCard, _LatyrCaptureCardState, LatyrProgressiveBlur, _LatyrProgressiveBlurState, LatyrRichSummary, _LatyrRichSummaryState, _AppleTvSynopsis, _AppleTvSynopsisState (+10 more)

### Community 93 - "CaptureStreamController.java"
Cohesion: 0.22
Nodes (3): CaptureStreamController, HealthController, ProbeController

### Community 95 - "Intent"
Cohesion: 0.13
Nodes (13): ContentType, IMAGE, TEXT, URL, Intent, BUY, COOK, EXPLORE (+5 more)

### Community 96 - "UrlNormalizationService"
Cohesion: 0.17
Nodes (3): CreateCaptureRequest, UrlNormalizationService, UrlNormalizationServiceTest

### Community 100 - "capture_source_classifier.dart"
Cohesion: 0.25
Nodes (6): CaptureSourceClassifier, classify, extractFirstUrl, normalizeUrl, _trackingParams, _urlRegex

### Community 101 - "summary_lexer.dart"
Cohesion: 0.25
Nodes (5): _parseLinkTarget, stripMarkup, SummaryLexer, tokenize, _tokenRegex

### Community 102 - "SubscriptionQuotaService"
Cohesion: 0.15
Nodes (5): RevenueCatWebhookController, UserSubscriptionHistoryMapper, SubscriptionQuotaService, UserService, RevenueCatWebhookControllerTest

### Community 103 - "github_language_colors.dart"
Cohesion: 0.29
Nodes (5): _colors, formatCount, formatRelativeTime, GitHubLanguageColors, resolve

### Community 105 - "token_provider_test.dart"
Cohesion: 0.12
Nodes (10): _Auth, container, currentUser, error, getIdToken, isAnonymous, main, token (+2 more)

### Community 106 - "app_properties.dart"
Cohesion: 0.40
Nodes (3): AppProperties, enableTopBlur, enableTopTint

### Community 107 - "watch_provider_category.dart"
Cohesion: 0.40
Nodes (4): code, fromString, label, WatchProviderCategory

### Community 110 - "Latyr backend REST API / Latyr Flutter mobile application"
Cohesion: 0.29
Nodes (7): Java Spring Boot PostgreSQL backend stack, Flutter pub get run and widget tests, Latyr information capture application, Latyr backend REST API, Latyr Flutter mobile application, Maven wrapper backend run and tests, Flutter Riverpod Drift mobile stack

### Community 111 - "Orchestrated layered architecture / External adapter facades"
Cohesion: 0.47
Nodes (4): Thin controllers, Immutable internal DTO records, MyBatis explicit SQL, Services and orchestrators

### Community 136 - "pill_badge.dart"
Cohesion: 0.12
Nodes (14): AmbientBackgroundMode, AmbientMeshBackground, build, _buildDarkBackground, _buildLightBackground, child, mode, build (+6 more)

### Community 137 - "WeatherIntegrationClient"
Cohesion: 0.24
Nodes (5): ContextController, WeatherContextResponse, LocationData, WeatherData, WeatherIntegrationClient

### Community 138 - "floating_nav_island.dart"
Cohesion: 0.17
Nodes (9): build, _buildNavItem, currentIndex, FloatingNavIsland, icon, isSelected, label, _NavPill (+1 more)

### Community 139 - "summary_action_handler.dart"
Cohesion: 0.17
Nodes (10): _confirmReminder, handleAction, _handleGitHubAction, _handleMapsAction, _launchUriSafely, _launchWebUrl, _showReminderSheet, _showToast (+2 more)

### Community 140 - "apple_tv_badge.dart"
Cohesion: 0.18
Nodes (9): AppleTvBadge, AppleTvBadgeVariant, build, emoji, fontSize, icon, label, padding (+1 more)

### Community 143 - "streaming_branding.dart"
Cohesion: 0.18
Nodes (8): actionLabel, brandColor, icon, launchStreamingOrSearch, name, resolve, StreamingBrand, textColor

### Community 146 - "Document"
Cohesion: 0.17
Nodes (11): Apify Scraper, Document, Firebase Authentication, Flutter MVVM Riverpod Drift, Gemini Multimodal, Latyr Capture Understanding, MyBatis Explicit SQL, PostgreSQL Transactional Queue (+3 more)

### Community 147 - "color_extraction_service.dart"
Cohesion: 0.20
Nodes (7): clearCache, ColorExtractionService, extractDominantColor, getCachedColor, _inFlightCache, _performExtraction, _resolvedCache

### Community 153 - "Document"
Cohesion: 0.14
Nodes (13): Document, Dynamic Entity Enrichment, EntityDetailScreen, IMDb Destination Tile, Inline MORE Pill, JustWatch CDN Logos, LatyrExpandableText, Light Mode (+5 more)

### Community 161 - "org.slf4j.Logger"
Cohesion: 0.12
Nodes (11): AIProvider, CompositeEntityEnricher, EntityEnrichmentProvider, EphemeralMediaStreamer, ScraperProvider, ExtractedEntityMapper, FirebaseStorageService, IngestionPipelineService (+3 more)

## Knowledge Gaps
- **1069 isolated node(s):** `com.latyr:latyr-api`, `WATCH`, `OPEN_GITHUB`, `READ`, `COOK` (+1064 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1442 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **61 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WatchProviderCategory` connect `WatchProviderCategory` to `EntertainmentEntityEnricher.java`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **What connects `com.latyr:latyr-api`, `WATCH`, `OPEN_GITHUB` to the rest of the system?**
  _1069 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package:flutter/cupertino.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0563265306122449 - nodes in this community are weakly interconnected._
- **Why does `AuthenticatedUser` connect `AuthenticatedUser` to `instant`, `CaptureController.java`, `CaptureControllerTest.java`, `User`, `org.springframework.http.ResponseEntity`, `CaptureStreamController.java`, `org.springframework.stereotype.Component`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Should `ExtractedEntity` be split into smaller, more focused modules?**
  _Cohesion score 0.10409745293466224 - nodes in this community are weakly interconnected._
- **Why does `Capture` connect `Capture` to `Intent`, `NotificationLog`, `org.slf4j.Logger`, `CaptureServiceTest.java`, `.processJob`, `instant`, `CanonicalSource`, `CaptureMapper`, `ResurfacingScheduler.java`, `Uuid`, `.createUrlCapture`, `UserMapper`, `Intent`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._