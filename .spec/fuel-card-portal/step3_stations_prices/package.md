# Package 03 · Stations and prices

Status Complete · Dependency 01 complete · Estimate 2–3 h

## Objective and ownership

Own station and prices features and scoped tests. Read R11–R13 from [reference audit](../reference-audit.md) and V04 from [verification](../verification.md). Coordinate route and localization wiring with the coordinator.

## Tasks

- [x] Create `network.json` as specified in the [fixture contract](../fixtures.md). Include fictional bilingual station and product data, all three availability states, conditional mock directions, and current and historical bulletins.
- [x] Implement station name/address search, city and product filters, details and a local directions preview. Preserve applied filters with Back.
- [x] Implement current bulletin, ordered history and shared details with explicit dates and prices.
- [x] Verify filters, empty/error paths, history, conditional actions and both directions in targeted tests and an emulator smoke.

## Evidence and downstream contract

- Baseline is `main` at `a6a2352` with verified Packages 01 and 02 already in the working tree.
- The network fixture shares station and fuel IDs with finance. Package 04 can use `PortalDestinations.station(id)` for station alerts and `PortalDestinations.prices` for the bulletin shortcut. Station filtering matches the products a station carries and displays current availability separately.
- `flutter analyze --no-pub` and `flutter test --no-pub` passed. All 18 local tests passed, including text/city/product intersections, stable sale joins, ordered history, date validation, missing-fixture retry, empty screens, and switching queries after filter reset.
- `flutter build apk --debug --target-platform android-arm64 --no-pub` built the APK. `build/stations-prices/fleet-stations-prices-debug.apk` contains the network and empty-network assets. SHA-256 `f44bd38d27980b062d9fac7cbbe7ccdf029e26de364a3c5c11aa808ea57f7ffb`.

- `flutter test --no-pub integration_test/stations_prices_smoke_test.dart -d emulator-5556` passed on a Pixel 9 Pro AVD with Android 16/API 36, airplane mode on, Wi-Fi off, 360 dp width and 1.3× text. It covered applying combined criteria, details and Back, restoring the query and chips, clearing filters, conditional directions, current and previous bulletin prices, and Arabic RTL navigation.

- The installed APK rendered Arabic directions and bulletin prices offline. A native touch check on the final build opened filters with the software keyboard visible, verified it stayed closed after Apply, checked details and Back, cleared both filters, and found a station with no directions action. The final focus change also passed Flutter analysis and the five station/price tests.

## Exit

Station and bulletin journeys work in airplane mode from real tabs/shortcuts. Publish route hooks and test evidence.
