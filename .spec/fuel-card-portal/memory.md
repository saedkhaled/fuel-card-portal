# Fuel-card portal execution memory

Updated 25 November 2026

## Current state

- 03 Stations and prices completed. The bundled network fixture, station filters, offline directions, and bulletin history passed Arabic/English Android offline checks. The ARM64 debug APK is in `build/stations-prices/`.

- 02 Cards and finance completed. JSON-backed Home, cards and notes, balances, operations, sales, and CSV/XLSX passed Android 16 offline checks. The ARM64 debug APK is in `build/cards-finance/`.

- 01 Foundation completed on the checkout of `main` from `a6a2352`. Offline JSON sign-in, Arabic/English locale selection, guarded shell, and session persistence were verified on Android 16/API 36. A debug-signed ARM64 APK is available in `build/foundation/`.
- Reference sign-in, authenticated navigation and logout were exercised on Pixel 9 Pro Android 16. The delivered JSON loader supports the standard and recoverable auth scenarios. Card and finance fixtures are implemented. Network and account fixtures remain in packages 03 and 04.
- The working directory had an empty Git repository at planning intake. Capture the current branch and `git status --short` at implementation time. Use `HEAD` only if a commit exists.
- Mobile monorepo planning layout informed these documents. This is a standalone project.

## Packages

| ID | Status | Exit evidence |
| --- | --- | --- |
| [01 Foundation](step1_foundation/package.md) | Complete | [Foundation evidence](step1_foundation/package.md#evidence) |
| [02 Cards and finance](step2_cards_finance/package.md) | Complete | [Cards and finance evidence](step2_cards_finance/package.md#evidence-and-downstream-contract) |
| [03 Stations and prices](step3_stations_prices/package.md) | Complete | [Stations and prices evidence](step3_stations_prices/package.md#evidence-and-downstream-contract) |
| [04 Account services](step4_account_services/package.md) | Ready | Pending |
| [05 Android acceptance](step5_android_acceptance/package.md) | Awaiting 03–04 | Pending |

## Decisions and anchors

- The first release covers all R01–R23 APK workflows and uses checked-in, bundled JSON for mock data. The implementation handoff includes the JSON files and editing instructions. See the [fixture contract](fixtures.md).
- The plan uses a single app, Flutter 3.44.2, an API 24 minimum candidate, Arabic/English, an original visual identity, and synthetic local substitutes. Toolchain versions are local observations. API 24 acceptance has yet to run.
- R01–R23 identify reference observations in [reference audit](reference-audit.md). V01–V09 identify required checks in [verification](verification.md).
- [Architecture](architecture.md) defines proposed contracts and fixtures. Each package translates them into implementation and exit checks.
- Later package verification is pending. Record command, device/API when applicable, input state, result, and artifact checksum in the package and link from here. When a follow-up changes scope or acceptance, record its effect before updating statuses.

## Next chat command

```text
/spec-apply fuel-card-portal step4_account_services
```
