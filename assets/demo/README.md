# Demo fixtures

The app loads `manifest.json` and the selected scenario's bundled assets. `standard/auth.json` defines the synthetic account ID, phone, six-digit code, validity, and resend delay. Change a fixture in the source tree, run `flutter test test/demo_fixtures_test.dart`, and rebuild the app to ship the edited asset.

The default scenario is `standard`. Set `--dart-define=DEMO_SCENARIO=recoverable_error` on `flutter run` to verify that the first code request fails and a retry succeeds. Future packages add the feature JSON files listed in the [fixture contract](../../.spec/fuel-card-portal/fixtures.md). Declare new scenario directories explicitly in `pubspec.yaml`.

Local preferences store language, the demo account ID, and the alert prompt choice. Clearing this app's data restores its original state.

Package 02 adds `cards.json` and `finance.json`. Keep the card ID stable across balances, operations, and sales. The finance data uses two-decimal SYP amounts stored as integer minor units and UTC timestamps. The fixture clock anchor keeps the dashboard’s 48-hour activity reproducible. The `quiet` scenario moves that anchor forward and keeps historical rows. The `empty` scenario provides empty cards and finance collections.

Package 03 can join fixture sale stations with IDs `dam-depot` and `hms-junction`. The shared product IDs are `diesel`, `benzene`, and `premium`. Package 04 can join subscriptions and transfer notes by `FleetCard.id`, scoped to `FleetCard.accountId`.

Package 03 adds `network.json` with bilingual product, city and station labels, availability, optional demo directions, and price bulletins. Station IDs link to finance records. A product filter matches stations that carry that product, even if its current availability is low or unavailable. Bulletin dates use `YYYY-MM-DD` and prices are integer SYP minor units per liter. Set `currentBulletinId` to the latest bulletin. The `empty` scenario uses an empty station and bulletin dataset.

Package 04 adds `account.json` and `notifications.json`. Join profiles and inboxes on demo account ID and subscription rows on card ID. An inbox item can link to a station or a bulletin from the network fixture. Keep the QR payload in the `FLEET-CARDS-DEMO:` namespace and the transfer destination and note clearly marked as demo. The `quiet` and `empty` scenarios ship without inbox items or station events. Alert preferences, delivered events and read markers stay on the device, scoped to the scenario and account.

Acceptance also ships `large_fleet`, which keeps the standard sample cards and adds 176 synthetic cards with matching balances, operations and subscriptions. Select it with `--dart-define=DEMO_SCENARIO=large_fleet`. The acceptance tests validate the joins, exercise scrolling and search, and count all 180 rows in a full export.
