# Package commands and agent handoff

The slash forms below are project conventions that a Codex chat can interpret through AGENTS.md. They are intended for use as chat messages.

| Command | Action |
| --- | --- |
| `/spec-explore fuel-card-portal` | Read-only review of evidence gaps or feasibility. |
| `/spec-propose fuel-card-portal` | Update planning files for a changed scope. |
| `/spec-apply fuel-card-portal step1_foundation` | Scaffold Android, l10n, shell, mock session and OTP. |
| `/spec-apply fuel-card-portal step2_cards_finance` | Deliver Home, cards, notes, finance, sales and exports. |
| `/spec-apply fuel-card-portal step3_stations_prices` | Deliver station and bulletin journeys. |
| `/spec-apply fuel-card-portal step4_account_services` | Deliver More, profile, subscriptions and demo services. |
| `/spec-apply fuel-card-portal step5_android_acceptance` | Run acceptance and produce the Android APK and handoff. |
| `/spec-apply fuel-card-portal step6_figma_redesign` | Deliver the bilingual Figma design and Flutter handoff, including the motion specification. |
| `/spec-apply fuel-card-portal step7_ai_support` | Implement and verify the [Gemini pilot](step7_ai_support/gemini-pilot.md) using the existing Arabic-first Support tab, knowledge base, and offline fallback. |
| `/spec-sync fuel-card-portal` | Reconcile package tasks, test outputs and gaps with current files. |
| `/spec-archive fuel-card-portal` | Archive after acceptance and a final evidence review, when requested. |

To authorize the complete implementation in one run, send this message.

> Implement the fuel-card-portal plan end to end from the current checkout. Start with the ready package in memory.md and continue through Android acceptance. Use repo-local skills and the original visual direction. Create, validate, and bundle the editable JSON fixture catalog. Verify every observed workflow in R01–R23. Build, install, and verify the Android APK. Update memory and report any unverified cases.

## Ownership and delegation

A single Codex agent can run the full plan. When parallel work is authorized and tool slots are available, the coordinator owns sequencing, package status, cross-feature routing and merges. Foundation establishes shared fixture IDs for accounts, products and stations, along with route hooks and theme, before parallel work. Feature packages populate their manifest entries as their files land. Validate complete cross-feature joins at integration. Prefer two implementation lanes after foundation, then review.

| Role | Owns | Coordination |
| --- | --- | --- |
| Coordinator / foundation | Root Flutter/Android files, app composition, auth, shared contracts, memory | Assign feature writes, integrate route, dependency and ARB contributions, resolve shared test setup. |
| Cards and finance worker | Home, Cards, Finance, Sales, exports and their scoped tests | Publishes stable card/finance contract used by account features. |
| Stations and prices worker | Stations, prices and their scoped tests | Supplies route hooks and locale strings to coordinator. |
| Account and notifications worker | More, account services and notifications, with scoped tests | Starts after card contract exists. Supplies Home/inbox contract. |
| Reviewer / Android QA | Acceptance outputs and issue list | Review independently if another agent is available. Coordinator owns shared fixes and APK. |

Workers should work in assigned paths, preserve other edits, and send a handoff with changed files, commands/results and unresolved items. Serialize edits to root router, dependency composition, localization catalogs, pubspec and Android manifest. The current plan needs Flutter/Dart implementation, Arabic localization, fixture design, Android testing, and review. The three repo-local skills capture project-specific workflows. Flutter SDK testing and ADB cover the first release without requiring an app-specific external skill.
