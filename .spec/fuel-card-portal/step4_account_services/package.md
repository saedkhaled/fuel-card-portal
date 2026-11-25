# Package 04 · Account services

Status awaiting 01 and card contract from 02 · Estimate 3–4 h

## Objective and ownership

Own More/account, notifications and local service surfaces. Read R03 and R15–R23 from [reference audit](../reference-audit.md) and V05 from [verification](../verification.md).

## Tasks

- [ ] Create `account.json` and `notifications.json` under the [fixture contract](../fixtures.md). Build the profile and settings menu using the loaded account and contact data. Link existing Sales, Prices and Notifications routes.
- [ ] Build subscription summary, per-card items and invoice history using stable card IDs and mock invoice states.
- [ ] Build simulated top-up with inert QR, demo destination, instructions, local download/share of the image and copy of synthetic account or transfer-note text.
- [ ] Implement expandable information, persistent station-alert setting, first-run prompt integration, and inbox. Use a seeded local station availability event to exercise the on/off behavior. Use the same read/unread dataset for inbox and Home.
- [ ] Add language, About and logout confirmation. Integrate guarded navigation and clear session-scoped state.
- [ ] Verify subscription, top-up, toggle, quiet/populated inbox, locale persistence, and cancel/confirm logout using tests and Android smoke.

## Exit

All More entries are reachable, render in both directions and use local data. File/clipboard actions are checked with synthetic content. Record evidence and hand off remaining cross-feature checks to 05.
