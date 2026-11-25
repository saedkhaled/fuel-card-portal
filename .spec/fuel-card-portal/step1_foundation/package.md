# Package 01 · Foundation

Status Complete · Dependencies none · Estimate 2–3 h

## Objective and ownership

Own Flutter/Android bootstrap, app composition, shell, theme, locale, auth, and fixture conventions. Read R01–R03 and R21 from [reference audit](../reference-audit.md) and the [architecture](../architecture.md). Create route hooks for upcoming tab/feature screens, handing off actual UI to their owners.

## Tasks

- [x] Record repository/device/toolchain baseline and create the Android Flutter project using the planned application ID. Pin the SDK choice and package lockfile. Install and launch the scaffold.
- [x] Set up Material 3 tokens, app identity, English/Arabic catalogs, accessible shell and guard, and scoped route contracts.
- [x] Implement a fake session, phone validation, timed OTP request/resend/verify with synthetic sign-in hints, guarded session restoration, and notification prompt state. Expose logout and locale operations for account features.
- [x] Build the JSON asset loader, scenario manifest and initial auth fixture from the [fixture contract](../fixtures.md). Register assets, test missing and invalid JSON, and document file ownership. Establish repository injection, time conventions and persistence namespaces.
- [x] Add focused auth, clock, localization and routing tests. Run format, analyze, relevant tests and first Android sign-in smoke.

## Evidence

- Started from `main` at `a6a2352` with a clean worktree.
- Flutter 3.44.2, Dart 3.12.2, JBR 21.0.10, Gradle 9.1.0, AGP 9.0.1, compile and target SDK 36. Android application ID is `com.example.fleet_cards_demo` and minSdk is 24.
- `flutter gen-l10n`, Dart format and `flutter analyze --no-pub` passed. All nine tests passed with `flutter test --no-pub`, covering fixture parsing and recovery, exact resend/expiry boundaries, protected navigation, locale direction and session restore/sign-out.

- `flutter build apk --debug --target-platform android-arm64 --no-pub` built the foundation. APK copy at `build/foundation/fleet-cards-foundation-debug.apk` (debug-signed, Flutter engine ARM64). SHA-256 `da3e4736d69bed60dc8ec361caa5207274850f502ac16da2c8248df4b9bbf3dd`. Inspected the packaged auth and manifest assets and Android SDK declarations.
- Installed and launched on the dedicated Pixel 9 Pro AVD `FleetCardsApi36` (Android 16/API 36) using ADB. Airplane mode on, Wi-Fi off, 360 dp and 1.3× font scale. Verified Arabic sign-in, switch to English, JSON OTP, one-time prompt dismissal, cold restart with English and session restored, language changes from More, logout cancel/confirm, and a second cold restart with the session cleared.
- `flutter test --no-pub integration_test/foundation_smoke_test.dart -d emulator-5556` passed in airplane mode. The test reads the bundled auth fixture, exercises sign-in and checks shell navigation.
- API 24 runtime and release-mode checks remain part of Package 05. The initial all-ABI packaging run was replaced with the tested ARM64 debug build after host memory pressure.

## Handoff

The router defines the five tab roots and the auth guards. Replace the foundation tab content as later packages land. Extend the scenario's JSON file mappings and consume the selected `DemoFixtures` from app composition. Keep the account ID and preference namespace stable.

## Exit

The phone and code in the bundled JSON sign in offline through the real launch path. Guard, clock-based error flows, locale switch and restart are verified. Device launch and commands are recorded. 02 and 03 can start.
