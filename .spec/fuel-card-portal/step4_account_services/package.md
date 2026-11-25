# Package 04 · Account services

Status Complete · Card contract from 02 available · Estimate 3–4 h

## Objective and ownership

Own More/account, notifications and local service surfaces. Read R03 and R15–R23 from [reference audit](../reference-audit.md) and V05 from [verification](../verification.md).

## Tasks

- [x] Create `account.json` and `notifications.json` under the [fixture contract](../fixtures.md). Build the profile and settings menu using the loaded account and contact data. Link existing Sales, Prices and Notifications routes.
- [x] Build subscription summary, per-card items and invoice history using stable card IDs and mock invoice states.
- [x] Build simulated top-up with inert QR, demo destination, instructions, local download/share of the image and copy of synthetic account or transfer-note text.
- [x] Implement expandable information, persistent station-alert setting, first-run prompt integration, and inbox. Use a seeded local station availability event to exercise the on/off behavior. Use the same read/unread dataset for inbox and Home.
- [x] Add language, About and logout confirmation. Integrate guarded navigation and clear session-scoped state.
- [x] Verify subscription, top-up, toggle, quiet/populated inbox, locale persistence, and cancel/confirm logout using tests and Android smoke.

## Evidence and downstream contract

- Baseline is `main` at `a6a2352` with Packages 01–03 already present in the working tree.
- Subscription rows join on `FleetCard.id` and each account has its own inbox. Notification links resolve to the existing station and bulletin routes. Preferences persist by scenario and account. The first enable delivers the seeded in-app station event once, and turning alerts off leaves delivered items in history.
- The app reads its version from Android. The bundled transfer destination and clipboard notes are synthetic. QR exports use the existing Android file adapter with a white quiet zone and a text-only demo payload.
- `flutter analyze --no-pub` passed and `flutter test --no-pub` passed 24 tests. Account coverage includes fixture joins, paid/unpaid/exempt invoices, inert QR payload validation, PNG encoding, persisted alerts and read markers, and the quiet inbox.

- `flutter test --no-pub integration_test/account_services_smoke_test.dart -d emulator-5556` passed. It verified account profile, invoice history, the Android clipboard contents for destination and card note, FAQ expansion, alert activation, the inbox and Home unread count, actual Android version metadata, Arabic RTL, and cancel/confirm sign-out.
- The separately installed APK verified the first-run Enable action, native PNG save and share cancellation on Pixel 9 Pro Android 16/API 36 in airplane mode, Wi-Fi off, 360 dp width, and 1.3× text size. Decoding the saved PNG with Vision returned exactly `FLEET-CARDS-DEMO:TRANSFER-104`.
- Built with `flutter build apk --debug --target-platform android-arm64 --no-pub`. Artifact `build/account-services/fleet-account-services-debug.apk`, SHA-256 `458ef32800f454aaabd956220a313a45881e295bbfb2383c61f3525264acf43d`.

## Exit

All More entries are reachable, render in both directions and use local data. File/clipboard actions are checked with synthetic content. Record evidence and hand off remaining cross-feature checks to 05.
