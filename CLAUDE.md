# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

Play SRG is the SRG SSR (Swiss Broadcasting Corporation) iOS and tvOS audio/video platform. The same codebase produces five distinct apps (Play SRF, Play RSI, Play RTS, Play RTR, Play SWI), each a different Xcode target sharing most of the code but with BU-specific configuration. Minimum deployment: iOS 14.1, tvOS 14.

## Commands

```bash
make setup          # checkout private configuration repo + pod install
make check-quality  # SwiftLint + SwiftFormat + RuboCop + ShellCheck + yamllint
make fix-quality    # auto-fix SwiftLint/SwiftFormat issues
make git-hook-install   # install pre-commit linter and Jira commit-msg hook (run once)
```

Quality checks are strict — CI fails on any lint or format warning. Always run `make check-quality` before committing. To fix issues automatically: `make fix-quality`.

There are no automated unit tests to run from the command line; testing is done through Xcode UI tests in the `UITests/` target.

## Project Structure

### Language split

The codebase is a **mixed Objective-C / Swift project**. The iOS app layer has a large Objective-C foundation (AppDelegate, UIKit view controllers, player, helpers) that bridges into Swift via `PlaySRG-Swift.h`. New code is written in Swift. tvOS is nearly all Swift.

### Source directories

| Directory | Contents |
|---|---|
| `Application/Sources/` | iOS-only source (see below) |
| `TV Application/` | tvOS app source |
| `Common/Sources/` | Shared code (currently just `AccessibilityIdentifier.swift`) |
| `Extensions/NotificationService/` | iOS notification service extension |
| `Extensions/TopShelf/` | tvOS Top Shelf extension |
| `UITests/` | UI test targets for screenshots |

### iOS source modules (`Application/Sources/`)

- **Application/** — `AppDelegate` (ObjC), `SceneDelegate` (ObjC), `Navigation.swift` (navigation helpers and `navigateToMedia` / `navigateToShow` entry points)
- **Configuration/** — `ApplicationConfiguration` (ObjC singleton, Firebase-backed remote config). All remote config keys are documented in `docs/REMOTE_CONFIGURATION.md`.
- **Content/** — `Content.swift` (defines `Content.Section` and `Content.Item` enums used throughout), `SectionViewModel`, `PageViewModel` — the core data model for content pages
- **Player/** — `MediaPlayerViewController` (ObjC, wraps SRGLetterbox), `MediaPreviewViewController`, program guide views
- **UI/Controllers/** — Base UIKit view controllers (`BaseViewController`, `DataViewController`, `TabBarController`, etc.)
- **UI/Views/** — SwiftUI and UIKit reusable views (cells, cards, overlays)
- **DeepLinking/** — `DeepLinkService` (ObjC), `DeepLinkAction`
- **Helpers/** — `PushService` (ObjC, Airship SDK), `ApplicationSettings`, shared utilities
- **Bridges/** — ObjC-callable Swift wrappers (e.g. `SwiftMessagesBridge`)
- **CarPlay/** — CarPlay scene delegate and template controllers
- **Profile/** — User profile / account views (mixed SwiftUI + UIKit)
- **MiniPlayer/** — Audio mini player (iOS only)
- **Downloads/** / **Favorites/** / **WatchLater/** / **History/** — User data features

### Key dependencies (CocoaPods)

- **SRGLetterbox** — media player SDK (wraps AVPlayer, handles DRM, subtitle tracks, continuous playback)
- **SRGDataProvider** / **SRGDataProviderCombine** — Integration Layer (IL) API client and Combine publishers
- **SRGAnalytics** / **SRGAnalyticsIdentity** — analytics and identity tracking
- **SRGUserData** — remote sync for history, favorites, watch later
- **SRGIdentity** — user login/logout
- **AirshipCore** — push notifications (iOS only)
- **Firebase** — remote configuration and crash reporting (AppCenter for crashes)
- **libextobjc** — ObjC utilities (`@weakify`/`@strongify`, `@onExit`)

### Configuration system

Build settings are layered xcconfig files under `Xcode/`:
- `Xcode/Shared/Common.xcconfig` — top-level shared settings (prefix `COMMON__`)
- `Xcode/Shared/BUs/` — per-BU settings (prefix `BU__`)
- `Xcode/Shared/Targets/` — per-target-type settings (prefix `TARGET__`)
- Leaf files in `Xcode/iOS/` and `Xcode/tvOS/` only contain `#include` directives

The private `Configuration/` folder (checked out by `make setup` from a separate private repo) contains secrets, `AirshipConfig.plist`, `GoogleService-Info.plist`, and `ApplicationConfiguration.json` for each BU.

### Build configurations

Four configurations: **Debug**, **Nightly** (release, internal distribution), **Beta** (TestFlight), **AppStore**.

### Content data flow

Pages load via `PageViewModel` → `SectionViewModel` (per section) → `Content.Section`/`Content.Item` enums → SRGDataProviderCombine publishers. The `Content.swift` file is the central type definition for all displayable content.

### Branch and commit conventions

- Branch naming: `JIRA-1234-feature-name` (Jira) or `1234-feature-name` (GitHub issue)
- Commit messages must include the Jira/GitHub ticket ID; the `commit-msg` hook adds it automatically after `make git-hook-install`
- PRs are squash-merged into `main`

### Translations

Managed via Crowdin. Source strings live in `Translations/`. Use `make generate-translations` → `make push-translations` / `make pull-translations`.
