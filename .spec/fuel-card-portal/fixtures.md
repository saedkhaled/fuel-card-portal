# Bundled JSON fixture contract

The implementation delivers the editable JSON files under `assets/demo/` with a short guide for changing a record, adding a scenario, running validation, and rebuilding the APK. The default Android experience loads the shipped files through Flutter’s asset bundle. Use these same files in tests so decode and data validation cover what gets packaged.

## Files and ownership

| JSON file | Owner | Contents and reference coverage |
| --- | --- | --- |
| `manifest.json` | 01 Foundation | Schema version, default scenario, and scenario-to-file mappings. Optional scenario clock anchor and recoverable failure configuration. |
| `auth.json` | 01 Foundation | Synthetic account IDs, demo phone and verification code, challenge validity and resend settings. R01–R03, R23. |
| `cards.json` | 02 Cards and finance | Cards keyed by ID and account ID, status, fuel and plan, plate, optional activation, RFID, delivery date and seed note. R05–R07. |
| `finance.json` | 02 Cards and finance | Card balances, operations, and sales records. Include all observed operation types and dates suitable for filtering. R04, R08–R10, R14. |
| `network.json` | 03 Stations and prices | Shared fuel products, stations, cities, availability, mock directions, and dated price bulletins. R11–R13. |
| `account.json` | 04 Account services | Profiles, per-card subscriptions, invoices, FAQs, demo top-up destination, inert QR payload, transfer-note template, and synthetic support details. R15–R18, R22. |
| `notifications.json` | 04 Account services | Inbox items, initial read state, default settings and a local station-availability event for exercising the alert toggle. R03–R04, R19–R20. |

Keep scenario files in directories such as `assets/demo/standard/`. The manifest may point to shared files for unchanged data. Each mapping chooses a complete dataset for its domain. R21 uses the app’s Arabic/English ARB files for interface strings and reads localized values from JSON for data such as station names. R23 uses the JSON demo account with the local session lifecycle.

## Representation and consistency

- Use stable string IDs, short string enum values, explicit nullable fields, and `ar`/`en` keys for bilingual fixture content. Keep identifiers such as phone numbers and plates as strings to preserve leading zeros.
- Store SYP values as integer minor units with one declared scale. Use ISO dates for date-only fields and UTC timestamps for events. Give time-sensitive scenarios a known anchor so a fresh install can show its recent activity examples and tests can advance time deliberately.
- Validate unique IDs, valid enums, timestamp and money formats, and relationships such as finance → card, card → account and sale → station/product. Validate notification route targets and card ownership. Represent an empty collection with an empty array. Treat missing files, malformed values, and broken joins as fixture errors with a retry or recovery UI and diagnostic context.
- Load the selected scenario into typed models. Compute Home metrics, filtered lists, file exports and transfer notes from those models. Keep business records and sample credentials in JSON. Code implements the rules, for example calculating totals, advancing OTP timers, and formatting exports.

## Mutations and external actions

Bundled JSON is the read-only seed. Persist changes on the device with keys scoped to the scenario and account. Use an explicit deletion record for a removed seed note so restarting cannot bring it back. Store notification read state and local alert preferences as overrides. Keep language as an app-wide preference. Logout clears the session and the protected route stack. Clearing app data restores the bundled defaults.

Simulate SMS delivery and validation, station directions, top-up and notification delivery from the fixture data. Keep Android clipboard, file save, and the share chooser functional with synthetic payloads. This lets the demo exercise the observable workflows offline, including state changes and cancellation.
