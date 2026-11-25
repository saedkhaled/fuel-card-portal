---
name: portal-flutter
description: Implement Flutter screens, navigation, localization, repositories and synthetic fixtures for this repository's fuel-card portal demo.
---

# Fuel-card portal implementation

Read [architecture.md](../../../.spec/fuel-card-portal/architecture.md) and the selected requirement IDs in [reference-audit.md](../../../.spec/fuel-card-portal/reference-audit.md). Use the current package ownership from [prompt.md](../../../.spec/fuel-card-portal/prompt.md).

- Compose JSON-backed repositories once. Follow the [fixture contract](../../../.spec/fuel-card-portal/fixtures.md) for asset ownership and persistent local edits. Keep card IDs stable across lists, notes, balances, operations, subscriptions and deep links. Derive summary metrics from the same records and clock used by the lists.
- Use the app's original visual tokens and accessible text in both ARB catalogs. Keep numeric identifiers internally stable and visibly ordered in RTL. Use one reusable filter model for applied state, exported data and Back navigation.
- Demo sign-in and QR data stay local and synthetic. Gate platform operations behind scoped adapters so tests can check payloads. Preserve Android cancellation and handle errors close to the initiating control.
- Deliver a working route through the app before expanding the feature's edge cases. Test its data and widget behavior, then use the Android QA skill when the selected package calls for a device check.
