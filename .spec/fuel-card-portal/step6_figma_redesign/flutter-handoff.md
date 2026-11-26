# Figma to Flutter handoff

[Redesign package](package.md) · [Android baseline coverage](../step5_android_acceptance/coverage.md)

Use the current Flutter router and synthetic fixture IDs for the redesigned views. Standard and reduced motion share the same route, focus, state and persistence behavior.

## Brand and components

| Design role | Reference | Flutter mapping |
| --- | --- | --- |
| Brand navy `#003262` | Stage app header sampled from an API 36 capture | Semantic primary, selected controls, and dark header surfaces |
| Logo blue `#044064` and gold `#DBA513` | Opaque pixels in Stage asset `Golden-Gate-Logo-Trans.png` | Logo artwork and brand accents. Use contrast-checked foreground/background pairs for text and states |
| Cairo | `assets/fonts/Cairo.ttf` in Stage APK | Arabic typography reference. Verify the font used for production and text metrics before bundling |
| Bottom navigation icons | Observed home, card, wallet, pin, and more outlines. Stage bundles Material Icons | Existing `PortalTab` roles, with full spoken labels and logical RTL order |
| Balance/card highlight | New gradient and geometric treatment | Shared presentation component with stable named elements for card-to-detail animation |
| List row, status, buttons, chips and field | New visual treatment using existing data and actions | Material surface, button, input, and chip roles in `portal_theme.dart`. State uses text with icon/color support |
| Filters, note editor and confirmations | Existing action flows and new sheet styles | Modal bottom sheet or dialog. Move focus to the heading or input on open and restore it to the invoking control on close |

Logo source is the user-supplied Stage APK. It remains outside the repository, along with the Stage APK, screen captures and credentials. Use synthetic values from [the fixture catalog](../fixtures.md). Isolate card IDs, dates, signed amounts and vehicle plates in RTL. Keep the back arrow directional and the logo, QR and numerals in their natural orientation.

For solid color pairs, white on Stage navy measures 12.86:1, gold on Stage navy 5.76:1, and logo blue on white 10.92:1. Reserve gold on white (2.23:1) for decorative accents. Check text contrast at the lightest point of any final gradient.

## Route and state map

| ID | Flutter route and design behavior |
| --- | --- |
| R01 | `/sign-in` phone entry, language, format error, unavailable account and recovery |
| R02 | `/sign-in/code` OTP entry, masked phone, countdown, wrong code, resend, expiry and Back |
| R03 | `/home` first-run alert prompt with Enable and Not now |
| R04 | `/home` total, recent activity and shortcuts. Bell and View all reach `/notifications` |
| R05 | `/cards` search, all/active/stopped filters, state messaging and scoped export |
| R06 | `/card/:cardId` details section for active and stopped cards |
| R07 | Note editor opens from the card list or detail. Save and delete update the same card-scoped note |
| R08 | `/card/:cardId` financial preview retains card context and opens the full operations log |
| R09 | `/card/:cardId/operations` shared by Cards and Balances. Type/date filter, clear, CSV/XLSX and cancellation |
| R10 | `/balances` aggregate, per-card balance, last operation, empty state and export |
| R11 | `/stations` search, city/fuel controls, availability and empty state. Back restores criteria |
| R12 | `/stations/:stationId` detail and optional `/stations/:stationId/directions` preview |
| R13 | `/price-bulletins` current and history, both linking to `/price-bulletins/:bulletinId` |
| R14 | `/sales` shared by Home and More with product/card/date filters, no-results and scoped export |
| R15 | `/more` organization and contact summary, service entries and settings |
| R16 | `/subscriptions` and `/subscriptions/:cardId` for card statuses, exempt cards and paid/unpaid invoice states |
| R17 | `/top-up` demo QR and copy actions, with native Android PNG save and share |
| R18 | `/information` FAQ expands in place and preserves reading order |
| R19 | `/notification-settings` alert preference and simulated station alert delivery |
| R20 | `/notifications` empty and populated states, unread update and linked destination |
| R21 | Language picker from `/sign-in` and `/more` switches direction while preserving context |
| R22 | `/about` version and synthetic support contact |
| R23 | Logout confirmation on `/more` cancels in place or returns to `/sign-in` with protected Back disabled |

## Motion implementation targets

| Trigger | Motion | Flutter and Back behavior |
| --- | --- | --- |
| OTP succeeds | 200 ms ease-out crossfade into Home; reveal the balance with a small opacity transition | Use the guarded route replacement. Focus Home when it appears. Back must never reveal a successful OTP challenge |
| Open card details | 260 ms ease-in-out shared transition for the card surface and identity | Use a stable card-ID tag for a shared transition. Reverse to the same scroll position on Back |
| Open filter or note editor | 200 ms ease-out modal sheet enter, with dimmed backdrop | Close sheet before popping route on Back. Cancel/Back preserves the previous committed values |
| Apply filter or save/delete | 140 ms ease-out state crossfade with explicit result feedback | Render the resulting data and announce completion. Subsequent input can interrupt any ongoing animation |

Use the platform accessibility setting exposed by Flutter to remove transition time and displacement when reduced motion is requested. Keep all controls and feedback available in that mode. File chooser, share sheet and Android keyboard behavior are verified on Android. A Figma representation documents the entry, return and cancellation points.

