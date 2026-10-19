# Latyr Engineering & Architecture Guidelines

This document defines the core architecture principles, coding standards, and design patterns for all AI agents and contributors working on the **Latyr** monorepo (`latyr-api` and `latyr-app`).

---

## 🏛️ Core Architectural Principles

### 1. Orchestrated & Decoupled Architecture
- **Layered Separation of Concerns**:
  - **Controllers (`controller/`)**: Thin entry points responsible only for request validation, routing, and returning standard response DTOs. Never put business logic or direct SQL/mapper calls in controllers.
  - **Services & Orchestrators (`service/`)**: Business logic, workflow orchestration, transaction boundaries (`@Transactional`), domain validations, and coordinating multiple mappers or external adapters.
  - **Data Access (`mapper/`)**: MyBatis `@Mapper` interfaces with clean, explicit SQL queries. No business logic in mappers.
  - **External Adapters (`client/` or `integration/`)**: Isolated clients for third-party services (Firebase, Vertex AI / Gemini, Apify, RevenueCat) wrapped in interfaces to allow easy mocking and swapping.
  - **Domain Models (`domain/model/`)**: Clean POJO models matching relational schemas without ORM coupling.
  - **DTOs (`dto/`)**: Request/Response contracts isolated from internal domain entities.

### 2. Scalable & Virtual Thread Friendly
- The backend runs on Java 21 with **Project Loom Virtual Threads** (`spring.threads.virtual.enabled=true`).
- Avoid `synchronized` blocks that pin carrier threads; use `ReentrantLock` or stateless concurrency where synchronization is necessary.
- Leverage PostgreSQL queue semantics (`FOR UPDATE SKIP LOCKED`) for background async workers.

### 3. Maintainability & Explicit SQL Control
- We use **MyBatis 3.0** (`@Mapper`, `@Select`, `@Insert`, `@Update`, `@Delete`) instead of heavy ORM abstractions.
- All database column-to-property mappings follow `snake_case` $\rightarrow$ `camelCase` conventions.
- Complex PostgreSQL types (`JSONB`, `TEXT[]`) must use dedicated type handlers in `com.latyr.api.config.typehandler`.

### 4. Robust Error Handling & Predictable API Responses
- All exceptions extend `LatyrException` with specific HTTP status codes and error codes (`INVALID_TOKEN`, `QUOTA_EXCEEDED`, `RESOURCE_NOT_FOUND`, etc.).
- Errors must be caught and transformed by `GlobalExceptionHandler` into a unified `ErrorResponse` payload:
  ```json
  {
    "timestamp": "2026-08-24T10:00:00Z",
    "status": 402,
    "error": "QUOTA_EXCEEDED",
    "message": "Monthly capture quota exceeded.",
    "path": "/api/v1/captures",
    "details": {}
  }
  ```

### 5. Zero-Secret Ingestion & Security
- **Never commit secrets, tokens, credentials, or private config files** (`.env`, `*.key`, `*.keystore`, `google-services.json`, `local.properties`).
- Security filters must validate tokens statelessly and inject standard `AuthenticatedUser` principals into Spring's `SecurityContextHolder`.

### 6. External Adapter Facades & Zero-Coupling Rule
- All external third-party integrations (GitHub, TMDB, OMDb, Apple Music, Apify, Firebase) **MUST** be abstracted behind an interface/facade in `com.latyr.api.client` or `adapter/`.
- Services and entity enrichers depend **ONLY** on the facade interface, never directly on concrete HTTP clients, raw vendor JSON schemas, or external SDKs.
- External payloads must be mapped immediately to clean, immutable internal DTO records. Swapping an external provider (e.g. switching GitHub REST to GraphQL or a self-hosted mirror) must require zero modifications to business or orchestration code.

