# Flutter architecture and mock data

## Structure and toolchain

Use one Flutter app at the repository root with feature directories and a small app composition root. The mobile monorepo provides the planning format. A single deployable app can share internal libraries directly. Add a Dart workspace only if a second real consumer emerges. Start with the locally verified Flutter 3.44.2 / Dart 3.12.2, lock resolved package versions, keep the generated Gradle wrapper, and record the effective JDK and Android SDK. Bootstrap with `flutter create --platforms=android --org com.example --project-name fleet_cards_demo .`. Prefer the Flutter template values for compile and target SDK, with API 36 verifying the current emulator and API 24 as the proposed minSdk. Verify dependencies and the merged manifest before accepting the minimum.

```text
android/
assets/demo/                  # checked-in JSON scenarios and fixture guide
lib/
  app/                        # composition, router, theme, shell
  core/                       # formatting, clock, scoped platform adapters
  demo/                       # asset loading, validation and scenario selection
  features/
    auth/ home/ cards/ finance/ stations/ prices/ account/ notifications/ support/
  l10n/                       # English and Arabic ARB
test/                         # mirrors app features
integration_test/             # Android demo journey
```

Feature views own rendering, view models own commands and screen state, repositories own data and mutations. Use injectable interfaces at data boundaries, constructor injection and `ChangeNotifier`/provider for UI state, and `go_router` with a guarded stateful shell and nested detail routes. Assemble local implementations once in the app composition root and inject the selected dataset from bundled JSON. Use the [JSON fixture contract](fixtures.md) for file ownership, joins and persisted edits. Use Flutter localization, `intl`, and simple local key-value storage for session, locale, scenario-independent settings, and notes namespaced by account and card ID. Keep credential values out of the preference store. Use an Android adapter or a maintained package for file save/share only where required. Use SDK APIs for clipboard and standard Material 3 components with original design tokens. Confirm package compatibility in 01 and favor built-in APIs when equivalent. [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide) · [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

## Navigation and state

Signed-out stack is phone → code. Successful verification replaces it with the shell. Shell branches are Home, Cards, Support, Stations, and More. Home and More open the shared Balances route. Support ranks passages in the bundled Arabic knowledge base, uses the previous subject for short follow-ups, and keeps the draft and conversation in the signed-in shell. See [Offline Support design](step7_ai_support/package.md#offline-support-design). Global notifications and cross-tab shortcuts use the same destinations as their menu entries. Card links carry the stable card ID. Card details land on the details tab, while an operations shortcut opens the financial operations tab or its shared view. Android Back closes transient UI first, then detail routes, with the originating list, search, and filters restored. Stale route IDs show a friendly missing-record state. Logout clears protected navigation and transient state while local preferences and scoped notes remain available to the same demo profile.

Every async screen models loading, content, empty, error, and retry as applicable. Fake delays are deterministic and zero or clock-driven in tests. Cancel or ignore stale responses after newer requests, route exit, or session change. Disable repeated submit, Save, and export while the corresponding operation is in progress. Use stable list keys and lazy rendering for the large-data scenario.

## Proposed contracts

| Contract | Required data and behavior |
| --- | --- |
| `SessionRepository` | Request, resend, verify and restore session, logout. A challenge has ID, masked phone, expiration and resend timestamps. One active challenge, one completion. |
| `CardsRepository` | Stable ID, card number, plate, active/stopped, nullable activation timestamp, fuel type, refill quota, created date, nullable note. List/search and card-scoped note upsert/delete. |
| `FinanceRepository` | Card balance joined by card ID, last-operation date, typed operation, signed amount, status, timestamp, station or description, sale rows. Recent counts derive from an injected clock and the same dataset. |
| `StationRepository` | ID, localized name/address/city, products and availability per product, optional mock directions metadata. |
| `BulletinRepository` | ID, effective date, active or previous status, localized products and unit prices. |
| `AccountRepository` | Profile, contact, card subscriptions and invoices, informational entries, demo top-up instructions. |
| `NotificationRepository` | Inbox items with kind/read flag and optional route target, local preference for station availability alerts. |

Currency uses integer minor units plus currency code and explicit display precision. Use UTC instants for events and one documented demo time convention for rendering date filters and day boundaries, with Syria-local display where configured. Represent effective dates as date-only values. Display numbers, plates, and IDs with direction isolation in Arabic. Document note length, date range inclusivity, operations summary counts and sign conventions in tests. Exports render canonical values from the same filtered query snapshot, use unique temporary file names, and support platform cancellation. Any CSV field with user-supplied text must be quoted and neutralized for spreadsheet formulas. [Android document creation](https://developer.android.com/training/data-storage/shared/documents-files#create-file).

## Scenario fixtures

| Scenario | Content and purpose |
| --- | --- |
| `standard` | Original fictional fleet, mixed active and stopped cards, first-activation and never-activated cases, multiple fuel types, balances, operations, station availability states, current and previous bulletins, paid and unpaid invoices, and read/unread notifications. |
| `quiet` | Signed-in profile with recent operations and inbox empty, plus meaningful historical rows if date filters are expanded. |
| `empty` | No cards or sales, no results and safe totals. |
| `recoverable_error` | A selected fetch fails once, then succeeds on retry. |
| `large_fleet` | Checked-in JSON generated deterministically with 180 synthetic cards and realistic joins for scroll, filter and export checks. |

Use an explicit test-only injection or documented build-time scenario selector. Keep the normal demo entry on standard with obvious sample sign-in help. Put the synthetic phone `0900000000` and code `246810` in the auth fixture and use them for the sign-in help. Simulate the observed five-minute code validity, one-minute resend cooldown and six-digit auto-submit. Provide a fake clock for tests, invalidate prior challenges on resend, and check invalid or expired sequences and back navigation. For notifications, simulate preferences and read states locally. The mock top-up QR must encode inert demo text and visibly identify itself as a demo. No fixture should contain real payment details, staging identifiers, or original APK assets.

## Visual direction

Use a distinct Material 3 design with deep teal, light neutral surfaces, and restrained amber for status emphasis. Set a clear hierarchy with a balance summary, search and filter controls, and compact cards for list items. Use consistent status chips with text and icon where useful. Build the card detail around a simple summary panel and tabs. Pick an Android fallback that supports Arabic and Latin scripts and verify numeral rendering. Use original icons from the selected Material set and generate the inert QR locally. Keep the bilingual UI usable on small screens without forcing five long tab labels into a single crowded row. Preserve accessible full labels for screen readers.

## Decisions that affect delivery

| Risk | Response |
| --- | --- |
| OS file chooser and sharing behave differently by Android API | Keep one scoped export adapter. Test generated bytes separately from native save/share and report actual API coverage. |
| Mixed-direction identifiers and long translations make dense screens hard to use | Add Arabic from foundation. Check real device widths and enlarged text during feature work, then repeat at acceptance. |
| Multiple features edit shared wiring | Agree on feature route hooks and stable card IDs early. Assign one owner to integrate dependency, router and ARB changes. |
| The reference account exposes only some data and error states | Preserve observed controls and route outcomes. Use documented synthetic variants for missing and failure states. |
