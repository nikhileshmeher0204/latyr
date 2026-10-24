# Graph Report - latyr  (2026-10-23)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 3212 nodes · 6446 edges · 171 communities (107 shown, 64 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 744 edges (avg confidence: 0.85)
- Token usage: unmeasured (Codex semantic extraction; agent usage counters unavailable). No external model API calls.

## Graph Freshness
- Built from commit: `d71d192e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package:flutter/cupertino.dart / package:latyr_app/core/design/latyr_typography.dart
- api_client.dart
- app_database.g.dart / actualTableName
- entertainment_detail_screen.dart
- ActionCTA
- capture_detail_screen.dart / latyr_capture_card.dart
- Language
- sse_client.dart / api_client.dart
- CanonicalSource / SourceType
- latyr_colors.dart / amberBorder
- Capture / .processJob()
- ExtractedEntity / .processSinglePendingEntity()
- latyr_progressive_blur.dart / LatyrProgressiveBlur
- intent_detail_app_bar.dart / library_1x2_grid_widget.dart
- latyr_spacing.dart / base
- latyr_capture_card.dart
- entity_cards.dart / StatelessWidget
- org.springframework.stereotype.Component
- latyr_typography.dart / body
- app_colors.dart / alabaster
- home_screen.dart / _HomeScreenState
- capture_repository_test.dart
- latyr_rich_summary.dart / static const double
- UserSubscriptionHistory / .handleRevenueCatEvent()
- .testResurfacing_FridayNightWindow
- CaptureService.java
- search_screen.dart / library_screen.dart
- .createUrlCapture() / .testProcessJob_Success()
- entertainment_metadata.dart / awards
- filter_chip_bar.dart
- glass_card.dart / apple_tv_badge.dart
- CaptureResponse
- where_to_watch_card.dart / WhereToWatchCard
- JsonbTypeHandler.java / StringArrayTypeHandler.java
- .processJob
- UserCollection / UserCollectionMapper
- CaptureService
- User / .getOrProvisionUser()
- ApifyScraperAdapter
- org.junit.jupiter.api.Test / org.junit.jupiter.api.DisplayName
- org.springframework.context.annotation.Configuration
- V1__init_schema.sql / captures
- Live visual verification showcase / Latyr Flutter package manifest
- extracted_entity_model.dart / ExtractedEntityModel
- app.dart / floating_nav_island.dart
- CurrentUserArgumentResolver.java
- CaptureControllerTest.java
- share_intent_service.dart
- State
- github_repo_metadata.dart / audit
- GitHubEntityEnricher / .enrich()
- NotificationLog / .processUserResurfacing()
- dominant_color_service.dart / accent
- app_theme.dart / static const Color
- capture_providers.dart / _CaptureDetailScreenState
- com.fasterxml.jackson.databind.ObjectMapper / SecurityConfig.java
- UserMapper
- .buildEnrichedEntity() / StreamingPlatform
- UserSubscription / .createDefaultFreeSubscription()
- summary_token.dart / String get
- OmdbClient / OmdbMovieResponse
- FirebaseAuthFilter.java / PathNormalizationFilter.java
- AppDelegate / .application()
- CaptureCollection / CaptureCollectionMapper
- CaptureMapper / .getUserCaptures()
- capture_repository.dart
- GoogleGenAIConfig.java
- org.slf4j.Logger / GlobalExceptionHandler.java
- CdnAssetStorageProvider
- instant
- sync_service.dart / dart:async
- jakarta.servlet.http.HttpServletRequest / WeatherIntegrationClient
- AuthenticatedUser
- widget_test.dart
- Collection / .Collection()
- org.springframework.http.ResponseEntity
- place_metadata.dart / address
- TmdbClient / com.fasterxml.jackson.annotation.JsonIgnoreProperties
- capture_source_icon.dart / CustomPainter
- AsyncConfig.java
- app_switcher_scroll_physics.dart / app_switcher_scroll_physics_test.dart
- StreamingBrandCatalog
- latyr_expandable_text.dart / LatyrExpandableText
- book_metadata.dart
- recipe_metadata.dart
- home_providers.dart / apiClient
- AIEntity / DefaultEntityEnrichmentAdapter
- brand_registry.dart / brandColor
- collections_providers.dart
- MainActivity / .setIntent()
- generic_entity_metadata.dart / Map
- SseNotificationService
- LatyrException
- CaptureServiceTest.java
- Document
- RestGitHubClient / .searchRepositories()
- Document
- Document
- CollectionMapper / Select
- .resolveArgument() / .setUp()
- capture_source_classifier.dart / CaptureSourceClassifier
- summary_lexer.dart / static final RegExp
- org.junit.jupiter.api.BeforeEach
- PagedResponse
- github_language_colors.dart / static const Map
- Latyr backend REST API / Latyr Flutter mobile application
- Orchestrated layered architecture / External adapter facades
- JobStatus
- LocalCapture / LocalCapturesCompanion
- app_properties.dart / AppProperties
- watch_provider_category.dart / code
- library_1x2_grid_widget.dart
- TypographyContext / BuildContext
- iOS launch screen assets / Xcode asset catalog launch image customization
- environment_config.dart
- Flutter getting started resources / Latyr personal knowledge application
- Graphify query-first workflow
- PostgreSQL SKIP LOCKED worker queue
- Latryl home screen design reference
- Resolution provenance JSONB metadata
- Share extension 300ms local write target
- Stateless token authentication
- Java 21 virtual threads
- Dart Flutter DevTools extension settings
- com.latyr:latyr-api
- Document
- Latyr — Database Design & Physical Data Model (Low-Level Design)
- Latyr — Spring Boot Backend Architecture & Class Design (Low-Level Design)
- Latyr — REST API Specifications & Interface Contracts (Low-Level Design)
- Latyr — System Architecture Overview (High-Level Design)
- Latyr — Queue Worker & Ingestion Engine Design (Low-Level Design)
- Latyr — Flutter Mobile Client Architecture & Component Design (Low-Level Design)
- Document
- Document
- Latyr — Product Requirements Document (PRD)
- Latyr — Infrastructure & Unit Economics (High-Level Design)
- Latyr — Security, Privacy & Compliance (High-Level Design)
- Latyr — Data Flow & Processing Pipelines (High-Level Design)
- Instagram Reel Feasibility Report
- Latyr — Domain Models & High-Level Data Schema
- Document
- Drift SQLite
- String?
- RevenueCatWebhookController
- user_collections
- OmdbClient
- Flutter Drift Client

## God Nodes (most connected - your core abstractions)
1. `Capture` - 73 edges
2. `IngestionJob` - 43 edges
3. `ExtractedEntity` - 42 edges
4. `EntityType` - 36 edges
5. `User` - 36 edges
6. `TmdbClient` - 35 edges
7. `EntertainmentEntityEnricher` - 34 edges
8. `AuthenticatedUser` - 33 edges
9. `CaptureMapper` - 33 edges
10. `Language` - 32 edges

## Surprising Connections (you probably didn't know these)
- `CaptureController` --conceptually_related_to--> `CaptureController`  [INFERRED]
  05-implementation-roadmap/stage-03-ingestion-gateway-and-deduplication.md → latyr-api/src/main/java/com/latyr/api/controller/CaptureController.java
- `IngestionJob` --conceptually_related_to--> `IngestionJob`  [INFERRED]
  05-implementation-roadmap/stage-01-core-foundation-and-database.md → latyr-api/src/main/java/com/latyr/api/domain/model/IngestionJob.java
- `UserController` --conceptually_related_to--> `UserController`  [INFERRED]
  05-implementation-roadmap/stage-02-auth-and-user-management.md → latyr-api/src/main/java/com/latyr/api/controller/UserController.java
- `StreamingPlatform` --conceptually_related_to--> `StreamingPlatform`  [INFERRED]
  05-implementation-roadmap/stage-04-async-ingestion-engine.md → latyr-api/src/main/java/com/latyr/api/domain/enums/StreamingPlatform.java
- `GlobalExceptionHandler` --conceptually_related_to--> `GlobalExceptionHandler`  [INFERRED]
  05-implementation-roadmap/stage-01-core-foundation-and-database.md → latyr-api/src/main/java/com/latyr/api/exception/GlobalExceptionHandler.java

## Import Cycles
- None detected.

## Communities (171 total, 64 thin omitted)

### Community 0 - "package:flutter/cupertino.dart / package:latyr_app/core/design/latyr_typography.dart"
Cohesion: 0.03
Nodes (74): fromString, image, build, CaptureBannerWidget, onTap, build, categoryTag, ForYouCardWidget (+66 more)

### Community 1 - "api_client.dart"
Cohesion: 0.09
Nodes (15): ApiClient, AuthInterceptor, ApiClient, createCapture, dio, getCaptureDetail, getCaptures, getWeatherContext (+7 more)

### Community 2 - "app_database.g.dart / actualTableName"
Cohesion: 0.03
Nodes (91): _, actualTableName, _alias, aliasedName, allSchemaEntities, allTables, attachedDatabase, _audioTranscriptMeta (+83 more)

### Community 3 - "entertainment_detail_screen.dart"
Cohesion: 0.05
Nodes (36): ExtractedEntityMetadataX, ExtractedEntityModel, _AppleTvImdbLinkTile, _AppleTvImdbLinkTileState, _AppleTvSynopsis, _AppleTvSynopsisState, build, _buildDetailRow (+28 more)

### Community 4 - "ActionCTA"
Cohesion: 0.08
Nodes (19): ActionCTA, COOK, EXPLORE, OPEN_GITHUB, READ, REMEMBER, VISIT, WATCH (+11 more)

### Community 5 - "capture_detail_screen.dart / latyr_capture_card.dart"
Cohesion: 0.08
Nodes (24): apiClientProvider, appDatabaseProvider, build, _buildCaptureIntentsSection, _buildCardDecoration, _buildCuratedMediaCard, _buildMediaTextSection, _buildProcessingBanner (+16 more)

### Community 6 - "Language"
Cohesion: 0.05
Nodes (32): AIProvider, ApifyScraperAdapter, Document, EntertainmentEntityEnricher, ENTITY_ENRICHED SSE, EntityEnrichmentRetryWorker, Gemini 2.5 Flash, GoogleGenAIAdapter (+24 more)

### Community 7 - "sse_client.dart / api_client.dart"
Cohesion: 0.08
Nodes (19): _cancelToken, connect, data, _dio, disconnect, dispose, _eventController, events (+11 more)

### Community 8 - "CanonicalSource / SourceType"
Cohesion: 0.09
Nodes (8): SourceType, IMAGE, INSTAGRAM_REEL, WEB_URL, YOUTUBE_SHORT, YOUTUBE_VIDEO, CanonicalSource, CreateCaptureRequest

### Community 9 - "latyr_colors.dart / amberBorder"
Cohesion: 0.05
Nodes (42): amberBorder, amberFill, ambientHoney, ambientWarmGlow, ambientWheat, brandAmber, brandAmberDark, brandAmberLight (+34 more)

### Community 12 - "latyr_progressive_blur.dart / LatyrProgressiveBlur"
Cohesion: 0.05
Nodes (26): alwaysNeedsCompositing, begin, build, child, _configureShader, createRenderObject, createState, devicePixelRatio (+18 more)

### Community 13 - "intent_detail_app_bar.dart / library_1x2_grid_widget.dart"
Cohesion: 0.06
Nodes (29): captures, categoryName, color, icon, SubCategoryGroup, subCategoryName, build, parentCategoryColor (+21 more)

### Community 14 - "latyr_spacing.dart / base"
Cohesion: 0.05
Nodes (38): base, blurCard, blurNav, brLG, brMD, brPill, brSheet, brSM (+30 more)

### Community 15 - "latyr_capture_card.dart"
Cohesion: 0.10
Nodes (14): capture, cardColorFor, _cleanPreviewSummary, _computeIsDark, createState, didChangeDependencies, didUpdateWidget, _extractedColor (+6 more)

### Community 16 - "entity_cards.dart / StatelessWidget"
Cohesion: 0.06
Nodes (37): _DottedUnderlineText, _HandwrittenWavyText, EntertainmentDetailScreen, _MetascoreText, _RatingText, _RottenTomatoesText, _VibrantText, borderColor (+29 more)

### Community 17 - "org.springframework.stereotype.Component"
Cohesion: 0.15
Nodes (3): EphemeralMediaStreamer, GitHubSearchResultDTO, ResurfacingScheduler

### Community 18 - "latyr_typography.dart / body"
Cohesion: 0.05
Nodes (36): body, buttonLabel, callout, caption1, caption1Bold, caption2, caption2Bold, eyebrow (+28 more)

### Community 19 - "app_colors.dart / alabaster"
Cohesion: 0.05
Nodes (38): alabaster, alabasterBorder, alabasterGlass, amberBorder, amberGlow, amberSubtle, ambientHoney, ambientWarmGlow (+30 more)

### Community 20 - "home_screen.dart / _HomeScreenState"
Cohesion: 0.05
Nodes (42): captureListStreamProvider, captureRepositoryProvider, homeStatsProvider, weatherProvider, _buildAnimatedCard, _buildBar, _buildBarChart, _buildCircleButton (+34 more)

### Community 21 - "capture_repository_test.dart"
Cohesion: 0.11
Nodes (8): AppDatabase, CaptureRepository, db, main, db, main, repository, main

### Community 22 - "latyr_rich_summary.dart / static const double"
Cohesion: 0.05
Nodes (31): _amplitude, build, cardAccentColor, _clearRecognizers, color, createState, didUpdateWidget, dispose (+23 more)

### Community 23 - "UserSubscriptionHistory / .handleRevenueCatEvent()"
Cohesion: 0.09
Nodes (6): SubscriptionEventType, CANCELLATION, DOWNGRADE, RENEWAL, UPGRADE, UserSubscriptionHistory

### Community 25 - "CaptureService.java"
Cohesion: 0.16
Nodes (5): PlanTier, FREE, PRO, QuotaExceededException, ResourceNotFoundException

### Community 26 - "search_screen.dart / library_screen.dart"
Cohesion: 0.09
Nodes (14): _buildEmptyState, _buildEntityWidget, createState, _filters, _selectedFilterIndex, _buildEntityCard, createState, dispose (+6 more)

### Community 28 - "entertainment_metadata.dart / awards"
Cohesion: 0.06
Nodes (34): awards, backdropUrl, boxOffice, contentRating, country, director, durationOrSeasons, EntertainmentMetadata (+26 more)

### Community 29 - "filter_chip_bar.dart"
Cohesion: 0.05
Nodes (36): _confirmReminder, handleAction, _handleGitHubAction, _handleMapsAction, _launchUriSafely, _launchWebUrl, _showReminderSheet, _showToast (+28 more)

### Community 31 - "glass_card.dart / apple_tv_badge.dart"
Cohesion: 0.05
Nodes (39): AmbientBackgroundMode, AmbientMeshBackground, build, _buildDarkBackground, _buildLightBackground, child, mode, borderRadius (+31 more)

### Community 32 - "CaptureResponse"
Cohesion: 0.14
Nodes (4): CaptureController, EntityController, CaptureDetailResponse, CaptureResponse

### Community 33 - "where_to_watch_card.dart / WhereToWatchCard"
Cohesion: 0.04
Nodes (44): clearCache, ColorExtractionService, extractDominantColor, getCachedColor, _inFlightCache, _performExtraction, _resolvedCache, actionLabel (+36 more)

### Community 34 - "JsonbTypeHandler.java / StringArrayTypeHandler.java"
Cohesion: 0.16
Nodes (3): JsonbTypeHandler, StringArrayTypeHandler, UuidTypeHandler

### Community 37 - "CaptureService"
Cohesion: 0.13
Nodes (14): EntityEnrichmentProvider, ScraperProvider, CanonicalSourceMapper, ExtractedEntityMapper, IngestionJobMapper, CanonicalDeduplicationService, CaptureService, FcmService (+6 more)

### Community 39 - "ApifyScraperAdapter"
Cohesion: 0.28
Nodes (3): ApifyScraperAdapter, org.springframework.core.ParameterizedTypeReference<Map<String, Object>>, OgMetadata

### Community 40 - "org.junit.jupiter.api.Test / org.junit.jupiter.api.DisplayName"
Cohesion: 0.07
Nodes (9): MarkupSanitizer, UrlSourceClassifier, ApifyScraperAdapterTest, EphemeralMediaStreamerTest, FcmServiceTest, GoogleGenAIAdapterTest, LatyrApiApplicationTests, MarkupSanitizerTest (+1 more)

### Community 42 - "V1__init_schema.sql / captures"
Cohesion: 0.16
Nodes (24): notification_logs, user_subscriptions, canonical_sources, captures, extracted_entities, idx_canonical_sources_hash, idx_captures_resurface, idx_captures_user_status_created (+16 more)

### Community 43 - "Live visual verification showcase / Latyr Flutter package manifest"
Cohesion: 0.09
Nodes (21): Feature-First MVVM, Dynamic palette extraction and Brand Token Registry, Riverpod AsyncNotifier and StateNotifier, Pure stateless presentation renderers, Dart analyzer configuration, Flutter recommended analyzer lints, Flutter lint test and Drift build dependencies, Bundled icon assets (+13 more)

### Community 44 - "extracted_entity_model.dart / ExtractedEntityModel"
Cohesion: 0.08
Nodes (16): actionCta, book, description, entertainment, entityType, externalUrl, fromJson, generic (+8 more)

### Community 45 - "app.dart / floating_nav_island.dart"
Cohesion: 0.10
Nodes (13): build, _buildFloatingNavBar, _buildNavItem, createState, _currentIndex, dispose, initState, LatyrApp (+5 more)

### Community 47 - "CaptureControllerTest.java"
Cohesion: 0.18
Nodes (3): CaptureControllerTest, CaptureStreamControllerTest, UserControllerTest

### Community 48 - "share_intent_service.dart"
Cohesion: 0.17
Nodes (9): captureRepository, _channel, dispose, _extractUrl, _handleSharedText, _init, _lastHandledAt, _lastHandledUrl (+1 more)

### Community 49 - "State"
Cohesion: 0.16
Nodes (16): LatyrCaptureCard, _LatyrCaptureCardState, LatyrProgressiveBlur, _LatyrProgressiveBlurState, LatyrRichSummary, _LatyrRichSummaryState, _WatchProviderLogoButton, _WatchProviderLogoButtonState (+8 more)

### Community 50 - "github_repo_metadata.dart / audit"
Cohesion: 0.08
Nodes (24): audit, avatarUrl, defaultBranch, forks, forksFormatted, formatCount, fromMap, fullName (+16 more)

### Community 51 - "GitHubEntityEnricher / .enrich()"
Cohesion: 0.22
Nodes (7): GitHubEntityEnricher, GitHubRepoDetailsDTO, LicenseDTO, OwnerDTO, ItemDTO, GitHubClient, GitHubEntityEnricherTest

### Community 53 - "dominant_color_service.dart / accent"
Cohesion: 0.09
Nodes (19): accent, background, DominantPalette, extractDominantColor, extractPalette, fallback, getCachedPalette, getSeparatorColor (+11 more)

### Community 54 - "app_theme.dart / static const Color"
Cohesion: 0.09
Nodes (18): accent, AppTheme, background, border, cupertinoTheme, darkTheme, error, info (+10 more)

### Community 55 - "capture_providers.dart / _CaptureDetailScreenState"
Cohesion: 0.14
Nodes (14): authAttempted, client, db, repo, service, shareIntentServiceProvider, sseClientProvider, sync (+6 more)

### Community 57 - "UserMapper"
Cohesion: 0.11
Nodes (8): UserController, UserMapper, UserSubscriptionHistoryMapper, UserSubscriptionMapper, SubscriptionQuotaService, UserService, RevenueCatWebhookControllerTest, SubscriptionQuotaServiceTest

### Community 58 - ".buildEnrichedEntity() / StreamingPlatform"
Cohesion: 0.09
Nodes (11): EntertainmentEntityEnricher, StreamingPlatform, APPLE_TV, DISNEY_HOTSTAR, NETFLIX, OTHER, PRIME_VIDEO, SONY_LIV (+3 more)

### Community 61 - "summary_token.dart / String get"
Cohesion: 0.10
Nodes (17): actionPayload, actionScheme, actionType, hashCode, highlight, icon3d, iconName, italic (+9 more)

### Community 62 - "OmdbClient / OmdbMovieResponse"
Cohesion: 0.22
Nodes (4): OmdbClient, OmdbMovieResponse, OmdbRating, collections

### Community 63 - "FirebaseAuthFilter.java / PathNormalizationFilter.java"
Cohesion: 0.13
Nodes (3): PathNormalizationFilter, PathNormalizationFilter, HttpServletRequestWrapper

### Community 64 - "AppDelegate / .application()"
Cohesion: 0.12
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 67 - "capture_repository.dart"
Cohesion: 0.12
Nodes (14): apiClient, captureUrl, checkProcessingCaptures, db, dispose, fetchRemoteFeed, hasActiveProcessingCaptures, _initSseListener (+6 more)

### Community 68 - "GoogleGenAIConfig.java"
Cohesion: 0.12
Nodes (3): GoogleGenAIConfig, JacksonConfig, FirebaseConfig

### Community 69 - "org.slf4j.Logger / GlobalExceptionHandler.java"
Cohesion: 0.20
Nodes (3): ErrorResponse, ErrorResponse, GlobalExceptionHandler

### Community 72 - "sync_service.dart / dart:async"
Cohesion: 0.13
Nodes (9): captureRepository, _connectivity, dispose, _feedSyncTimer, _processingTimer, _startListening, _startTimers, _subscription (+1 more)

### Community 73 - "jakarta.servlet.http.HttpServletRequest / WeatherIntegrationClient"
Cohesion: 0.25
Nodes (5): ContextController, WeatherContextResponse, LocationData, WeatherData, WeatherIntegrationClient

### Community 75 - "widget_test.dart"
Cohesion: 0.14
Nodes (6): SseClient, main, connect, dispose, main, _NoOpSseClient

### Community 77 - "org.springframework.http.ResponseEntity"
Cohesion: 0.14
Nodes (3): AuthController, UserProfileResponse, CurrentUser

### Community 78 - "place_metadata.dart / address"
Cohesion: 0.12
Nodes (15): address, city, country, fromMap, latitude, location, longitude, mapsUrl (+7 more)

### Community 79 - "TmdbClient / com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.21
Nodes (15): TmdbCast, TmdbClient, TmdbCountryWatchProviders, TmdbCredits, TmdbCrew, TmdbExternalIds, TmdbGenre, TmdbItem (+7 more)

### Community 80 - "capture_source_icon.dart / CustomPainter"
Cohesion: 0.14
Nodes (13): CaptureSource, build, CaptureSourceIcon, color, _InstagramGlyphPainter, paint, shouldRepaint, size (+5 more)

### Community 82 - "app_switcher_scroll_physics.dart / app_switcher_scroll_physics_test.dart"
Cohesion: 0.13
Nodes (8): applyPhysicsToUserOffset, applyTo, AppSwitcherScrollPhysics, createBallisticSimulation, _kOverScrollSpring, minFlickVelocity, velocityPerCard, main

### Community 83 - "StreamingBrandCatalog"
Cohesion: 0.22
Nodes (3): BrandMetadata, StreamingBrandCatalog, AssetStorageProvider

### Community 84 - "latyr_expandable_text.dart / LatyrExpandableText"
Cohesion: 0.14
Nodes (13): LatyrExpandableText, LatyrExpandableText, RoundedTextStyle, animationDuration, build, createState, _isExpanded, LatyrExpandableText (+5 more)

### Community 85 - "book_metadata.dart"
Cohesion: 0.14
Nodes (12): author, BookMetadata, buyUrl, coverUrl, fromMap, genres, isbn, overview (+4 more)

### Community 86 - "recipe_metadata.dart"
Cohesion: 0.14
Nodes (13): calories, cookTime, cuisine, difficulty, fromMap, imageUrl, ingredients, instructions (+5 more)

### Community 87 - "home_providers.dart / apiClient"
Cohesion: 0.14
Nodes (13): apiClient, capturesToday, categoriesDiscovered, city, condition, db, fromJson, HomeStats (+5 more)

### Community 88 - "AIEntity / DefaultEntityEnrichmentAdapter"
Cohesion: 0.17
Nodes (5): AIEntity, DefaultEntityEnrichmentAdapter, CompositeEntityEnricher, EntityEnricher, DefaultEntityEnrichmentAdapterTest

### Community 89 - "brand_registry.dart / brandColor"
Cohesion: 0.15
Nodes (12): brandColor, BrandRegistry, BrandToken, colorFromHex, iconColor, logoUrl, name, resolve (+4 more)

### Community 90 - "collections_providers.dart"
Cohesion: 0.07
Nodes (23): CollectionsScreen, build, CategoryGroup, build, CategoryDetailScreen, categoryGroup, captures, capturesAsync (+15 more)

### Community 92 - "generic_entity_metadata.dart / Map"
Cohesion: 0.17
Nodes (9): category, confidenceScore, fromMap, GenericEntityMetadata, rawProperties, sourceDomain, summary, tags (+1 more)

### Community 93 - "SseNotificationService"
Cohesion: 0.20
Nodes (4): CaptureStreamController, HealthController, SseNotificationService, SseNotificationServiceTest

### Community 95 - "CaptureServiceTest.java"
Cohesion: 0.11
Nodes (17): CaptureStatus, COMPLETED, FAILED, PENDING, PROCESSING, ContentType, IMAGE, TEXT (+9 more)

### Community 97 - "Document"
Cohesion: 0.23
Nodes (11): SyncService, AppDatabase, Document, FcmService, GoRouter, LocalCaptures, Riverpod ProviderScope, Shared App Group Database (+3 more)

### Community 99 - "Document"
Cohesion: 0.39
Nodes (7): Cache Miss Job, CanonicalSourceService, Capture Retrieval, CaptureController, Document, Screenshot SHA256, URL Normalization

### Community 100 - "Document"
Cohesion: 0.43
Nodes (6): Document, FcmService, ResurfacingScheduler, RevenueCatWebhookController, Silent Sync Notification, Subscription Audit History

### Community 104 - "capture_source_classifier.dart / CaptureSourceClassifier"
Cohesion: 0.25
Nodes (6): CaptureSourceClassifier, classify, extractFirstUrl, normalizeUrl, _trackingParams, _urlRegex

### Community 105 - "summary_lexer.dart / static final RegExp"
Cohesion: 0.25
Nodes (5): _parseLinkTarget, stripMarkup, SummaryLexer, tokenize, _tokenRegex

### Community 109 - "github_language_colors.dart / static const Map"
Cohesion: 0.29
Nodes (5): _colors, formatCount, formatRelativeTime, GitHubLanguageColors, resolve

### Community 110 - "Latyr backend REST API / Latyr Flutter mobile application"
Cohesion: 0.29
Nodes (7): Java Spring Boot PostgreSQL backend stack, Flutter pub get run and widget tests, Latyr information capture application, Latyr backend REST API, Latyr Flutter mobile application, Maven wrapper backend run and tests, Flutter Riverpod Drift mobile stack

### Community 111 - "Orchestrated layered architecture / External adapter facades"
Cohesion: 0.47
Nodes (4): Thin controllers, Immutable internal DTO records, MyBatis explicit SQL, Services and orchestrators

### Community 112 - "JobStatus"
Cohesion: 0.15
Nodes (5): JobStatus, COMPLETED, FAILED, PENDING, PROCESSING

### Community 115 - "app_properties.dart / AppProperties"
Cohesion: 0.40
Nodes (3): AppProperties, enableTopBlur, enableTopTint

### Community 116 - "watch_provider_category.dart / code"
Cohesion: 0.40
Nodes (4): code, fromString, label, WatchProviderCategory

### Community 117 - "library_1x2_grid_widget.dart"
Cohesion: 0.17
Nodes (11): bgColor, build, color, icon, _IconBadge, isDark, Library1x2GridWidget, moviesCount (+3 more)

### Community 121 - "environment_config.dart"
Cohesion: 0.18
Nodes (7): cdnBaseUrl, environment, EnvironmentConfig, isLocal, isProd, isUat, _rawApiUrl

### Community 146 - "Document"
Cohesion: 0.09
Nodes (21): Backend Stages, Document, Mobile Stages, Document, Flyway Migrations, GlobalExceptionHandler, IngestionJob, JPA Domain Entities (+13 more)

### Community 147 - "Latyr — Database Design & Physical Data Model (Low-Level Design)"
Cohesion: 0.09
Nodes (12): captures, Enrichment Queue Index, extracted_entities, Flyway, ingestion_jobs, JSONB GIN Index, Latyr — Database Design & Physical Data Model (Low-Level Design), user_subscription_history (+4 more)

### Community 148 - "Latyr — Spring Boot Backend Architecture & Class Design (Low-Level Design)"
Cohesion: 0.11
Nodes (16): AIProvider, ApifyScraperAdapter, CaptureMapper, EntertainmentEntityEnricher, ExtractedEntityMapper, GoogleGenAIAdapter, IngestionPipelineService, IngestionQueueWorker (+8 more)

### Community 149 - "Latyr — REST API Specifications & Interface Contracts (Low-Level Design)"
Cohesion: 0.07
Nodes (11): Capture Detail Endpoint, Entity Edit Endpoint, ENTITY_ENRICHED, Firebase Bearer Token, Image Upload Endpoint, Latyr — REST API Specifications & Interface Contracts (Low-Level Design), List Captures Endpoint, RevenueCat Webhook (+3 more)

### Community 150 - "Latyr — System Architecture Overview (High-Level Design)"
Cohesion: 0.14
Nodes (11): Apify Adapter, Canonical URL Deduplication, Capture Ingestion Service, ErrorResponse, Gemini 2.5 Flash, GlobalExceptionHandler, Ingestion Pipeline Worker, Latyr — System Architecture Overview (High-Level Design) (+3 more)

### Community 151 - "Latyr — Queue Worker & Ingestion Engine Design (Low-Level Design)"
Cohesion: 0.09
Nodes (13): Apify Reel Scraper, Entity Metadata JSONB, Ephemeral Audio Buffer, Exponential Backoff, GitHub Enrichment, Immediate Async Trigger, Ingestion Job State Machine, Latyr — Queue Worker & Ingestion Engine Design (Low-Level Design) (+5 more)

### Community 152 - "Latyr — Flutter Mobile Client Architecture & Component Design (Low-Level Design)"
Cohesion: 0.12
Nodes (14): AppDatabase, CaptureCardWidget, CaptureFeedScreen, CaptureListController, CaptureModel, DominantColorService, EntityDetailScreen, Latyr — Flutter Mobile Client Architecture & Component Design (Low-Level Design) (+6 more)

### Community 153 - "Document"
Cohesion: 0.12
Nodes (21): Document, Dynamic Entity Enrichment, EntityDetailScreen, Inline MORE Pill, JustWatch CDN Logos, Light Mode, Magazine Design Language, Pixel 9 UAT Verification (+13 more)

### Community 154 - "Document"
Cohesion: 0.18
Nodes (12): Android Share Target, CaptureCardWidget, CaptureFeedScreen, CaptureListController, Document, GitHubRepoCardWidget, iOS Share Extension, MovieShowCardWidget (+4 more)

### Community 155 - "Latyr — Product Requirements Document (PRD)"
Cohesion: 0.09
Nodes (8): Drift SQLite, ENTITY_ENRICHED, EntityDetailScreen, Hybrid Enrichment Engine, Latyr — Product Requirements Document (PRD), Native Share Extension, OMDb, TMDB

### Community 156 - "Latyr — Infrastructure & Unit Economics (High-Level Design)"
Cohesion: 0.13
Nodes (13): Apify API, Async Worker Fleet, Blended Capture Cost, Canonical URL Deduplication, FCM, Latyr — Infrastructure & Unit Economics (High-Level Design), Object Storage, PostgreSQL (+5 more)

### Community 157 - "Latyr — Security, Privacy & Compliance (High-Level Design)"
Cohesion: 0.13
Nodes (8): AuthenticatedUser, Derived Text in PostgreSQL, Firebase Authentication, Gemini 2.5 Flash, IMDb Attribution Policy, Latyr — Security, Privacy & Compliance (High-Level Design), RevenueCat, SecurityContextHolder

### Community 158 - "Latyr — Data Flow & Processing Pipelines (High-Level Design)"
Cohesion: 0.14
Nodes (10): Canonical URL Cache, Drift Revalidation, EntityEnrichmentRetryWorker, Ephemeral Audio Buffer, Gemini 2.5 Flash, Latyr — Data Flow & Processing Pipelines (High-Level Design), OMDb Exact IMDb Lookup, SSE ENTITY_ENRICHED (+2 more)

### Community 159 - "Instagram Reel Feasibility Report"
Cohesion: 0.15
Nodes (7): Apify Instagram Scraper, Caption Only Fallback, Gemini 1.5 Flash, Hinglish Whisper, Instagram oEmbed, Instagram Reel Feasibility Report, Visual Bookmark Fallback

### Community 160 - "Latyr — Domain Models & High-Level Data Schema"
Cohesion: 0.21
Nodes (12): canonical_sources, capture_collections, captures, extracted_entities, Gemini 2.5 Flash, Latyr — Domain Models & High-Level Data Schema, OMDb, TMDB (+4 more)

### Community 162 - "Document"
Cohesion: 0.39
Nodes (8): AuthenticatedUser, Document, Firebase Token Verification, FirebaseAuthFilter, QuotaExceededException, SubscriptionQuotaService, User Auto Provisioning, UserController

### Community 164 - "Drift SQLite"
Cohesion: 0.50
Nodes (4): CaptureDetailScreen, Drift SQLite, FCM Background Handler, CaptureDetailScreen

### Community 166 - "String?"
Cohesion: 0.22
Nodes (7): author, context, fromMap, QuoteMetadata, quoteText, sourceWork, year

### Community 168 - "user_collections"
Cohesion: 0.40
Nodes (6): capture_collections, collections, user_collections, capture_collections, update_user_collections_modtime, user_collections

### Community 169 - "OmdbClient"
Cohesion: 0.50
Nodes (4): EntityEnrichmentRetryWorker, OmdbClient, SSE ENTITY_ENRICHED, TmdbClient

### Community 170 - "Flutter Drift Client"
Cohesion: 0.67
Nodes (3): Firebase Auth, Flutter Drift Client, Native Share Extension

## Knowledge Gaps
- **1075 isolated node(s):** `fromString`, `image`, `build`, `onTap`, `build` (+1070 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1574 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **64 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WatchProviderCategory` connect `Language` to `StreamingBrandCatalog`, `EntertainmentEntityEnricher.java`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **What connects `fromString`, `image`, `build` to the rest of the system?**
  _1075 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package:flutter/cupertino.dart / package:latyr_app/core/design/latyr_typography.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03135964912280702 - nodes in this community are weakly interconnected._