## Verification in Flutter

Re-run [V01–V09](../verification.md#automated-coverage) after implementation. Add a design comparison at 360 dp in both locales, 1.3× text, long labels, keyboard-open states, 48 dp targets, contrast, bidi runs, and TalkBack focus for the redesigned flows. Test both normal and reduced motion and the interaction's Back behavior. Use an installed offline Android build for native chooser and share regression checks.

## Flutter implementation evidence

- Implemented 25 November 2026 from `codex/fuel-card-portal` at `52f7d00`, with the existing Package 06 planning edits preserved. The redesign uses the Figma navy, gold and paper palette, bundled Cairo and Inter typefaces, mirrored tab order, and shared balance and card surfaces. The account, authentication, finance, station, notification and file-action data contracts use the existing code paths and fixtures.
- The original artwork is supplied to branded builds as `PORTAL_LOGO_BASE64` via an external `--dart-define-from-file`. The source build defaults to the demo name and fuel mark. The fonts come from Google Fonts revision `6ebe737e44fd64ee736bbc6feed6136a6dbfd222`, with their licenses bundled.
- `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze --no-pub` and all 27 local tests passed. The new widget coverage exercises mirrored navigation and card details at 360 dp and 1.3× text, checks Arabic currency sign ordering, and exercises the reduced-motion card route.
- `flutter test integration_test/portal_smoke_test.dart -d emulator-5560 --dart-define-from-file=<brand-json>` passed all five tests on a task-owned Pixel 9 Android 16/API 36 emulator. Coverage includes session and locale switching, cards and notes, balances, Sales, stations, prices, top-up clipboard contents, invoices, inbox and notification settings, and the large fleet.
- Built `fleet-cards-redesign.apk` with `flutter build apk --release --dart-define-from-file=<brand-json>` in an isolated copy after workspace I/O delays. SHA-256 `1b12085ac2de6bbddaa2d8763a411ca441b179670434a9230b557d2aa71ce444`. The release-mode APK uses development signing and passed `apksigner verify`. The app ID is `com.example.fleet_cards_demo`, min SDK 24, target SDK 36, with ARM64, ARMv7 and x86-64 ABIs.
- Installed the release-mode build on Pixel 9 Pro Android 16/API 36. Checked Arabic sign-in and English/Arabic Home and Cards at 360 dp, 1.3× text, airplane mode and Wi-Fi off. Opened and canceled the native CSV destination picker during the installed walkthrough. The final APK copied the demo transfer destination and Android Paste reproduced `DEMO-TRANSFER-104` in the Cards search field. Full spoken TalkBack traversal and API 24 were outside this redesign regression run.

## Open saved exports

- The Android save adapter opens the saved document with its original MIME type and a read-only URI grant after the output stream closes. A missing viewer leaves the file saved. Canceling the picker leaves the app on the originating screen.
- Verified the branded release on Android 16/API 36 in airplane mode. A temporary test viewer opened the saved CSV and read its rows, and opened the saved XLSX and read its worksheet entry. After removing the test viewer, CSV still saved to Downloads. The downloaded 512 × 512 QR PNG opened in Google Photos. The CSV picker cancellation returned to Balances.
- `flutter analyze --no-pub` and all 27 local tests passed. Built `fleet-cards-open-after-save.apk` with `flutter build apk --release --dart-define-from-file=<brand-json>`. SHA-256 `9762a57f1d6631053f0fa4fd38cbb10440c8154da85bc793c6a699e387a5d3ed`.

## Original launcher icon follow-up

- On branch `codex/fuel-card-portal` at `7aea3d0`, added an Android build option for the user-supplied Stage launcher resources. The brand artwork is supplied from `~/.config/fleet-cards-demo/launcher-res` and remains outside Git. The Stage APK SHA-256 is `9e49e4d15367aa65aa73f4ae02d2845a9475c02e86c11684743adafcab55b47f`.
- `aapt2 dump resources` and `aapt2 dump xmltree` confirmed the legacy mipmaps and adaptive foreground in five densities, the white background, and the Stage inset. All ten packaged PNGs matched the original APK byte for byte. With `PORTAL_LAUNCHER_RES` pointed at an absent directory, `./gradlew --offline :app:processReleaseMainManifest` resolved the demo icon.
- Built with `flutter build apk --release --target-platform android-arm64`. `apksigner verify` passed. APK `/tmp/fleet-launcher-qa.vx6jNL/fleet-cards-golden-gate-branded-arm64.apk`, SHA-256 `fd46362180456b0ae88a4564adc285cf049049dc310c0644a02281153294ea79`.
- Installed with `adb -s emulator-5554 install -r` on Android 16/API 36. Compared the icons in Android App Info. The two 144 × 144 icon crops were pixel-identical. Launched the updated app and confirmed its activity was in the foreground.

### Bundled Android launcher icon

- The default Android launcher icon now uses the public Golden Gate mark with the existing brand blue. An explicit `PORTAL_LAUNCHER_RES` remains available for custom Android launcher resources.
- AAPT2 compiled and linked the bundled launcher resources against Android API 36. The resource table contains both the legacy and Android 8+ adaptive variants.
