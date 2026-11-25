# Package 02 · Cards and finance

Status Complete · Dependency 01 complete · Estimate 4–6 h

## Objective and ownership

Own Home, Cards, Balances, card detail, notes, card financial history, Sales and offline export. Read R04–R10 and R14 from [reference audit](../reference-audit.md) and V02–V03/V06 from [verification](../verification.md). Coordinate route, locale and plugin wiring with the coordinator.

## Tasks

- [x] Create `cards.json` and `finance.json` with the states and stable joins in the [fixture contract](../fixtures.md). Hand off the card identifier contract and summary fields to 04 before proceeding with UI.
- [x] Deliver Home → Cards → Details vertical slice first. Derive summary metrics, wire shortcuts and recent activity View all to Notifications through the app routes.
- [x] Implement card number/plate search and status filter, activation metadata, optional RFID and delivery date, and shared 500-character note sheet with add/edit/delete and local persistence.
- [x] Build financial preview, full per-card log and balances. Reuse log behavior across entry points. Implement observed operation types and date range controls.
- [x] Build Sales rows and card/product/date filters. Add shared CSV/XLSX generation and Android save/share integration. Use applied scope, typed cells and cancellation paths.
- [x] Verify totals, filter combinations, empty/error handling, note boundaries and export files. Smoke Home → Cards → log and Balances → same card log on Android.

## Evidence and downstream contract

- Baseline is `main` at `a6a2352`, with the verified Foundation package already present in the worktree.
- The card ID contract is `FleetCard.id` and `FleetCard.accountId`. Package 04 can use `FleetData.forAccount(accountId).cards` with each card’s number, plate, and fuel product. Stable station and product IDs are documented in the fixture guide for Package 03.
- Home, balances and exports use integer minor units from the same account-scoped dataset. The 48-hour window uses the fixture anchor. Date displays and inclusive date filters use UTC. Android export uses the Storage Access Framework and the platform share chooser.
- `flutter analyze --no-pub` passed. `flutter test --no-pub` passed 13 tests, including joins, account scope, combined filters, quiet/empty states, note persistence and tombstones, and reopening filtered CSV/XLSX.

- `flutter test --no-pub integration_test/cards_finance_smoke_test.dart -d emulator-5556` passed on the Pixel 9 Pro AVD (Android 16/API 36, airplane mode with Wi-Fi off, 360 dp, 1.3× font scale). It checked the Home → Cards → Details path, search and status selection, note editing, operation filtering, return with search intact, the equivalent balances entry point, and Sales filtering.
- The separately installed ARM64 debug APK opened the same log offline. Native document export saved CSV and XLSX containing only deposit `op-002` for card `FC-0101`, with the typed numeric value of 100,000 SYP. The Android file picker and share chooser both canceled back to the filtered log.
- After switching the installed app back to Arabic, verified Home balances, Cards, card operations and Sales at 360 dp and 1.3× text scale.
- Artifact `build/cards-finance/fleet-cards-finance-debug.apk`. SHA-256 `256c3642c5a38381f642437a5f6a2be0f140f80619bbe7d4e90d9fcbec7050eb`.
- Prices and Notifications shortcuts have shared routes. Package 03 delivers price content. Package 04 delivers the inbox and connects its unread count to Home.

## Exit

Card identity is stable downstream. Both locales show fixture-driven cards, balances, operations and sales. Targeted tests pass and both export formats are validated. Update memory with commands and evidence.
