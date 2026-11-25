# Package 01 · Foundation

Status Ready · Dependencies none · Estimate 2–3 h

## Objective and ownership

Own Flutter/Android bootstrap, app composition, shell, theme, locale, auth, and fixture conventions. Read R01–R03 and R21 from [reference audit](../reference-audit.md) and the [architecture](../architecture.md). Create route hooks for upcoming tab/feature screens, handing off actual UI to their owners.

## Tasks

- [ ] Record repository/device/toolchain baseline and create the Android Flutter project using the planned application ID. Pin the SDK choice and package lockfile. Install and launch the scaffold.
- [ ] Set up Material 3 tokens, app identity, English/Arabic catalogs, accessible shell and guard, and scoped route contracts.
- [ ] Implement a fake session, phone validation, timed OTP request/resend/verify with synthetic sign-in hints, guarded session restoration, and notification prompt state. Expose logout and locale operations for account features.
- [ ] Build the JSON asset loader, scenario manifest and initial auth fixture from the [fixture contract](../fixtures.md). Register assets, test missing and invalid JSON, and document file ownership. Establish repository injection, time conventions and persistence namespaces.
- [ ] Add focused auth, clock, localization and routing tests. Run format, analyze, relevant tests and first Android sign-in smoke.

## Exit

The phone and code in the bundled JSON sign in offline through the real launch path. Guard, clock-based error flows, locale switch and restart are verified. Device launch and commands are recorded. 02 and 03 can start.
