# Fuel-card portal execution memory

Android baseline archived 25 November 2026 · [Closeout and verification record](archive.md)

## Current state

- 07 adds a centered Support tab with five app guides and 23 Arabic answers from the official Golden Gate site. The Android 16 build verified Arabic first run and the support flow in airplane mode. The approved sheet and connected provider remain follow-up work. [Package 07 evidence](step7_ai_support/offline-implementation.md)

- The Flutter redesign is applied and verified on Android 16 in English and Arabic. All 27 local tests and five Android integration tests passed. The branded APK and implementation evidence are recorded in the [Flutter handoff](step6_figma_redesign/flutter-handoff.md#flutter-implementation-evidence).
- 06 Figma redesign and design handoff are complete. The user confirmed that the existing prototype examples are optional. The Flutter handoff records the Android implementation and accessibility checks. [Design and evidence](step6_figma_redesign/package.md#implementation-evidence)

- 05 Android acceptance completed. The development-signed release-mode APK is `build/android-acceptance/fleet-cards-demo-release.apk`. All 26 local and five Android integration tests passed. The exact APK passed the installed walkthrough on API 36 and the fresh offline sign-in smoke check on API 24. The handoff records the TalkBack spot check and its scope. [Acceptance evidence](step5_android_acceptance/package.md#artifact-and-verification-evidence)

- 04 Account services completed. Account and inbox fixtures, subscriptions, offline QR top-up, FAQ, alerts and sign-out passed local and Android 16 checks. The ARM64 debug APK is in `build/account-services/`.

- 03 Stations and prices completed. The bundled network fixture, station filters, offline directions, and bulletin history passed Arabic/English Android offline checks. The ARM64 debug APK is in `build/stations-prices/`.

- 02 Cards and finance completed. JSON-backed Home, cards and notes, balances, operations, sales, and CSV/XLSX passed Android 16 offline checks. The ARM64 debug APK is in `build/cards-finance/`.

- 01 Foundation completed on the checkout of `main` from `a6a2352`. Offline JSON sign-in, Arabic/English locale selection, guarded shell, and session persistence were verified on Android 16/API 36. A debug-signed ARM64 APK is available in `build/foundation/`.
- Reference sign-in, authenticated navigation and logout were exercised on Pixel 9 Pro Android 16. The delivered JSON loader supports the standard and recoverable auth scenarios. Card and finance fixtures are implemented. Network fixtures are implemented. Account and notifications fixtures are implemented.
- The working directory had an empty Git repository at planning intake. Capture the current branch and `git status --short` at implementation time. Use `HEAD` only if a commit exists.
- Mobile monorepo planning layout informed these documents. This is a standalone project.

## Packages

| ID | Status | Exit evidence |
| --- | --- | --- |
| [01 Foundation](step1_foundation/package.md) | Complete | [Foundation evidence](step1_foundation/package.md#evidence) |
| [02 Cards and finance](step2_cards_finance/package.md) | Complete | [Cards and finance evidence](step2_cards_finance/package.md#evidence-and-downstream-contract) |
| [03 Stations and prices](step3_stations_prices/package.md) | Complete | [Stations and prices evidence](step3_stations_prices/package.md#evidence-and-downstream-contract) |
| [04 Account services](step4_account_services/package.md) | Complete | [Account services evidence](step4_account_services/package.md#evidence-and-downstream-contract) |
| [05 Android acceptance](step5_android_acceptance/package.md) | Complete | [Release and verification](step5_android_acceptance/package.md#artifact-and-verification-evidence), [R01–R23 coverage](step5_android_acceptance/coverage.md) |
| [06 Figma redesign](step6_figma_redesign/package.md) | Complete | [Evidence](step6_figma_redesign/package.md#implementation-evidence), [Flutter handoff](step6_figma_redesign/flutter-handoff.md) |
| [07 Arabic-first AI support](step7_ai_support/package.md) | Offline demo verified · Connected support planned | [Offline implementation evidence](step7_ai_support/offline-implementation.md) |

## Decisions and anchors

- The first release covers all R01–R23 APK workflows and uses checked-in, bundled JSON for mock data. The implementation handoff includes the JSON files and editing instructions. See the [fixture contract](fixtures.md).
- The app uses Flutter 3.44.2, an API 24 minimum verified by an Android 7.0 install and smoke check, Arabic/English, an original visual identity, and synthetic local substitutes.
- R01–R23 identify reference observations in [reference audit](reference-audit.md). V01–V09 identify required checks in [verification](verification.md).
- [Architecture](architecture.md) defines proposed contracts and fixtures. Each package translates them into implementation and exit checks.
- When a follow-up changes scope or acceptance, record its effect in the relevant package and include the command, device and API when applicable, input state, result, and artifact checksum.

## Closure

Packages 01–05 are complete and archived in place. Package 06 and its Flutter implementation handoff are complete. Record new scope through `/spec-propose fuel-card-portal`.
