# Latyr — Live Visual Verification & Screenshots Showcase

**Verification Target:** Pixel 9 Android Emulator (`emulator-5554`) & `latyr-api` UAT Profile  
**Device Resolution:** 1080 × 2424 (420 dpi)  
**Status:** 100% Verified Live in UAT  

---

## 1. Executive Summary

This document presents the visual verification of Latyr's **Magazine Design Language** and **Dynamic Entity Enrichment Pipeline** (Phase 1 Entertainment). All screenshots were captured directly on the live **Pixel 9 Android emulator** running against `latyr-api` (Spring Boot 3.3, Project Loom) on port 8080 and PostgreSQL 16+ (`latyr_db`).

---

## 2. Visual Verification Gallery

### 2.1 Enriched Magazine Feed Cards
* **Capabilities Verified**:
  * 90×135 2:3 vertical theatrical portrait artwork.
  * Gold Inter typographic rating pills: `★ 6.1 IMDb`, `★ 6.3 IMDb · R`, `★ 7.1 IMDb · TV-MA`.
  * Content maturity rating badges (`TV-MA`, `R`) in the subtitle row.
  * Branded streaming action buttons (`Watch on Netflix ►`).

![Enriched Magazine Cards](./screens/omdb_cards_live.png)  
*Direct Link: [View High-Res `omdb_cards_live.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/omdb_cards_live.png)*

---

### 2.2 Interactive Rating Bottom Sheets (Nominative Fair Use)
* **Capabilities Verified**:
  * Tapping the rating badge opens a Cupertino disclosure modal.
  * Displays exact score (`7.1 / 10`, `6.3 / 10`).
  * Displays authentic global vote count (`30,997 global user ratings`, `181,261 global user ratings`).
  * Surfaces Rotten Tomatoes critics score (`🍅 73% Tomatometer`).
  * Legal attribution under Nominative Fair Use disclaiming affiliation with IMDb.com, Inc.
  * Outbound link: `"View on IMDb ↗"`.

| *God's Crooked Lines* Rating Breakdown | *The Guilty* Rating Breakdown (with Rotten Tomatoes) |
| :---: | :---: |
| ![God's Crooked Lines Sheet](./screens/rating_sheet_gods_crooked_lines.png) | ![The Guilty Sheet](./screens/rating_sheet_the_guilty.png) |
| [Open `rating_sheet_gods_crooked_lines.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/rating_sheet_gods_crooked_lines.png) | [Open `rating_sheet_the_guilty.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/rating_sheet_the_guilty.png) |

---

### 2.3 Full-Screen Immersive Detail Views (`EntityDetailScreen`)

#### 1. *God's Crooked Lines* (Awards & Spanish Mystery Drama)
* **Top 48% Bleed**: TMDB 16:9 cinematic backdrop smoothly blurred into extracted ambient colors.
* **Floating Hero Poster**: 108×162 portrait poster with 14px rounded corners and realistic elevation.
* **Header Chips**: `★ 7.1 IMDb` pill, `[TV-MA]` maturity badge, `Movie · 2022 · 2h 34m`.
* **Verified Awards Card**: Golden-bordered card with trophy icon (`🏆 4 wins & 20 nominations total`).
* **Creative Credits**: Director Oriol Paulo, screenwriters, cast, audio language (Spanish), country (Spain).

| Hero Header & Awards Card | Scrolled Production & Creative Credits |
| :---: | :---: |
| ![God's Crooked Lines Detail](./screens/gods_crooked_lines_detail_omdb.png) | ![God's Crooked Lines Scrolled](./screens/gods_crooked_lines_detail_scrolled.png) |
| [Open `gods_crooked_lines_detail_omdb.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/gods_crooked_lines_detail_omdb.png) | [Open `gods_crooked_lines_detail_scrolled.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/gods_crooked_lines_detail_scrolled.png) |

---

#### 2. *The Guilty* (Studio Tagline & Rotten Tomatoes Score)
* **Studio Marketing Tagline**: Official TMDB studio tagline quote: *"Listen carefully."*.
* **Header Chips**: `★ 6.3 IMDb` pill, `🍅 73%` Rotten Tomatoes chip, `[R]` content rating badge.
* **Creative Credits**: Director Antoine Fuqua, screenplay by Nic Pizzolatto, lead cast Jake Gyllenhaal.

| Hero Header & Tagline Quote | Scrolled Production & Cast |
| :---: | :---: |
| ![The Guilty Detail](./screens/the_guilty_detail_omdb_live.png) | ![The Guilty Scrolled](./screens/the_guilty_detail_scrolled.png) |
| [Open `the_guilty_detail_omdb_live.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/the_guilty_detail_omdb_live.png) | [Open `the_guilty_detail_scrolled.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/the_guilty_detail_scrolled.png) |

---

### 2.4 Animated Expandable Synopsis (`LatyrExpandableText`)
* **Capabilities Verified**:
  * 3-line preview clamp by default to maintain magazine card rhythm.
  * Tapping `"Show more"` triggers an animated height expansion revealing the full creator synopsis.
  * Tapping `"Show less"` collapses smoothly back to 3 lines.

![Expandable Synopsis](./screens/enhancements_show_more_expanded.jpg)  
*Direct Link: [View High-Res `enhancements_show_more_expanded.jpg`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/enhancements_show_more_expanded.jpg)*

---

### 2.5 Official Streaming Platform Branding & JustWatch CDN Integration
* **Capabilities Verified**:
  * **Dynamic TMDB JustWatch CDN Icons**: Enriched entities dynamically receive official 92×92 square streaming logos directly from TMDB's Watch Providers CDN (`https://image.tmdb.org/t/p/w92/rK1KljqmbvO9HQa1PBFLILWah72.png` for Netflix).
  * **Flavored Action CTA Buttons**: Button on cards and full-screen immersive view renders the official Netflix brand badge with crisp typography (`Watch on Netflix ►`).
  * **Resilient Graceful Fallbacks**: If network or provider logo is unavailable, falls back instantly to local vector badge without broken asset errors.
  * **Nominative Fair Use**: Legally compliant identification of content availability with deep link directly to the title.

| Movie Cards with JustWatch CDN Logo | Immersive Full-Screen CTA with JustWatch CDN Logo |
| :---: | :---: |
| ![JustWatch Cards Verified](./screens/watch_provider_cards_verified.png) | ![JustWatch Detail Verified](./screens/watch_provider_detail_view_verified.png) |
| [Open `watch_provider_cards_verified.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/watch_provider_cards_verified.png) | [Open `watch_provider_detail_view_verified.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/watch_provider_detail_view_verified.png) |

---

### 2.6 Apple TV-Inspired Detail View (Early-Fading Progressive Blur & Sharp Character Artwork)
* **Capabilities Verified**:
  * **Blur Strictly Constrained to Title Downward**: The progressive blur layer begins strictly at the title line (`top: blurTop`, `bottom: 0`). 100% of the upper poster—including character faces, eyes, textured artwork, and studio taglines—remains razor-sharp and untouched by the blur shader.
  * **Early-Fading Progressive Transition**: Blur sigma and monochrome tint start fading immediately from the bottom edge (`stops: [0.0, 0.15, 0.45, 0.75, 1.0]`, $\sigma_{\text{start}}=16.0 \to \sigma_{\text{end}}=0.0$ at `Alignment(0.0, -0.2)`). By the synopsis and subtitle, the blur and tint have dissolved to subtle translucency, allowing underlying poster details (e.g. the typography and textures in *The Guilty*) to shine through clearly.
  * **Poster Bottoms Out Just Below Ratings Row**: Hero stack sizes dynamically so that the full theatrical portrait poster extends naturally through the title, subtitle, synopsis, and ratings row, terminating cleanly 16px below the metrics row before the streaming CTA button.
  * **Zero-Container Typography**: All metric boxes, genre tags, and rating pills stripped away. Media type and genres formatted as clean dot-separated text (`Movie · Crime · Drama`), and metrics formatted inline (`2021 · 1h 29m · [R] · 🍅 73% · ★ 6.3 IMDb · Ⓜ 63/100`).
  * **Apple TV-Style `[MORE]` Pill**: Clean 2-line clamped synopsis with Cupertino tap toggle expanding/collapsing on demand.
  * **Tabular Information List**: Director, writers, cast, and country presented with subtle hairline dividers instead of card boxes.

| *The Guilty* (Sharp Face & Early Blur Fade) | *God's Crooked Lines* (Sharp Hair & Clean Palette) | *The Chalk Line* (Crisp Floor Grid & Character) |
| :---: | :---: | :---: |
| ![The Guilty Early Fade](./screens/apple_tv_fade_early_the_guilty.png) | ![God's Crooked Lines Early Fade](./screens/apple_tv_fade_early_gods_crooked_lines.png) | ![The Chalk Line Early Fade](./screens/apple_tv_fade_early_the_chalk_line.png) |
| [Open `apple_tv_fade_early_the_guilty.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_fade_early_the_guilty.png) | [Open `apple_tv_fade_early_gods_crooked_lines.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_fade_early_gods_crooked_lines.png) | [Open `apple_tv_fade_early_the_chalk_line.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_fade_early_the_chalk_line.png) |

---

### 2.7 Apple TV Exact 1:1 Pixel Match (Bottom-Left Ratings, Inline [MORE], Pure White Watch Button, Accolade Pill, Seamless Zero-Line Seam)
* **Capabilities Verified**:
  * **Bottom-Left Aligned Metrics with Apple Weight**: Ratings and metadata row aligned strictly to `Alignment.centerLeft` with heavier font weights (`FontWeight.w600` / `w700`) reflecting Apple's SF Pro styling (`2021 · 1h 29m · [R] · 🍅 73% · ★ 6.3 IMDb · Ⓜ 63/100`).
  * **Left-Aligned Synopsis with Inline `[MORE]` Pill**: Replaced center-aligned text and separate button with left-aligned natural flow. The `[MORE]` pill button renders inline at the exact end of line 2 using custom layout calculation, seamlessly matching Apple's *United 93* and *The Guilty* references. Tapping `[MORE]` smoothly expands the full plot with an inline `[LESS]` pill.
  * **Apple-Style High-Contrast Watch Button**: Redesigned the primary CTA into Apple's signature pure white pill (`Color(0xFFFFFFFF)` in dark mode / black in light mode) with bold black typography, Cupertino play icon (`▶`), official 20×20 provider CDN logo badge (`[N]`), and animated spring scale feedback (`scale: 0.98`).
  * **Frosted Accolade Badge Below Button**: Positioned a sleek frosted badge (`#1C1C1E`) directly below the action button (`🏆 2 wins total`, `🏆 4 wins & 20 nominations total`) and linked awards into the tabular Information section.
  * **100% Elimination of Visible Line Below Poster**: Implemented inverted alpha `ShaderMask` on the poster artwork and solid opaque background stops (`[0.0, 0.22, 0.50, 0.78, 1.0]`), guaranteeing the poster fades completely to 100% pitch black before the boundary with zero visible seam under zoom.

| *The Guilty* (Exact Apple TV UI) | *God's Crooked Lines* (Exact Apple TV UI) | *The Chalk Line* (Exact Apple TV UI) |
| :---: | :---: | :---: |
| ![The Guilty Exact](./screens/apple_tv_guilty_exact.png) | ![God's Crooked Lines Exact](./screens/apple_tv_gods_crooked_lines_exact.png) | ![The Chalk Line Exact](./screens/apple_tv_chalk_line_exact.png) |
| [Open `apple_tv_guilty_exact.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_guilty_exact.png) | [Open `apple_tv_gods_crooked_lines_exact.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_gods_crooked_lines_exact.png) | [Open `apple_tv_chalk_line_exact.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_chalk_line_exact.png) |

| *The Chalk Line* (Expanded Synopsis with Inline `[LESS]`) | *God's Crooked Lines* (Scrolled Information Table & Links) |
| :---: | :---: |
| ![The Chalk Line Expanded](./screens/apple_tv_chalk_line_expanded.png) | ![God's Crooked Lines Scrolled](./screens/apple_tv_gods_crooked_lines_scrolled.png) |
| [Open `apple_tv_chalk_line_expanded.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_chalk_line_expanded.png) | [Open `apple_tv_gods_crooked_lines_scrolled.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/apple_tv_gods_crooked_lines_scrolled.png) |

---

### 2.8 Device Light Mode Visual Verification (Dynamic Monochrome Palette, Apple Contrast, Frosted Dismiss)
* **Capabilities Verified**:
  * **System Light Mode Response (`uimode night no`)**: App dynamically resolves ambient light brightness across all presentation screens.
  * **Fresh Cream & Crisp White Canvases**: Home tab renders with pastel metric capsules and soft cards; Capture overview renders with warm cream canvas (`#F8F9FA`) and pure white summary surface.
  * **Enriched Entity Cards on White**: Clean white card tiles with high-contrast dark typography, gold IMDb rating pills, and streaming action buttons.
  * **Apple Light Mode Detail View**:
    * **Milky Frosted Gradient Diffusion**: Progressive blur shader transitions from transparent at chest level to 94% light background opacity behind the title, subtitle, and synopsis, guaranteeing crisp, shadowless black text readability without obscuring actor facial features.
    * **Apple Dark Action Pill (`#1C1C1E`)**: Signature Apple high-contrast black button with bold white text `▶ Watch on Netflix [N]`.
    * **Frosted Accolade Badge**: Light pill card (`#F2F2F7`) with dark typography and gold trophy.
    * **Frosted White Dismiss Button**: Crisp circular white frosted button with black cross icon and soft ambient drop shadow.
    * **Cupertino Rating Action Sheet**: Native iOS-style light disclosure popup with clear ratings, vote counts, and legal attribution.

| Home Tab (Light Mode) | Capture Overview (Light Mode) | Entity Cards Feed (Light Mode) |
| :---: | :---: | :---: |
| ![Home Light](./screens/light_mode_home.png) | ![Capture Overview Light](./screens/light_mode_capture_detail_cards.png) | ![Entity Cards Light](./screens/light_mode_entity_cards.png) |
| [Open `light_mode_home.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_home.png) | [Open `light_mode_capture_detail_cards.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_capture_detail_cards.png) | [Open `light_mode_entity_cards.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_entity_cards.png) |

| *The Guilty* (Light Detail View) | *God's Crooked Lines* (Light Detail View) | *The Chalk Line* (Light Detail View) |
| :---: | :---: | :---: |
| ![The Guilty Light](./screens/light_mode_the_guilty.png) | ![God's Crooked Lines Light](./screens/light_mode_gods_crooked_lines.png) | ![The Chalk Line Light](./screens/light_mode_the_chalk_line.png) |
| [Open `light_mode_the_guilty.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_the_guilty.png) | [Open `light_mode_gods_crooked_lines.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_gods_crooked_lines.png) | [Open `light_mode_the_chalk_line.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_the_chalk_line.png) |

| *God's Crooked Lines* (Scrolled Info & Links) | Cupertino Rating Verification Sheet (Light) |
| :---: | :---: |
| ![God's Crooked Lines Scrolled Light](./screens/light_mode_gods_crooked_lines_scrolled.png) | ![Rating Sheet Light](./screens/light_mode_rating_sheet.png) |
| [Open `light_mode_gods_crooked_lines_scrolled.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_gods_crooked_lines_scrolled.png) | [Open `light_mode_rating_sheet.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/light_mode_rating_sheet.png) |

---

### 2.9 Pure Progressive Blur Shader & Cinema Hero Architecture (Elimination of White Gradient Overlay)
* **Architectural Insight**:
  * **Zero Artificial Haze**: The artificial white gradient overlay has been completely removed (`LatyrProgressiveBlur(child: null)`). The GPU fragment shader smoothly diffuses the authentic poster pixels directly without washing out the colors.
  * **Apple TV Cinema Mode Standards**: Content detail screens are treated as an immersive theatrical experience (`scaffoldBgColor = #000000`), matching Apple TV, Netflix, Disney+, and HBO Max design standards.
  * **Universal Contrast Invariance**: Hero typography (Tagline, Title, Subtitle, Synopsis, Ratings) is rendered in pure white (`Colors.white`) with Apple SF Pro vibrancy and subtle dark drop shadow (`Shadow(blurRadius: 8, color: Colors.black)`). This guarantees 100% legibility across dark posters (*The Guilty*), warm light posters (*God's Crooked Lines*), and mid-tone posters (*The Chalk Line*).
  * **Seamless Zero-Line Dissolve**: The poster fades directly into pitch black right below the ratings row, eliminating hard seams and color collisions.

| *The Guilty* (Pure Blur Cinema) | *God's Crooked Lines* (Pure Blur Cinema) | *The Chalk Line* (Pure Blur Cinema) |
| :---: | :---: | :---: |
| ![The Guilty Cinema](./screens/cinema_the_guilty.png) | ![God's Crooked Lines Cinema](./screens/cinema_gods_crooked_lines.png) | ![The Chalk Line Cinema](./screens/cinema_the_chalk_line.png) |
| [Open `cinema_the_guilty.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/cinema_the_guilty.png) | [Open `cinema_gods_crooked_lines.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/cinema_gods_crooked_lines.png) | [Open `cinema_the_chalk_line.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/cinema_the_chalk_line.png) |

---

### 2.10 Blended Apple TV IMDb Destination Tile (TMDB Removed, Zero Visual Clutter)
* **Design Refinement**:
  * **Removed TMDB Link**: TMDB outbound button completely eliminated; only the official IMDb destination is preserved.
  * **Blended Dark Surface (`#1C1C1E`)**: Replaced the previous neon-bordered button with Apple's dark grouped surface card (`Border.all(width: 0.5, color: 8% white)`).
  * **Brand Precision**: Left-aligned iconic golden IMDb badge (`#F5C518`), clean white SF Pro title `"View on IMDb"`, and a subtle translucent diagonal arrow (`↗`).
  * **Zero Clutter**: Flows harmoniously right below the Information table with generous bottom safe area padding.

| Scrolled Detail View with Blended IMDb Tile |
| :---: |
| ![Blended IMDb Tile](./screens/imdb_tile_perfect.png) |
| [Open `imdb_tile_perfect.png`](file:///c:/Users/nikhi/StudioProjects/latyr/screens/imdb_tile_perfect.png) |

---

## 3. Test Device & Environment Provenance

* **Device**: Pixel 9 (Android 15 / API 35, `emulator-5554`)
* **Flutter**: Flutter 3.x (Dart 3.x)
* **Backend**: Spring Boot 3.3.3 (Java 21 Project Loom Virtual Threads, Profile: `uat`)
* **Database**: PostgreSQL 16+ (`latyr_db` on localhost:5432)
* **Verified Real Capture**: `a9539f7c-592a-448b-b0a3-1f22175989de` (Instagram Reel containing 3 real Spanish & American thriller movies)

