# Android fuel-card portal proposal

Prepared 25 November 2026 · Planning complete · Implementation pending

Build an Android-first Flutter demo for a fleet customer. A user signs in with a synthetic phone and verification code, then browses fuel cards, balances, operations, stations, prices, sales, subscriptions, account services, and notifications. Card notes are editable. Payment and communication surfaces use a simulated workflow. The installed app must run in airplane mode.

## Scope and evidence

The supplied Stage APK opened successfully on Pixel 9 Pro / Android 16 (API 36). The authenticated account exposed five tabs and additional screens from Home and More. This is a fuel-card customer portal. [Reference inventory](reference-audit.md) documents the routes, states, actions, and evidence gaps. The demo must reproduce the observed user-facing workflows and controls across R01–R23, including their entry points, filters, edits, exports, and relevant empty and failure states. Where the reference uses a live service, the corresponding demo action runs locally against synthetic data. The demo uses an original name, layout treatment, copy, icons, and visual identity. Use **Fleet Cards Demo** as the working name and `com.example.fleet_cards_demo` as the sideload application ID.

The Android artifact, source, editable, versioned JSON fixture files bundled with the Android app, fixture editing instructions, run instructions, and test evidence form the implementation handoff. Store release, iOS, real authentication/SMS, live payment and transfers, real push delivery, live station integrations, administrative card issuance or activation, and service deployment are outside the first release. A stopped card remains a read-only state. Mock operation and subscription data may be richer than the observed account to exercise the UI.

## Execution plan

| Package | Outcome | Depends on | Estimate |
| --- | --- | --- | --- |
| [01 Foundation](step1_foundation/package.md) | Android shell, locale, fixtures, local session and OTP | — | 2–3 h |
| [02 Cards and finance](step2_cards_finance/package.md) | Home, cards, notes, balances, operations, sales, exports | 01 | 4–6 h |
| [03 Stations and prices](step3_stations_prices/package.md) | Search, filter, details, directions preview, bulletins | 01 | 2–3 h |
| [04 Account services](step4_account_services/package.md) | More, subscriptions, top-up, FAQ, settings, inbox, logout | 01 and shared card contract from 02 | 3–4 h |
| [05 Android acceptance](step5_android_acceptance/package.md) | Independent review, bilingual emulator smoke, installable APK | 02, 03, 04 | 2–4 h |

Estimate is 13–20 agent-hours under functioning Android tooling, with a first demo slice after 01 and the Home → Cards portion of 02. Gradle downloads, host setup, or undocumented UI variants can add elapsed time. Agents can work in parallel on 02 and 03 after 01, then start 04 after 02 stabilizes shared contracts. [Execution instructions](prompt.md).

## Product acceptance

- The demo installs on API 36 and supports API 24 as the planned minimum, subject to dependency validation. Verify API 24 on an available emulator before claiming tested compatibility.
- The default Arabic RTL experience supports switching to English from signed-out and signed-in surfaces. Language and local notes survive process restart. Logout clears the session and guarded route stack.
- Home metrics come from the same fixtures as the Cards, Balances, operations, and inbox screens. Both card and balance shortcuts open the same operations component with the correct card scope. Exports honor scope and applied filters and open with the expected mock rows.
- Verify each R01–R23 workflow on Android and record its corresponding demo route, action result and scenario. Exercise populated, empty and retry paths using the bundled JSON. A visible control counts as covered when it performs its simulated action or documented native Android action.
- All financial values, station details, notification content, account identifiers, and exported rows are synthetic. Top-up uses a clearly labeled simulated QR payload and demo-only account text. Directions/contact actions use local previews. Clipboard, save, and share operate on synthetic data through Android UI.
- Both locales work at 360 dp, enlarged system text, and with the soft keyboard open. Screen reader names, focus order, targets, dates, and numeric direction are verified on key flows.
- Release or demo APK builds, installs, and runs a recorded offline end-to-end journey. SDK, commands, artifact checksum, emulator/API, and any unverified cases are recorded.

[Architecture](architecture.md) · [JSON fixture contract](fixtures.md) · [Android verification](verification.md) · [Implementation status](memory.md)

## Design follow-up

[Package 06](step6_figma_redesign/package.md) delivers a brand-aligned, bilingual Figma redesign and motion specification on top of the archived Android baseline. The handoff can drive a separately scoped Flutter update.
