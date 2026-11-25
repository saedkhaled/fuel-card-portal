# Fuel-card portal execution memory

Updated 25 November 2026

## Current state

- Planning complete. No Flutter code or demo artifact exists.
- Ready package is 01 Foundation. Implementation begins when requested.
- Reference sign-in, authenticated navigation and logout were exercised on Pixel 9 Pro Android 16. Fixture/contract design is proposed.
- The working directory had an empty Git repository at planning intake. Capture the current branch and `git status --short` at implementation time. Use `HEAD` only if a commit exists.
- Mobile monorepo planning layout informed these documents. This is a standalone project.

## Packages

| ID | Status | Exit evidence |
| --- | --- | --- |
| [01 Foundation](step1_foundation/package.md) | Ready | Pending |
| [02 Cards and finance](step2_cards_finance/package.md) | Awaiting 01 | Pending |
| [03 Stations and prices](step3_stations_prices/package.md) | Awaiting 01 | Pending |
| [04 Account services](step4_account_services/package.md) | Awaiting 01 and 02 card contract | Pending |
| [05 Android acceptance](step5_android_acceptance/package.md) | Awaiting 02–04 | Pending |

## Decisions and anchors

- The first release covers all R01–R23 APK workflows and uses checked-in, bundled JSON for mock data. The implementation handoff includes the JSON files and editing instructions. See the [fixture contract](fixtures.md).
- The plan uses a single app, Flutter 3.44.2, an API 24 minimum candidate, Arabic/English, an original visual identity, and synthetic local substitutes. Toolchain versions are local observations. API 24 acceptance has yet to run.
- R01–R23 identify reference observations in [reference audit](reference-audit.md). V01–V09 identify required checks in [verification](verification.md).
- [Architecture](architecture.md) defines proposed contracts and fixtures. Each package translates them into implementation and exit checks.
- Verification evidence is pending. Record command, device/API when applicable, input state, result, and artifact checksum in the package and link from here. When a follow-up changes scope or acceptance, record its effect before updating statuses.

## Next chat command

```text
/spec-apply fuel-card-portal step1_foundation
```
