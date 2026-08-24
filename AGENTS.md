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

---

## 📱 Mobile Architecture Guidelines (`latyr-app`)
- **Feature-First MVVM**: Organize by domain features (`features/capture`, `features/feed`, `features/auth`, `features/settings`).
- **State Management**: Use `flutter_riverpod` (AsyncNotifier / StateNotifier).
- **Offline First**: Use `drift` (SQLite) for local caching, ensuring instant UI renders and background synchronization with `latyr-api`.
- **Share Extension Target**: The native iOS/Android share sheet must complete local write and return to system under **300ms**.
