# Package 06 · Figma redesign

Status Design handoff complete · Baseline Package 05 complete

## Objective and ownership

Design a futuristic, Android-first refresh of the fuel-card portal in the [specified Figma file](https://www.figma.com/design/NhoSoQrmBLRX4DT7ilZ529/Untitled?t=Iwnek9wRvgIr5cG8-0). Carry forward the original app’s primary colors, logo, and recognizable iconography in a new layout and motion system. Use the Stage APK to review brand cues and the shipped offline demo to review interactions. Cover the full application in Arabic RTL and English LTR. Deliver an editable design and specs for a subsequent Flutter implementation. On 25 November 2026, the user confirmed that prototype completion is optional once the design is ready.

Own the new Figma pages and this package’s evidence. Start from the [reference audit](../reference-audit.md), [R01–R23 coverage matrix](../step5_android_acceptance/coverage.md), [navigation and state contract](../architecture.md#navigation-and-state), and [verification](../verification.md).

## Tasks

- [x] **Review access and the brand.** Verified edit access in the existing Chrome session. Created `Foundations`, `Android Screens`, and `Prototype & Handoff`. Sampled the Stage palette and placed the APK artwork into the shared brand component. Used the observed Material icon roles and synthetic design content. APK, credentials, live screenshots and brand files remain outside Git.
- [x] **Design and review the first slice.** Created and inspected Home, Cards, and Card Details in Arabic and English at 360 dp. Used dark balance and card surfaces, fine gold geometry, and light transaction surfaces. Extended the design after the first-slice review.
- [x] **Build the foundations.** Saved the Stage palette as semantic variables, defined the Inter/Cairo typography and design scales, and added shared navigation, card, balance, transaction, input, button and state components. Documented the observed outline icon roles, reusable logo, and motion values.
- [x] **Complete the screen inventory.** Created bilingual frames for R01–R23, with representative recovery, empty, keyboard-open, and larger-text states. Mapped the Flutter routes and interaction outcomes in the [handoff](flutter-handoff.md).
- [x] **Verify and hand off the design.** Recorded frame links, asset sources, representative visual checks and remaining implementation checks. Mapped design variables, components and motion to the existing Flutter routes and roles.

## Screen inventory

| Workflow | Frames and states |
| --- | --- |
| Sign-in and Home · R01–R04 | Phone and language picker, OTP entry/resend/error/expiry, first-run notification prompt, Home totals, shortcuts and recent activity |
| Cards and finance · R05–R10, R14 | Cards search and status filters, active and stopped states, card details and operations preview, add/edit/delete note, balances and shared operations log, Sales, date and product filters, export menu and outcome |
| Stations and prices · R11–R13 | Station search and filters, availability, station detail and directions preview, current bulletin, history and detail |
| Account services · R15–R20 | More and profile, subscription and invoices, demo top-up and QR, FAQ, notification preferences, populated/quiet inbox and linked alerts |
| Settings and session · R21–R23 | Language switch from both entry points, About, logout confirmation and signed-out destination |

Reuse component variants for loading, empty/no results, validation, error/retry, disabled or busy actions, and success feedback where each workflow supports them. Include representative 360 dp compositions, enlarged text, and keyboard-open input and sheet states.

## Motion specification

| Moment | Proposed Figma interaction | Reduced-motion variant |
| --- | --- | --- |
| OTP accepted | 200 ms crossfade into Home with a short balance panel reveal | Immediate Home state |
| Card list → detail | 260 ms Smart Animate between matching card elements; keep the amount and card ID readable | Immediate detail state |
| Filter or note sheet | 200 ms slide with a dimmed backdrop and clear focus target | Immediate sheet and focus change |
| Filter applied or update confirmed | 120–160 ms highlight or crossfade with explicit text or status feedback | Immediate feedback and status |

Treat timings as starting points. The Flutter handoff documents reverse and Back behavior, interruptibility, and Android’s reduced-motion setting.

## Exit criteria

- The specified Figma file contains editable foundations, named components and variants, and bilingual screen frames. The handoff links directly to the design.
- R01–R23 each map to a named frame or component state and its intended behavior, including representative recovery and cancellation states.
- Brand colors and assets are traceable to the reference or an approved source. Unavailable assets have labeled placeholders and a recorded disposition.
- Inspect representative 360 dp frames in both directions and include larger-text and keyboard-open examples. Record the remaining accessibility checks for implementation.
- Record motion triggers, timing, easing, Back behavior and the reduced-motion mapping in the handoff.
- Record any gap that prevents verification. A later Flutter package should use [V01–V09](../verification.md) for regression coverage and verify implemented motion, reduced-motion behavior, and screen reader focus on Android.

## Planning evidence

- Git baseline was clean on `codex/fuel-card-portal` at `52f7d00`.
- The supplied `Stage_2026_11_17.apk` matched the audited build. `shasum -a 256` returned `9e49e4d15367aa65aa73f4ae02d2845a9475c02e86c11684743adafcab55b47f`.
- The Figma link could not be opened by the web reader during planning. File contents, edit access, palette values, and reusable brand assets remain to be verified during the first task.

## Implementation evidence

- Implementation started on `codex/fuel-card-portal` at `52f7d00` with the Package 06 planning updates already present in the working tree. Package 05 remains the Android baseline.
- On emulator `emulator-5554` at API 36, opened the installed Stage package with `adb shell am start -n sy.goldengate.gg_portal/.MainActivity` and sampled the capture locally. Stage header navy was `#003262`. The unpacked transparent logo had opaque blue `#044064` and gold `#DBA513`. The shared Figma logo component uses a downsampled copy of that artwork. Figma uses Inter and Cairo and a set of Material-style outline roles.
- Saved 118 bilingual, editable 360 × 800 frames, including 54 initial frames and 64 continuation frames, with synthetic content. The file contains a reusable logo, variables, native components, editable text and vectors. Early frames use shared components. Continuation frames include imported editable vectors and text alongside the original component-based set.
- Native presentation checks in Chrome reached both locale Home screens from their sign-in, OTP and alert flows. English playback reached Balances → FC-0101 → Operations → Filter, Home → Stations → Station Details → Directions, Home → More → Top-up, card note save/delete, and Sales → filtered results → export → cancel. Arabic playback reached instant Operations, Filter and Apply, and More → Settings → Sign out. Cancel returned to Settings and confirm reached Arabic sign-in.
- The default card detail reaction is 260 ms Smart Animate with Ease in and out in both locales. The alert choices use a 200 ms reveal into Home. Operations, Stations and Sales Apply use a 140 ms dissolve. Both instant Balances → Operations examples are saved separately.
- [English prototype](https://www.figma.com/proto/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=5-773&starting-point-node-id=5%3A773) · [Arabic prototype](https://www.figma.com/proto/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=5-1098&starting-point-node-id=5%3A1098) · [English instant example](https://www.figma.com/proto/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=7-1901&starting-point-node-id=7%3A1901) · [Arabic instant example](https://www.figma.com/proto/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=7-2217&starting-point-node-id=7%3A2217)
- [Android screen inventory](https://www.figma.com/design/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=5-2) · [Figma motion and route board](https://www.figma.com/design/NhoSoQrmBLRX4DT7ilZ529/Untitled?node-id=23-1888) · [Flutter handoff and R01–R23 route map](flutter-handoff.md)

## Flutter implementation checks and prototype evidence limits

- Existing clickable examples are available for reference. Secondary prototype interactions and hotspot coverage were outside the final design-only acceptance scope.
- The Arabic keyboard-open frame was inspected at 360 dp. During Flutter implementation, verify 1.3× text, reading order, 48 dp targets, final contrast, Android reduced motion, TalkBack, and native save/share. Verify the FAQ, alert toggle, inbox read-state updates and Back behavior against the route and state map.
