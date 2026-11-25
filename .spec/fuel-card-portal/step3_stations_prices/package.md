# Package 03 · Stations and prices

Status Ready · Dependency 01 complete · Estimate 2–3 h

## Objective and ownership

Own station and prices features and scoped tests. Read R11–R13 from [reference audit](../reference-audit.md) and V04 from [verification](../verification.md). Coordinate route and localization wiring with the coordinator.

## Tasks

- [ ] Create `network.json` as specified in the [fixture contract](../fixtures.md). Include fictional bilingual station and product data, all three availability states, conditional mock directions, and current and historical bulletins.
- [ ] Implement station name/address search, city and product filters, details and a local directions preview. Preserve applied filters with Back.
- [ ] Implement current bulletin, ordered history and shared details with explicit dates and prices.
- [ ] Verify filters, empty/error paths, history, conditional actions and both directions in targeted tests and an emulator smoke.

## Exit

Station and bulletin journeys work in airplane mode from real tabs/shortcuts. Publish route hooks and test evidence.
