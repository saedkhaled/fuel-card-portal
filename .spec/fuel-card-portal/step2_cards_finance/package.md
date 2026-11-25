# Package 02 · Cards and finance

Status awaiting 01 · Estimate 4–6 h

## Objective and ownership

Own Home, Cards, Balances, card detail, notes, card financial history, Sales and offline export. Read R04–R10 and R14 from [reference audit](../reference-audit.md) and V02–V03/V06 from [verification](../verification.md). Coordinate route, locale and plugin wiring with the coordinator.

## Tasks

- [ ] Create `cards.json` and `finance.json` with the states and stable joins in the [fixture contract](../fixtures.md). Hand off the card identifier contract and summary fields to 04 before proceeding with UI.
- [ ] Deliver Home → Cards → Details vertical slice first. Derive summary metrics, wire shortcuts and recent activity View all to Notifications through the app routes.
- [ ] Implement card number/plate search and status filter, activation metadata, optional RFID and delivery date, and shared 500-character note sheet with add/edit/delete and local persistence.
- [ ] Build financial preview, full per-card log and balances. Reuse log behavior across entry points. Implement observed operation types and date range controls.
- [ ] Build Sales rows and card/product/date filters. Add shared CSV/XLSX generation and Android save/share integration. Use applied scope, typed cells and cancellation paths.
- [ ] Verify totals, filter combinations, empty/error handling, note boundaries and export files. Smoke Home → Cards → log and Balances → same card log on Android.

## Exit

Card identity is stable downstream. Both locales show fixture-driven cards, balances, operations and sales. Targeted tests pass and both export formats are validated. Update memory with commands and evidence.