### 7. Resolution Strategy & Audit Trail Tracking
- Multi-strategy enrichment pipelines (e.g. Direct Lookup vs. Search Fallback) **MUST** track and persist full resolution provenance and audit telemetry in the entity's JSONB `metadata`:
  - `resolution_strategy`: (e.g. `DIRECT_LOOKUP_SUCCESS`, `SEARCH_FALLBACK_SUCCESS`, `DOWNGRADED_TO_TOOL`, `CACHED`)
  - `resolution_source`: (e.g. `GITHUB_REST_V3`, `TMDB_OMDB_HYBRID`)
  - `predicted_target`: what AI suggested before validation
  - `resolved_target`: actual canonical identifier resolved
  - `fallback_reason`: why the primary strategy fell back (if applicable)
  - `resolution_latency_ms`: execution duration for performance benchmarking
  - `resolved_at`: ISO-8601 timestamp

### 8. Strict Zero-Hardcoded Brand & UI Metadata Rule (Server-Driven & Dynamic Architecture)
- **Zero Inlined Magic Constants in UI**: AI agents and contributors are **strictly prohibited** from hardcoding vendor brand colors (e.g. `Color(0xFF00A8E1)`), magic hex values, vendor-specific strings, or hardcoded `if-else` / `switch` brand cases inside Flutter UI presentation widgets.
- **Server-Driven Metadata (Single Source of Truth)**: Dynamic vendor metadata (streaming platforms, logos, brand colors, tile background colors, deeplink templates) must be **server-driven**. `latyr-api` enriches entity payloads with `brand_color`, `tile_color`, `logo_url`, and `watch_url`. When a third-party service rebrands (e.g., HBO Max $\rightarrow$ Max, Disney+ Hotstar $\rightarrow$ JioHotstar), the metadata is updated on the server/CDN catalog without requiring mobile app store releases.
- **Pure Stateless Renderers**: Mobile presentation widgets (e.g., `StreamingPlatformsCard`) must remain pure, stateless consumers. They parse and render the dynamic metadata contract delivered by the API.
- **Dynamic Palette Extraction & Centralized Fallback**: If an uncataloged or regional provider arrives without server brand metadata, the client MUST either extract dominant/vibrant colors dynamically from the logo image bitmap at runtime (via dynamic palette extraction) or resolve through a centralized `core/design` Brand Token Registry—NEVER through inlined `if-else` or ad-hoc `Color(...)` literals in widget files.

---

## 🎨 Design Language & UI Philosophy
- **Reference Design**: The file `latryl home screen.jpeg` (located at the root of the project) represents the core design language for Latyr.
- **Consistency**: Whatever design we make moving forward MUST complement and strictly adhere to the aesthetics, blurring (SoftEdgeBlur), typography, and dark/light color palette established in this reference image.

---

## 📱 Mobile Architecture Guidelines (`latyr-app`)
- **Feature-First MVVM**: Organize by domain features (`features/capture`, `features/feed`, `features/auth`, `features/settings`).
- **State Management**: Use `flutter_riverpod` (AsyncNotifier / StateNotifier).
- **Offline First**: Use `drift` (SQLite) for local caching, ensuring instant UI renders and background synchronization with `latyr-api`.
- **Share Extension Target**: The native iOS/Android share sheet must complete local write and return to system under **300ms**.
- **No Inlined Brand Tokens**: Presentation widgets must NEVER contain hardcoded vendor hex colors, switch-cases, or brand logic. Always consume server-provided `brand_color`/`tile_color` or resolve through a centralized `core/design` Brand Token Registry.

---

## ?? E2E Testing & Verification Guidelines (CRITICAL)
- **STRICT NO-MOCK DATA RULE**: When testing the Latyr ingestion pipeline (especially Instagram Reels or other media), **NEVER hallucinate, make up, or inject fake/mock URLs** via ADB intents. Mock data breaks downstream scrapers (like Apify) and creates false failures or empty AI results.
- **ALWAYS USE mobile-mcp NATIVE UI**: To test sharing functionality, you must physically interact with the Android emulator. Use the mobile-mcp mobile MCP (mobile_run_task) to open the actual target app (e.g., Instagram), scroll to a **real, publicly accessible Reel**, tap the native Share button, and select Latyr. Do not bypass the UI.
- **Handling Rate Limits**: If mobile-mcp hits an AI rate limit (e.g., Gemini 429 quota), **WAIT** for the quota to reset. Do not attempt to bypass the vision agent by manually injecting fake ADB intents.

