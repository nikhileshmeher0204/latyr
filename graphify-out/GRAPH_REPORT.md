# Graph Report - latyr  (2026-10-24)

## Corpus Check
- 291 files · ~1,710,800 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 57 file(s) not represented in the graph (top: (none) 9, .properties 8, .xml 7)

## Summary
- 3505 nodes · 7542 edges · 161 communities (90 shown, 71 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 896 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a3f41dc7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package:flutter/cupertino.dart
- ExtractedEntity
- app_database.dart
- app_database.g.dart
- EntityType
- auth_providers.dart
- DurableIngestionPostgresTest.java
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
- TmdbClient
- latyr_typography.dart
- app_colors.dart
- latyr_rich_summary.dart
- EntertainmentEntityEnricher
- entertainment_metadata.dart
- UserSubscriptionHistory
- sse_auth_test.dart
- .processJob
- filter_chip_bar.dart
- Capture
- Uuid
- app_auth_boundary_test.dart
- capture_repository.dart
- IngestionJob
- NotificationLog
- JsonbTypeHandler.java
- WatchProviderCategory
- UserCollection
- home_screen.dart
- sse_client.dart
- SseNotificationService
- LatyrApiApplicationTests.java
- TmdbCatalog
- java.util.Map
- Live visual verification showcase / Latyr Flutter package manifest
- capture_repository_test.dart
- V1__init_schema.sql
- auth_gateway.dart
- CaptureControllerTest.java
- extracted_entity_model.dart
- User
- share_intent_service.dart
- intent_detail_app_bar.dart
- github_repo_metadata.dart
- AuthenticatedUser
- CaptureQuotaLedger
- dominant_color_service.dart
- org.springframework.context.annotation.Bean
- FirebaseSecurityChainTest.java
- UrlNormalizationService
- org.springframework.stereotype.Component
- app_theme.dart
- OmdbCatalog
- UserMapper
- org.springframework.stereotype.Component
- Intent
- summary_token.dart
- CaptureCollection
- app_auth_boundary_test.dart
- GoogleGenAIConfig.java
- AppDelegate
- UserSubscription
- firebase_auth_gateway_test.dart
- AIEntity
- ProviderOperationException
- CaptureMapper
- fake_auth_gateway.dart
- Collection
- place_metadata.dart
- capture_source_icon.dart
- app_switcher_scroll_physics.dart
- .claim
- latyr_expandable_text.dart
- IngestionOutboxEvent
- .extractMedia
- PostgresTestDatabase
- brand_registry.dart
- app.dart
- List
- UserSubscriptionMapper
- DurableIngestionStore
- entertainment_detail_screen.dart
- CaptureAdmissionPostgresTest
- EntertainmentEntityEnricher
- .createUrlCapture
- CollectionMapper
- capture_source_classifier.dart
- IngestionPipelinePostgresTest
- SubscriptionQuotaService
- github_language_colors.dart
- LocalCapture
- token_provider_test.dart
- app_properties.dart
- watch_provider_category.dart
- org.junit.jupiter.api.Test
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
- sync_service.dart
- WeatherIntegrationClient
- UserService
- StreamingBrandCatalog
- SecurityConfig.java
- Dart Flutter DevTools extension settings
- dart:async
- Language
- RemovedDiagnosticRoutesTest.java
- Document
- CurrentUserArgumentResolver
- UrlSourceClassifier
- Intent
- IngestionStageCheckpoint
- .findByCanonicalUrlHash
- Document
- JobStatus
- TypographyContext
- org.slf4j.Logger

## God Nodes (most connected - your core abstractions)
1. `IngestionJob` - 89 edges
2. `Capture` - 74 edges
3. `ExtractedEntity` - 43 edges
4. `AIEntity` - 39 edges
5. `EntityType` - 39 edges
6. `CanonicalSource` - 37 edges
7. `User` - 36 edges
8. `UserSubscription` - 35 edges
9. `ProviderOperationException` - 34 edges
10. `EntertainmentEntityEnricher` - 33 edges

## Surprising Connections (you probably didn't know these)
- `Latyr owned progressive blur fragment shader` --semantically_similar_to--> `Pure progressive blur cinema hero architecture`  [INFERRED] [semantically similar]
  latyr-app/pubspec.yaml → VISUAL_VERIFICATION_SHOWCASE.md
- `main()` --calls--> `ShareDeliveryState`  [INFERRED]
  latyr-app/android/app/src/test/kotlin/com/latyr/latyr_app/ShareDeliveryStateCheck.kt → latyr-app/android/app/src/main/kotlin/com/latyr/latyr_app/ShareDeliveryState.kt
- `Flutter runtime dependency catalog` --references--> `Riverpod AsyncNotifier and StateNotifier`  [EXTRACTED]
  latyr-app/pubspec.yaml → AGENTS.md
- `Flutter runtime dependency catalog` --references--> `Offline-first Drift SQLite caching`  [EXTRACTED]
  latyr-app/pubspec.yaml → AGENTS.md
- `IngestionPipelineService` --references--> `AIProvider`  [EXTRACTED]
  latyr-api/src/main/java/com/latyr/api/service/IngestionPipelineService.java → latyr-api/src/main/java/com/latyr/api/adapter/AIProvider.java

## Import Cycles
- None detected.

## Communities (161 total, 71 thin omitted)

### Community 0 - "package:flutter/cupertino.dart"
Cohesion: 0.03
Nodes (67): fromString, image, rootCollectionsProvider, build, CollectionsScreen, build, CaptureBannerWidget, onTap (+59 more)

### Community 2 - "app_database.dart"
Cohesion: 0.04
Nodes (39): copyWithCompanion, _entitiesJsonMeta, _idMeta, _originalCaptionMeta, _summaryMeta, accountDatabaseFileName, audioTranscript, category (+31 more)

### Community 3 - "app_database.g.dart"
Cohesion: 0.04
Nodes (53): _, actualTableName, _alias, aliasedName, allSchemaEntities, allTables, attachedDatabase, _audioTranscriptMeta (+45 more)

### Community 4 - "EntityType"
Cohesion: 0.08
Nodes (22): AIProvider, GoogleGenAIAdapter, TypeReference<Map<String, Object>>, ActionCTA, COOK, EXPLORE, OPEN_GITHUB, READ (+14 more)

### Community 5 - "auth_providers.dart"
Cohesion: 0.07
Nodes (25): _accessEpoch, _actionInFlight, AuthController, authGatewayProvider, AuthPhase, AuthState, dispose, errorMessage (+17 more)

### Community 6 - "DurableIngestionPostgresTest.java"
Cohesion: 0.13
Nodes (6): AnalysisOutcomeUnknownException, IngestionLeaseLostException, IngestionOutboxMapper, IngestionEventOutbox, IngestionOutboxWorker, DurableIngestionMigrationPostgresTest

### Community 7 - "glass_card.dart"
Cohesion: 0.04
Nodes (40): AppleTvBadge, AppleTvBadgeVariant, build, emoji, fontSize, icon, label, padding (+32 more)

### Community 8 - "capture_detail_screen.dart"
Cohesion: 0.04
Nodes (45): build, capture, cardColorFor, _cleanPreviewSummary, _computeIsDark, createState, didChangeDependencies, didUpdateWidget (+37 more)

### Community 9 - "CanonicalSource"
Cohesion: 0.10
Nodes (7): SourceType, IMAGE, INSTAGRAM_REEL, WEB_URL, YOUTUBE_SHORT, YOUTUBE_VIDEO, CanonicalSource

### Community 10 - "collections_providers.dart"
Cohesion: 0.06
Nodes (25): SubCategoryGroup, build, CategoryDetailScreen, categoryGroup, captures, capturesAsync, cat, categoryCaptures (+17 more)

### Community 11 - "latyr_colors.dart"
Cohesion: 0.05
Nodes (42): amberBorder, amberFill, ambientHoney, ambientWarmGlow, ambientWheat, brandAmber, brandAmberDark, brandAmberLight (+34 more)

### Community 12 - "latyr_progressive_blur.dart"
Cohesion: 0.05
Nodes (26): alwaysNeedsCompositing, begin, build, child, _configureShader, createRenderObject, createState, devicePixelRatio (+18 more)

### Community 13 - "search_screen.dart"
Cohesion: 0.07
Nodes (24): captureListStreamProvider, _buildOverlappingFeed, build, _buildEmptyState, _buildEntityWidget, createState, _filters, LibraryScreen (+16 more)

### Community 14 - "latyr_spacing.dart"
Cohesion: 0.05
Nodes (38): base, blurCard, blurNav, brLG, brMD, brPill, brSheet, brSM (+30 more)

### Community 15 - "entity_cards.dart"
Cohesion: 0.04
Nodes (53): _DottedUnderlineText, _HandwrittenWavyText, EntertainmentDetailScreen, _MaturityBadge, _MetascoreText, _RatingText, _VibrantText, borderColor (+45 more)

### Community 16 - "github_repo_detail_screen.dart"
Cohesion: 0.03
Nodes (54): clearCache, ColorExtractionService, extractDominantColor, getCachedColor, _inFlightCache, _performExtraction, _resolvedCache, build (+46 more)

### Community 17 - "TmdbClient"
Cohesion: 0.07
Nodes (26): GitHubEntityEnricher, GitHubRepoDetailsDTO, LicenseDTO, OwnerDTO, ItemDTO, GitHubClient, OmdbClient, OmdbMovieResponse (+18 more)

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
Cohesion: 0.13
Nodes (10): StreamingPlatform, APPLE_TV, DISNEY_HOTSTAR, NETFLIX, OTHER, PRIME_VIDEO, SONY_LIV, THEATRICAL (+2 more)

### Community 22 - "entertainment_metadata.dart"
Cohesion: 0.06
Nodes (34): awards, backdropUrl, boxOffice, contentRating, country, director, durationOrSeasons, EntertainmentMetadata (+26 more)

### Community 23 - "UserSubscriptionHistory"
Cohesion: 0.09
Nodes (6): SubscriptionEventType, CANCELLATION, DOWNGRADE, RENEWAL, UPGRADE, UserSubscriptionHistory

### Community 25 - "sse_auth_test.dart"
Cohesion: 0.06
Nodes (28): ApiClient, createCapture, dio, getCaptureDetail, getCaptures, getWeatherContext, updateEntity, uploadImageCapture (+20 more)

### Community 26 - ".processJob"
Cohesion: 0.10
Nodes (7): AIAnalysisResult, ScrapedMedia, ScraperProvider, CaptureAnalysisCodec, CaptureSuccessPolicy, CaptureSuccessPolicyTest, IngestionPipelineServiceTest

### Community 27 - "filter_chip_bar.dart"
Cohesion: 0.05
Nodes (39): _confirmReminder, handleAction, _handleGitHubAction, _handleMapsAction, _launchUriSafely, _launchWebUrl, _showReminderSheet, _showToast (+31 more)

### Community 28 - "Capture"
Cohesion: 0.13
Nodes (5): ContentType, IMAGE, TEXT, URL, Capture

### Community 29 - "Uuid"
Cohesion: 0.11
Nodes (6): PlanTier, FREE, PRO, ResourceNotFoundException, CanonicalSourceMapper, CanonicalDeduplicationService

### Community 30 - "app_auth_boundary_test.dart"
Cohesion: 0.09
Nodes (16): FirebaseAuthGateway, AuthGateway, AuthSession, changes, current, _Gateway, initialize, setSession (+8 more)

### Community 31 - "capture_repository.dart"
Cohesion: 0.08
Nodes (22): SseClient, apiClient, captureUrl, checkProcessingCaptures, db, dispose, _disposed, fetchRemoteFeed (+14 more)

### Community 34 - "JsonbTypeHandler.java"
Cohesion: 0.16
Nodes (3): JsonbTypeHandler, StringArrayTypeHandler, UuidTypeHandler

### Community 35 - "WatchProviderCategory"
Cohesion: 0.15
Nodes (5): WatchProviderCategory, BUY, FLATRATE, FREE, RENT

### Community 37 - "home_screen.dart"
Cohesion: 0.04
Nodes (51): captureRepositoryProvider, shareIntentServiceProvider, apiClient, capturesToday, categoriesDiscovered, city, condition, db (+43 more)

### Community 38 - "sse_client.dart"
Cohesion: 0.08
Nodes (22): _cancelToken, connect, _connectionGeneration, data, _dio, disconnect, dispose, _eventController (+14 more)

### Community 41 - "TmdbCatalog"
Cohesion: 0.15
Nodes (14): TmdbCast, TmdbCatalog, TmdbCountryWatchProviders, TmdbCredits, TmdbCrew, TmdbExternalIds, TmdbGenre, TmdbItem (+6 more)

### Community 43 - "Live visual verification showcase / Latyr Flutter package manifest"
Cohesion: 0.09
Nodes (21): Feature-First MVVM, Dynamic palette extraction and Brand Token Registry, Riverpod AsyncNotifier and StateNotifier, Pure stateless presentation renderers, Dart analyzer configuration, Flutter recommended analyzer lints, Flutter lint test and Drift build dependencies, Bundled icon assets (+13 more)

### Community 44 - "capture_repository_test.dart"
Cohesion: 0.09
Nodes (20): AppDatabase, _FeedAdapter, calls, close, db, fetch, getCaptureById, main (+12 more)

### Community 45 - "V1__init_schema.sql"
Cohesion: 0.11
Nodes (36): canonical_sources, capture_collections, captures, extracted_entities, idx_canonical_sources_hash, idx_captures_resurface, idx_captures_user_status_created, idx_extracted_entities_metadata_gin (+28 more)

### Community 46 - "auth_gateway.dart"
Cohesion: 0.11
Nodes (14): AuthenticationRequiredException, toString, AuthFailure, AuthFailureKind, initialize, isSupported, kind, message (+6 more)

### Community 47 - "CaptureControllerTest.java"
Cohesion: 0.08
Nodes (6): PagedResponse, PageMetadata, CaptureControllerTest, HandlerMethodArgumentResolver, CaptureStreamControllerTest, CurrentUserArgumentResolver

### Community 48 - "extracted_entity_model.dart"
Cohesion: 0.08
Nodes (18): actionCta, book, description, entertainment, entityType, externalUrl, ExtractedEntityMetadataX, ExtractedEntityModel (+10 more)

### Community 50 - "share_intent_service.dart"
Cohesion: 0.08
Nodes (16): cdnBaseUrl, environment, EnvironmentConfig, isLocal, isProd, isUat, _rawApiUrl, _channel (+8 more)

### Community 51 - "intent_detail_app_bar.dart"
Cohesion: 0.09
Nodes (18): actions, backIcon, build, buildActionButton, enableBlur, IntentDetailAppBar, isDark, onBack (+10 more)

### Community 52 - "github_repo_metadata.dart"
Cohesion: 0.05
Nodes (36): author, BookMetadata, buyUrl, coverUrl, fromMap, genres, isbn, overview (+28 more)

### Community 53 - "AuthenticatedUser"
Cohesion: 0.09
Nodes (8): CaptureController, EntityController, CaptureDetailResponse, ExtractedEntityResponse, UpdateEntityRequest, AuthenticatedUser, CurrentUser, CaptureService

### Community 54 - "CaptureQuotaLedger"
Cohesion: 0.10
Nodes (3): CaptureQuotaReservation, CaptureQuotaLedgerMapper, CaptureQuotaLedger

### Community 55 - "dominant_color_service.dart"
Cohesion: 0.09
Nodes (20): accent, background, DominantColorService, DominantPalette, extractDominantColor, extractPalette, fallback, getCachedPalette (+12 more)

### Community 56 - "org.springframework.context.annotation.Bean"
Cohesion: 0.10
Nodes (4): AsyncConfig, JacksonConfig, LatyrApiApplication, TestConfiguration

### Community 60 - "app_theme.dart"
Cohesion: 0.09
Nodes (18): accent, AppTheme, background, border, cupertinoTheme, darkTheme, error, info (+10 more)

### Community 61 - "OmdbCatalog"
Cohesion: 0.18
Nodes (3): OmdbCatalog, OmdbMovieResponse, OmdbRating

### Community 62 - "UserMapper"
Cohesion: 0.18
Nodes (3): UserMapper, ResurfacingScheduler, ResurfacingSchedulerTest

### Community 63 - "org.springframework.stereotype.Component"
Cohesion: 0.09
Nodes (9): IdentityProvider, APPLE, GOOGLE, UNSUPPORTED, IdentityTokenVerifier, VerifiedIdentity, PathNormalizationFilter, HttpServletRequestWrapper (+1 more)

### Community 64 - "Intent"
Cohesion: 0.16
Nodes (3): MainActivity, ShareDeliveryState, main()

### Community 65 - "summary_token.dart"
Cohesion: 0.11
Nodes (17): actionPayload, actionScheme, actionType, hashCode, highlight, icon3d, iconName, italic (+9 more)

### Community 67 - "app_auth_boundary_test.dart"
Cohesion: 0.05
Nodes (34): captures, CategoryGroup, categoryName, color, icon, subCategoryName, close, db (+26 more)

### Community 69 - "AppDelegate"
Cohesion: 0.14
Nodes (6): Flutter, AppDelegate, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 71 - "firebase_auth_gateway_test.dart"
Cohesion: 0.05
Nodes (35): _authenticate, _google, _googleInitialization, initialize, _session, sessions, signInWithApple, signInWithGoogle (+27 more)

### Community 72 - "AIEntity"
Cohesion: 0.17
Nodes (5): AIEntity, DefaultEntityEnrichmentAdapter, CompositeEntityEnricher, EntityEnricher, DefaultEntityEnrichmentAdapterTest

### Community 73 - "ProviderOperationException"
Cohesion: 0.09
Nodes (9): ExternalProviderException, LatyrException, Outcome, AMBIGUOUS, PERMANENT, RETRYABLE, UNSUPPORTED, ProviderOperationException (+1 more)

### Community 74 - "CaptureMapper"
Cohesion: 0.15
Nodes (7): CaptureStatus, COMPLETED, FAILED, PARTIAL, PENDING, PROCESSING, CaptureMapper

### Community 75 - "fake_auth_gateway.dart"
Cohesion: 0.12
Nodes (14): appleCalls, current, events, googleCalls, initializationError, initialize, pendingSignIn, _signIn (+6 more)

### Community 78 - "place_metadata.dart"
Cohesion: 0.12
Nodes (15): address, city, country, fromMap, latitude, location, longitude, mapsUrl (+7 more)

### Community 79 - "capture_source_icon.dart"
Cohesion: 0.14
Nodes (13): CaptureSource, build, CaptureSourceIcon, color, _InstagramGlyphPainter, paint, shouldRepaint, size (+5 more)

### Community 80 - "app_switcher_scroll_physics.dart"
Cohesion: 0.13
Nodes (8): applyPhysicsToUserOffset, applyTo, AppSwitcherScrollPhysics, createBallisticSimulation, _kOverScrollSpring, minFlickVelocity, velocityPerCard, main

### Community 82 - "latyr_expandable_text.dart"
Cohesion: 0.15
Nodes (11): RoundedTextStyle, animationDuration, build, createState, _isExpanded, LatyrExpandableText, _LatyrExpandableTextState, maxLines (+3 more)

### Community 86 - "brand_registry.dart"
Cohesion: 0.06
Nodes (32): brandColor, BrandRegistry, BrandToken, colorFromHex, iconColor, logoUrl, name, resolve (+24 more)

### Community 87 - "app.dart"
Cohesion: 0.09
Nodes (24): _AuthenticatedHome, build, _buildFloatingNavBar, _buildNavItem, createState, _currentIndex, dispose, initState (+16 more)

### Community 88 - "List"
Cohesion: 0.17
Nodes (9): category, confidenceScore, fromMap, GenericEntityMetadata, rawProperties, sourceDomain, summary, tags (+1 more)

### Community 92 - "entertainment_detail_screen.dart"
Cohesion: 0.06
Nodes (35): LatyrProgressiveBlur, _LatyrProgressiveBlurState, LatyrRichSummary, _LatyrRichSummaryState, _AppleTvImdbLinkTile, _AppleTvImdbLinkTileState, _AppleTvSynopsis, _AppleTvSynopsisState (+27 more)

### Community 96 - ".createUrlCapture"
Cohesion: 0.21
Nodes (3): CaptureResponse, CreateCaptureRequest, CaptureServiceTest

### Community 100 - "capture_source_classifier.dart"
Cohesion: 0.12
Nodes (11): CaptureSourceClassifier, classify, extractFirstUrl, normalizeUrl, _trackingParams, _urlRegex, _parseLinkTarget, stripMarkup (+3 more)

### Community 102 - "SubscriptionQuotaService"
Cohesion: 0.16
Nodes (4): RevenueCatWebhookController, UserSubscriptionHistoryMapper, SubscriptionQuotaService, RevenueCatWebhookControllerTest

### Community 103 - "github_language_colors.dart"
Cohesion: 0.29
Nodes (5): _colors, formatCount, formatRelativeTime, GitHubLanguageColors, resolve

### Community 105 - "token_provider_test.dart"
Cohesion: 0.08
Nodes (20): _Auth, _GoogleAccount, _User, _Adapter, _Auth, close, closed, connect (+12 more)

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

### Community 136 - "sync_service.dart"
Cohesion: 0.12
Nodes (12): captureRepository, _connectivity, dispose, _feedSyncTimer, _processingTimer, _startListening, _startTimers, _subscription (+4 more)

### Community 137 - "WeatherIntegrationClient"
Cohesion: 0.14
Nodes (8): CaptureStreamController, ContextController, WeatherContextResponse, HealthController, LocationData, WeatherData, WeatherIntegrationClient, ProbeController

### Community 138 - "UserService"
Cohesion: 0.18
Nodes (6): UserController, UpdatePreferencesRequest, UserProfileResponse, UserService, UserControllerTest, CurrentUserArgumentResolver

### Community 139 - "StreamingBrandCatalog"
Cohesion: 0.17
Nodes (4): BrandMetadata, StreamingBrandCatalog, AssetStorageProvider, CdnAssetStorageProvider

### Community 142 - "dart:async"
Cohesion: 0.17
Nodes (6): close, fetch, RecordingHttpAdapter, requests, main, providers

### Community 143 - "Language"
Cohesion: 0.18
Nodes (5): Language, ENGLISH, HINDI, HINGLISH, ORIGINAL

### Community 146 - "Document"
Cohesion: 0.17
Nodes (11): Apify Scraper, Document, Firebase Authentication, Flutter MVVM Riverpod Drift, Gemini Multimodal, Latyr Capture Understanding, MyBatis Explicit SQL, PostgreSQL Transactional Queue (+3 more)

### Community 148 - "UrlSourceClassifier"
Cohesion: 0.12
Nodes (5): MarkupSanitizer, UrlSourceClassifier, EphemeralMediaStreamerTest, MarkupSanitizerTest, UrlSourceClassifierTest

### Community 149 - "Intent"
Cohesion: 0.16
Nodes (10): Intent, BUY, COOK, EXPLORE, LEARN, REMEMBER, VISIT, WATCH (+2 more)

### Community 153 - "Document"
Cohesion: 0.14
Nodes (13): Document, Dynamic Entity Enrichment, EntityDetailScreen, IMDb Destination Tile, Inline MORE Pill, JustWatch CDN Logos, LatyrExpandableText, Light Mode (+5 more)

### Community 155 - "JobStatus"
Cohesion: 0.25
Nodes (5): JobStatus, COMPLETED, FAILED, PENDING, PROCESSING

### Community 161 - "org.slf4j.Logger"
Cohesion: 0.10
Nodes (7): ApifyScraperAdapter, EntityEnrichmentProvider, EphemeralMediaStreamer, ThumbnailStorage, FirebaseStorageService, IngestionPipelineService, IngestionQueueWorker

## Knowledge Gaps
- **1210 isolated node(s):** `com.latyr:latyr-api`, `GOOGLE`, `APPLE`, `UNSUPPORTED`, `WATCH` (+1205 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1671 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **71 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Capture` connect `Capture` to `NotificationLog`, `CanonicalSource`, `CaptureMapper`, `Intent`, `.publishCore`, `.processJob`, `Uuid`, `java.util.List`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `com.latyr:latyr-api`, `GOOGLE`, `APPLE` to the rest of the system?**
  _1210 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package:flutter/cupertino.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.033707865168539325 - nodes in this community are weakly interconnected._
- **Why does `WatchProviderCategory` connect `WatchProviderCategory` to `org.springframework.stereotype.Component`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Should `ExtractedEntity` be split into smaller, more focused modules?**
  _Cohesion score 0.08163265306122448 - nodes in this community are weakly interconnected._
- **Why does `IngestionJob` connect `IngestionJob` to `ExtractedEntity`, `org.slf4j.Logger`, `DurableIngestionPostgresTest.java`, `CanonicalSource`, `JobStatus`, `assertions`, `org.junit.jupiter.api.Test`, `.claim`, `IngestionStageCheckpoint`, `.publishCore`, `.processJob`, `DurableIngestionStore`, `Capture`, `Uuid`, `java.util.List`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._