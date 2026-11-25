# Fleet Cards Demo

Android-first Flutter demo for a fuel-card customer portal. It runs offline from synthetic JSON fixtures and supports Arabic and English.

## Run the Android demo

Use Flutter 3.44.2 and an Android emulator or USB-connected Android device.

```sh
flutter pub get
flutter run -d <android-device-id>
```

Sign in with demo number `0900000000` and code `246810`. The app starts in Arabic. Use the language button to switch to English. The number and code are read from [bundled JSON](assets/demo/standard/auth.json). See the [fixture editing guide](assets/demo/README.md) for the retry scenario and asset updates.

The demo includes sign-in, session restoration, Home, Cards, fuel-card notes, Balances, card operations, Sales, Android CSV/XLSX export, Stations, offline demo directions, and price bulletins. More includes the company profile, subscription and invoice history, simulated QR top-up, FAQ, notifications, language settings, app information and sign-out.

- [Implementation proposal](.spec/fuel-card-portal/propose.md)
- [Reference workflow inventory](.spec/fuel-card-portal/reference-audit.md)
- [JSON fixture contract](.spec/fuel-card-portal/fixtures.md)
- [Android acceptance checks](.spec/fuel-card-portal/verification.md)
- [Implementation rules](AGENTS.md) and [execution handoff](.spec/fuel-card-portal/prompt.md)
