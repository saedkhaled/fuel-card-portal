# Fleet Cards Demo

Android-first Flutter demo for a fuel-card customer portal. It runs offline from synthetic JSON fixtures and supports Arabic and English.

## Run the Android demo

Use Flutter 3.44.2 and an Android emulator or USB-connected Android device.

```sh
flutter pub get
flutter run -d <android-device-id>
```

Sign in with demo number `0900000000` and code `246810`. The app starts in Arabic. Use the language button to switch to English. The number and code are read from [bundled JSON](assets/demo/standard/auth.json). See the [fixture editing guide](assets/demo/README.md) for the retry scenario and asset updates.

The demo includes sign-in, session restoration, Home, Cards, fuel-card notes, Balances, card operations, Sales, Android CSV/XLSX export, Stations, offline demo directions, and price bulletins. The center Support tab answers sample Arabic questions offline about balances, stations, top-up, subscription invoices, and fuel prices. More includes Balances, the company profile, subscription and invoice history, simulated QR top-up, FAQ, notifications, language settings, app information and sign-out.

- [Implementation proposal](.spec/fuel-card-portal/propose.md)
- [Reference workflow inventory](.spec/fuel-card-portal/reference-audit.md)
- [JSON fixture contract](.spec/fuel-card-portal/fixtures.md)
- [Android acceptance checks](.spec/fuel-card-portal/verification.md)
- [Implementation rules](AGENTS.md) and [execution handoff](.spec/fuel-card-portal/prompt.md)

## Run Golden Gate AI Assistant

Run `flutter run` on Android or start debugging from VS Code. The build includes the no-cost prototype’s Firebase client configuration. The demo sign-in uses `0900000000` and `246810`. New debug installations need a one-time App Check debug token registration. Release APKs use Play Integrity and can fall back to local support when the service is unavailable. To force local support in development, use `flutter run --dart-define=SUPPORT_OFFLINE_ONLY=true`. See the [Gemini pilot guide](.spec/fuel-card-portal/step7_ai_support/gemini-pilot.md) for configuration overrides and device verification.

## Build a sideload APK

The baseline APK is at `build/android-acceptance/fleet-cards-demo-release.apk`. See the [baseline acceptance handoff](.spec/fuel-card-portal/step5_android_acceptance/package.md) for its checksum and API 24 and 36 results. See the [Flutter redesign handoff](.spec/fuel-card-portal/step6_figma_redesign/flutter-handoff.md) for the redesigned build.

```sh
flutter pub get
flutter build apk --release
adb -s <android-device-id> install -r build/app/outputs/flutter-apk/app-release.apk
```

The release-mode demo uses the local Android debug key for sideloading. Use Flutter's normal build command so it regenerates the Android plugin registrant for release mode.

To set the in-app branding, pass `--dart-define-from-file=/absolute/path/to/portal-brand.json` to `flutter run` or `flutter build apk`. Keep this JSON outside the repository and set its `PORTAL_LOGO_BASE64` value to the base64-encoded bytes of an authorized transparent PNG logo. Builds without that value use the demo's own fuel icon and name. Cairo and Inter are bundled offline, with their SIL Open Font Licenses in [assets/fonts](assets/fonts).

The standard Android build uses the bundled Golden Gate launcher icon for both adaptive and older Android launchers. It uses the gold mark from the [official Golden Gate site](https://goldengate.sy/assets/favicon.png). To use a different authorized launcher, set `PORTAL_LAUNCHER_RES` to an external Android resource directory containing `mipmap/ic_launcher` and its dependencies.

The cross-feature test resets demo state on the test app installation. Run it against a disposable Android emulator.

```sh
flutter test integration_test/portal_smoke_test.dart -d <android-device-id>
```