- **Why does `AppDatabase` connect `capture_repository_test.dart` to `Document`, `app_database.g.dart / actualTableName`, `capture_repository.dart`, `capture_providers.dart / _CaptureDetailScreenState`, `Latyr — Flutter Mobile Client Architecture & Component Design (Low-Level Design)`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Should `api_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.09486166007905138 - nodes in this community are weakly interconnected._
- **Why does `collections` connect `OmdbClient / OmdbMovieResponse` to `RestGitHubClient / .searchRepositories()`, `user_collections`, `AuthenticatedUser`, `org.junit.jupiter.api.BeforeEach`, `V1__init_schema.sql / captures`, `TmdbClient / com.fasterxml.jackson.annotation.JsonIgnoreProperties`, `GitHubEntityEnricher / .enrich()`, `AIEntity / DefaultEntityEnrichmentAdapter`, `.buildEnrichedEntity() / StreamingPlatform`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Should `app_database.g.dart / actualTableName` be split into smaller, more focused modules?**
  _Cohesion score 0.029290206648697213 - nodes in this community are weakly interconnected._

## Scope and limitations

Combined Latyr monorepo and C:/Users/nikhi/GitHub/latyr-docs: 242 code files scanned and all 31 documentation/configuration files read completely. Screenshots and media were excluded. Seven code/build/header files yielded no symbols. The repo tag `repo` identifies Latyr; `latyr-docs` identifies the documentation repository.

77 documentation-to-code bridges match a documented name to a unique source-backed AST symbol. They are INFERRED (confidence 0.85); they do not establish that historical specifications match current behavior.

Graph health warning: the raw monorepo extraction has 461 dangling-endpoint relationships, one missing-endpoint relationship, five self-loops, and 1,102 same-endpoint relationships subject to collapse in a directed graph. The documentation extraction has two dangling-endpoint relationships. Graphify may normalize or synthesize endpoints during build. Consult GRAPH_HEALTH.txt and the preserved raw .graphify_extract.json files for detail. This is a navigation aid with incomplete relationship coverage.

Generated graphify-out/ files are in the working trees and have not been committed. Semantic token usage is unavailable, rather than zero.
