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

## Fuel availability color follow-up

- On `codex/fuel-card-portal` at `7aea3d0`, updated the shared availability badge for R11 and R12. Available is green, low stock is yellow, and unavailable is red. Both screens retain the per-fuel label and status icon. The fixture and filter behavior are unchanged.
- `flutter analyze --no-pub` and all 34 `flutter test --no-pub` tests passed. The added widget check verifies the three foreground and background pairs in the station list and station details. Their text contrast ratios are 6.38:1, 7.05:1, and 6.49:1.
- Built with `flutter build apk --release --target-platform android-arm64`. The branded release-mode APK is `/tmp/fleet-station-colors.ARh1ll/fleet-cards-golden-gate-station-colors-arm64.apk`, SHA-256 `57224ea9fa668d6aee073c0ca5e4a8de9cd494d834a23a8893309799bf0110d2`.
- Installed with `adb -s emulator-5554 install -r` on Android 16/API 36. Verified all three color, icon, and label combinations on the Arabic station list and South Depot details.

## Official station catalogue

- The standard network fixture contains the eight Golden Gate sites and thirteen Taiba partner sites published on the [official interactive map](https://goldengate.sy/?stationView=all#stations). It includes bilingual names, locations, coordinates, operators, and listed fuels. The station details link to the map for access to current availability through the customer portal.
- The operator filter combines with the existing city, fuel, and text filters. Unfiltered results place Golden Gate first. The sales and alert routes retain their existing station IDs with the corresponding official station labels.
- Support uses the same network repository for nearby searches. The Android app requests location in the foreground, chooses the nearest fixed station by straight-line distance, and sends its published destination to Google Maps.
- `flutter test --no-pub integration_test/stations_prices_smoke_test.dart -d emulator-5554` passed on the Pixel 3a Android 13/API 33 emulator. It exercised the default order, both operator filters, filter combinations and reset, station details, the directions handoff and both price bulletins.
- Built with `flutter build apk --debug --target-platform android-arm64 --no-pub` and installed with `adb -s emulator-5554 install -r`. SHA-256 `dfd2dfc2b8c20fd70bef0e1ab88f4cf95436b95d5173b6cd0449ddd452c06195`.

## Availability and operator card styling

- The test catalogue supplies a station-specific availability value for each published fuel. Both the list and detail screens show the three existing text and color treatments. The station cards use a pale gold gradient for Golden Gate and a pale green gradient for Taiba.
- `flutter test integration_test/stations_prices_smoke_test.dart -d emulator-5554` passed on Android 13/API 33. It verified both station gradients, the three availability colors in both views, and the Arabic availability heading.
- Built a development-signed release APK with `flutter build apk --release --target-platform android-arm,android-arm64`. The delivered APK with SHA-256 `e9c9de982e98aa89b6e5f3f37b62cffcfa81bb7a3e7c1a37a9cdc3b27aab33b0` was installed on the Pixel 3a emulator. A manual walkthrough confirmed both operator backgrounds and the availability labels.

- The Golden Gate card header now uses the same navy, ink, and gold as the app identity. The station heading and availability section share the same horizontal alignment as the Taiba cards. The Android smoke test passed and the revised ARM release APK was visually checked on the Pixel 3a. SHA-256 `657dd3f2ff2b0774b9e201000a3e13c87dffbb4d4e7fe8f400685c3113692651`.
