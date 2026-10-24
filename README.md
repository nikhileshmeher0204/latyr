# Latyr

**Latyr** is an intelligent personal information capture and understanding application designed to seamlessly capture, structure, and organize content across devices.

---

## 📁 Repository Structure

```text
latyr/
├── latyr-api/       # Backend REST API (Java 21 / Spring Boot 4)
│   ├── src/
│   ├── pom.xml
│   └── mvnw
└── latyr-app/       # Mobile Application (Flutter / Dart)
    ├── lib/
    ├── test/
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## 🛠️ Tech Stack

### Mobile App (`latyr-app`)
- **Framework**: Flutter (Dart SDK `>=3.12.2`)
- **Architecture**: Feature-First MVVM with Riverpod & Drift SQLite
- **UI**: Material Design 3 / Cupertino
- **Platforms**: Android & iOS

### Backend API (`latyr-api`)
- **Language**: Java 21
- **Framework**: Spring Boot 4.x / 3.3+ (Virtual Threads & Flyway)
- **Database**: PostgreSQL 16+
- **Build Tool**: Apache Maven (Wrapper included)

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed on your machine:
- [Java Development Kit (JDK 21+)](https://adoptium.net/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.2`)
- [Android Studio](https://developer.android.com/studio) / [Xcode](https://developer.apple.com/xcode/)
- [Git](https://git-scm.com/)

---

### 1. Running the Backend API (`latyr-api`)

Navigate to the `latyr-api` directory:

```bash
cd latyr-api
```

Run with the Maven wrapper:

- **Windows (PowerShell / Command Prompt)**:
  ```powershell
  .\mvnw.cmd spring-boot:run
  ```

- **macOS / Linux**:
  ```bash
  ./mvnw spring-boot:run
  ```

Run tests:
```bash
./mvnw test
```

---

### 2. Running the Flutter App (`latyr-app`)

Navigate to the `latyr-app` directory:

```bash
cd latyr-app
```

Fetch dependencies:
```bash
flutter pub get
```

Launch the application on an emulator or connected device:
```bash
flutter run
```

Run widget tests:
```bash
flutter test
```

---

## 🔒 Security & Sensitive Data Policy

- **No sensitive tokens or credentials**: `.env`, `*.key`, `*.keystore`, `*.jks`, `*.pem`, `google-services.json`, `GoogleService-Info.plist`, and `local.properties` are strictly ignored via `.gitignore`.
- Provide template environment files (`.env.example`) for required configuration keys without committing secrets.
- Backend credentials must be supplied through `FIREBASE_CONFIG_PATH` / `firebase.config.path` or Google Application Default Credentials (for example, an external file selected by `GOOGLE_APPLICATION_CREDENTIALS`). Credential files bundled on the classpath are no longer loaded. Known credential filenames and private-key files are excluded from backend resources and JARs, including stale build output.
- Use a clean build (`./mvnw clean package`) for release verification. The packaging regression can be run on Windows with `latyr-api/scripts/verify-resource-packaging.ps1 -MavenPath <path-to-mvn.cmd>`; it creates only nonsecret fixtures.
- API authentication requires a verified Firebase ID token. Development-token strings and unverified/custom JWT payloads are not accepted. The former `/api/v1/auth/*` diagnostic and `/api/v1/ai/*` direct-provider endpoints have been removed; capture processing uses the normal authenticated capture API.
