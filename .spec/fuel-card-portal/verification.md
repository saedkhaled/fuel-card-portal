# Verification and handoff

## Automated coverage

| Check | Test level | Acceptance |
| --- | --- | --- |
| V01 Auth and navigation | Unit, widget, Android | Format validation, one challenge at a time, correct and incorrect code, resend/expiry with fake time, process restart restore, logout cancel/confirm, protected Back. |
| V02 Cards and notes | Unit, widget, Android | Active/stopped and combined search/status, activation variants, note add/edit/delete and max length, separate card namespaces, persistence after restart. |
| V03 Finance and sales | Unit, widget, Android | Matching totals, card scoping across both entry points, signed values, inclusive dates, invalid date range handling, product/card filtering and empty state. |
| V04 Stations and prices | Unit, widget, Android | City/product and text queries combine, detail and Back, conditional directions preview, current and previous price detail. |
| V05 Account services | Widget, Android | Subscription history, simulated top-up, transfer-note copy, FAQ expansion, alert setting, quiet inbox, populated inbox, About. |
| V06 Files and OS | Unit, Android | CSV and XLSX contain expected synthetic IDs and row counts. Verify escaping, workbook sheet/headers and numeric cells. Share and save/cancel use Android UI. QR image contains an inert demo payload. Inspect files on disk. |
| V07 Language and accessibility | Widget, Android | Both directions, predictable navigation and input behavior, mixed-direction IDs and amounts, 360 dp and 1.3× system text, long translated labels, focus and screen reader traversal. |
| V08 Offline and recovery | Android, unit | Airplane-mode sign-in and main routes, deterministic failure/retry, large list without visible stalls, release builds without external services. Confirm scope-sensitive logging and inspect release manifest. |
| V09 JSON fixtures | Unit, widget, Android | Decode all shipped scenarios, reject broken IDs and malformed files, verify fixture edits reach screens and exports, check overlay reset and persistence, and confirm assets are packaged. |

Use Flutter unit and widget tests for deterministic behavior and the SDK `integration_test` package for the cross-feature journey. Drive Android system chooser, save confirmation and airplane-mode checks with ADB/manual inspection as needed. Choose a task-owned emulator if another session is using the device. [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests).

```bash
flutter doctor -v
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
adb devices -l
flutter test integration_test/portal_smoke_test.dart -d <android-device-id>
flutter build apk --release
adb -s <android-device-id> install -r build/app/outputs/flutter-apk/app-release.apk
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
```

The Android health check covers Flutter, JDK, Gradle and SDK components. Warnings for untargeted platforms are informational. Use demo signing for the sideload artifact and document its configuration. Where a release build uses local debug signing, label it a development-signed release-mode APK. Record ABI, application ID, version, API level, locale, command and result. Document installation or Android platform gaps with the actual outcome.

## Coverage and JSON handoff

Record one acceptance result per R01–R23 item with the entry point, control invoked, observed outcome, scenario and linked test or device evidence. Include secondary actions such as Clear Filters, export cancellation, OTP resend and expiry, and logout cancellation. Mark unverified reference outcomes separately from tested demo outcomes.

Run the same loader against committed assets in tests and on Android. Exercise one fixture-only change to a card balance and confirm the detail view, aggregate and export agree. Restore the tracked fixture afterward. Verify that seeded note deletion survives restart and reinstalling or clearing app data restores the fixtures. See the [fixture contract](fixtures.md).

## Installed-app walkthrough

1. Launch fresh in airplane mode. Verify Arabic phone validation, English switch, synthetic OTP, and first-run prompt dismissal.
2. Use Home → Cards, apply Active and search for a fixture plate. Open details, change a note, then use the financial preview and full log. Check a card-scoped type/date filter. Reopen the app and verify the note.
3. Use Balances → Operations on the same card and verify matching scope. Generate both export formats. Open the sales route from Home, apply product and date filters, and sample the native share chooser.
4. Visit Stations, filter by city/product, open details and mock directions. Visit one current and one former bulletin.
5. Under More, open invoice history, copy a synthetic transfer note, preview the demo QR, toggle alerts, check FAQ and About, then open the inbox from both its menu entry and Home.
6. Switch back to Arabic. Recheck representative screens and system text scaling. Cancel logout, then confirm it. Relaunch and verify sign-in is required.

Evidence includes pass/fail commands, the APK path and checksum, meaningful synthetic screenshots or notes, filtered file samples, emulator details and explicit unverified cases. Keep temporary captures outside the repository unless deliberately included in a handoff.
