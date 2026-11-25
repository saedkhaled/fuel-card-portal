# Fleet Cards Demo

Android-first Flutter demo for a fuel-card customer portal. The planned app covers sign-in, cards and notes, balances, operations, stations, pricing, sales, subscriptions, top-up instructions, and notifications. It runs offline from synthetic JSON fixtures and supports Arabic and English.

## Run the Android demo

Use Flutter 3.44.2 and an Android emulator or USB-connected Android device.

```sh
flutter pub get
flutter run -d <android-device-id>
```

Sign in with demo number `0900000000` and code `246810`. The app starts in Arabic. Use the language button to switch to English. The number and code are read from [bundled JSON](assets/demo/standard/auth.json). See the [fixture editing guide](assets/demo/README.md) for the retry scenario and asset updates.

The demo includes sign-in, session restoration, Home, Cards, fuel-card notes, Balances, card operations, Sales, and Android CSV/XLSX export. Station and account services are scheduled in the packages below.

- [Implementation proposal](.spec/fuel-card-portal/propose.md)
- [Reference workflow inventory](.spec/fuel-card-portal/reference-audit.md)
- [JSON fixture contract](.spec/fuel-card-portal/fixtures.md)
- [Android acceptance checks](.spec/fuel-card-portal/verification.md)
- [Implementation rules](AGENTS.md) and [execution handoff](.spec/fuel-card-portal/prompt.md)

Stations, the local directions preview, and current and historical bulletins are available offline.
