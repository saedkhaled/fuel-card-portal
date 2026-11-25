# Package 05 · Android acceptance

Status Complete · Release APK verified on API 24 and 36

## Objective and ownership

Integrate the full Android app, verify the [acceptance matrix](../verification.md), and produce a tested, installable demo APK and a short build/run handoff.

## Tasks

- [x] Record the route, action outcome, JSON scenario, and evidence for each R01–R23 requirement. Validate and hand off the bundled JSON files and editing guide. Check all locale strings, empty/error states, phone-sized layouts and isolated synthetic data. Fix scoped defects.
- [x] Run format, analyze, tests, and the full Android integration journey. Exercise system save/share, note restart persistence, Back guard, Arabic RTL and airplane mode on the installed APK.
- [x] Verify the declared minimum on an API 24 AVD if available. Record actual tested API levels. Inspect merged permissions, application ID and supported ABIs.
- [x] Build and install the final demo APK. Verify fresh sign-in on that binary. Record checksum, build commands, signing mode, demo login and run instructions. Keep deliverables free of staging data.
- [x] Reconcile all package states and evidence in memory. Summarize verified behavior and any remaining gaps.

## Artifact and verification evidence

- Baseline is `main` at `a6a2352` with Packages 01–04 already present in the working tree. Built from an isolated copy of the current source after workspace I/O stalls. Use `flutter pub get` and `flutter build apk --release`. The normal Flutter invocation regenerates release plugin metadata.
- Release-mode demo artifact is `build/android-acceptance/fleet-cards-demo-release.apk`. SHA-256 `960b1b69b2c3eec56507f6e0e60cdcf8246575f0653df32ed3dd0890e2e3f472`. Package `com.example.fleet_cards_demo`, version `0.1.0+1`, min SDK 24, target SDK 36, ABIs arm64-v8a, armeabi-v7a and x86_64. Verified APK signature v2 with the local Android debug certificate. The merged manifest requests only the app-scoped dynamic-receiver permission.
- `dart format --output=none --set-exit-if-changed lib test integration_test` and `flutter analyze --no-pub` passed. All 26 local tests passed. The acceptance fixture test checks all five scenarios, including 180 cards and header plus 180 exported rows. A separate in-memory fixture edit changed the first card balance to 187,700 SYP and produced the matching 381,700 SYP Home total and CSV value without changing a checked-in fixture.
- `flutter test integration_test/portal_smoke_test.dart -d emulator-5556` passed all five tests on the Android 16/API 36 AVD. The suite exercised Foundation, Cards and finance, Stations and prices, Account services, and scrolling and filtering the bundled 180-card list.
- The exact release-mode APK passed fresh sign-in on Pixel 9 Pro Android 16/API 36 in airplane mode, Wi-Fi disabled, 360 dp width and 1.3× text. The walkthrough verified note edit/delete with cold restarts, scoped CSV/XLSX saves with deposit `op-002`, canceled native save/share, local station directions, current bulletin, native QR save and Arabic sign-out. The saved QR decodes to `FLEET-CARDS-DEMO:TRANSFER-104`. Clearing the disposable installation with `adb shell pm clear com.example.fleet_cards_demo` restored the seeded `North route` note.
- `adb -s emulator-5558 install <apk>` passed on the Android 7.0/API 24 AOSP ARM64 emulator. With no active default network, the fresh installation launched, accepted the bundled Arabic sign-in flow and loaded Home and Cards, including `FC-0101` and the seeded note. API 24 coverage was a minimum-version smoke check. Runtime checks used ARM64 emulators.
- V07 includes Arabic/English layout, the Android keyboard and scaled text. On API 36, `adb shell dumpsys accessibility` confirmed TalkBack was bound with touch exploration enabled. Its visible focus moved from the Arabic sign-in title to the language sheet and returned to the title when the sheet closed. Full spoken traversal across screens remains unverified on the headless AVD.
- Reference coverage and route evidence are recorded in the [coverage matrix](coverage.md). The shipped fixtures are documented in the [editing guide](../../../assets/demo/README.md).

## Sideload

```sh
adb -s <android-device-id> install -r build/android-acceptance/fleet-cards-demo-release.apk
```

Use demo number `0900000000` and code `246810`. The first launch starts in Arabic. Switch to English from the language control on sign-in or under More. See the [build and run guide](../../../README.md).

## Exit

The demo artifact is installable and the evidence matrix is complete with outcomes. Package status and handoff reflect the tested build.
