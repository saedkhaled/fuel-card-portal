# Package 07 · Arabic-first AI support

Status Connected Android smoke test passed · Live Gemini verification on this build pending

## Product scope

Give signed-in customers a main **المساعد / Assistant** tab for **Golden Gate AI Assistant**. Customers can ask in their own words, use Syrian colloquial Arabic, or ask a follow-up. The assistant replies in Arabic by default about Golden Gate and fuel-card portal support topics. It introduces itself by its full name when asked. When the offline catalog lacks a reliable match, the tab offers the existing FAQ.

Keep Arabic as the app’s first-run language on Android, including on English-language devices. `PortalSettings` already defaults to Arabic when there is no saved English choice, and `PortalBootstrap` already uses Arabic while loading. Preserve explicit English selections and the language picker before and after sign-in. Add regression coverage for fresh launch, restored sessions, and switching back to Arabic. Offline replies use the stored Arabic passages, including for supported English search terms. The Gemini pilot tests an explicit request to reply in English. Interface labels follow the app’s selected language.

Read the [current navigation contract](../architecture.md#navigation-and-state), [Account services package](../step4_account_services/package.md), [Flutter design handoff](../step6_figma_redesign/flutter-handoff.md), and [Android verification](../verification.md).

## Navigation and chat

- Use five primary destinations in logical order from the reading edge. **Home · Cards · Assistant · Stations · More**. Give Assistant a raised button treatment in the center of the existing bar. Implement it as a selectable destination with a visible label, selected state, and accessibility semantics. Show **المساعد الذكي / Smart Assistant** in the app bar. Keep the tab centered in Arabic RTL and English LTR.
- Keep `/balances` reachable through the existing Home shortcut and add a Balances entry under More. Retain the route and existing operations links. Keep the FAQ under More and link it from Support. Update affected navigation tests to use the new entry points.
- Give Support its own guarded shell branch at `/support` and preserve its draft and conversation while switching tabs within the same session. Android Back dismisses the keyboard first, then returns to the previous app destination or Home when entered directly. Sign-out clears the draft and transcript and discards in-flight replies.
- Use the existing visual system for the chat page. Show a short invitation, a few starter questions drawn from approved topics, the conversation, and a text composer. Show catalog loading and retry, searching, and no-answer states in both UI languages. Keep the composer reachable with the keyboard open and announce completed replies to TalkBack.

## Offline Support design

The [bundled schema-2 catalog](../../../assets/demo/standard/support.json) contains 61 passages from Golden Gate’s website, the supplied Arabic customer guide, and app instructions, including the assistant’s introduction. Its records carry a stable `id`, Arabic `title_ar` and `passage_ar`, and search `terms`. Optional `example_ar` fields supply starter prompts. A `subject` links related passages for follow-ups. Each record has at least one provenance field or destination from `guide_section`, `source_url`, and `app_route`. The loader validates unique IDs, required text, official website URLs, and allowlisted routes. Catalog changes ship with a new APK.

1. Display the question immediately and show the searching indicator. Keep one lookup in progress while allowing the user to draft the next question.
2. Normalize Arabic spelling and digits and map common equivalent terms. Rank matches across passage titles, search terms, and body text. Use the previous subject for short follow-ups that refer back to it.
3. Show the matching stored Arabic passage and any in-app destination. Weak or ambiguous results show the FAQ option. Station coverage refers to listed products and directs users to check availability where appropriate. The offline path runs on-device and can complete in airplane mode.
4. Keep the draft and conversation in the signed-in session. Cover paraphrases, follow-ups, source display, weak matches, and the searching state in local regression tests. Verify a guide answer and its citation on the installed Android build in airplane mode.

See the [offline implementation and verification evidence](offline-implementation.md#searchable-customer-guide-follow-up--25-november-2026).

## Connected Support

The [Gemini pilot plan](gemini-pilot.md) covers direct Android access through Firebase AI Logic. Gemini evaluates whether each submitted question relates to Golden Gate and can answer without a matching passage. The app displays the model’s reply directly. On-device search handles unavailable service. Online catalog publishing is a separate follow-up.

## Implementation and acceptance

- [x] **Offline Flutter shell and locale.** Added the centered Support route, chat, Arabic and English interface labels, and Balances entry in More. Verified Arabic on fresh install with Android set to English, locale selection and restored preference, and the centered tab in both directions.
- [x] **Offline knowledge base and ranked search.** Bundled 58 passages from the website, supplied guide, and demo guides. Verified paraphrases, short follow-ups, provenance, weak matches, the searching state, and a guide reply in airplane mode.
- [ ] **Online catalog updates.** Add a publishing path for owner updates that reach the app without an APK release.
- [x] **Gemini pilot.** Verify live responses through Firebase AI Logic and App Check on the emulator. See the [Gemini pilot evidence and release checklist](gemini-pilot.md).
- [ ] **Connected Android acceptance.** Run localization generation, Flutter analysis, unit/widget tests, and installed Android walkthroughs. Check 360 dp, 1.3× text, TalkBack traversal, Arabic and mixed-direction text, keyboard and Back, tab state, direct-route guard, sign-out during a request, timeout/retry, and airplane-mode FAQ. Recheck Home and More → Balances and existing operations routes against V01, V03, V05, V07, and V08. Record commands, device/API, dataset, and results in this package before closing it.

## Planning evidence

- Baseline checked with `git status --short --branch` and `git log -1 --oneline`. Branch `codex/fuel-card-portal` was at `7aea3d0`, with pre-existing edits in the Package 06 Flutter handoff and Android `MainActivity.kt`.
- Code inspection confirmed the Arabic default and stored locale, the five shell destinations, the existing Home → Balances shortcut, the FAQ under More, and an existing Arabic-first widget assertion. Planning completed through source inspection. See the offline implementation evidence for the updated Android results.
- Approved support content, an approved contact if offered, and a provider and hosting decision are inputs for the connected customer rollout.

## Website links and nearby stations follow-up

- Company answers remain grounded in the bundled public website content and customer guide. The reply shows a clickable source URL. Station questions use the official interactive map, and app-specific questions can also open the Stations tab.
- The nearest-station starter question and typed requests use the same [official catalogue as the Stations tab](../step3_stations_prices/package.md#official-station-catalogue). The app requests foreground location for this action and offers Android settings or a retry when appropriate, with a Google Maps search available if it cannot determine the nearest station. The app calculates the nearest station on-device. The directions button sends its destination coordinates to Google Maps.
- `flutter test --no-pub integration_test/support_home_smoke_test.dart -d emulator-5554` passed on Android 13/API 33. It checked the Home totals and shortcut order, the official map URL, the nearest partner station destination, and the permission-denied reply.
- After merging upstream `0f73d67`, `flutter test integration_test/support_home_smoke_test.dart -d emulator-5554 --reporter expanded` passed on Android 13/API 33. It checked the short Arabic assistant title, Arabic top-up, official links, injected Gemini replies and safeguards, and the location retry and settings actions.
- The installed debug build displayed the Android location prompt. With a simulated fix near Ariha, it identified the Ariha station and brought Google Maps to the foreground when tapped.
- The current emulator's Firebase App Check registration blocked the live Gemini exercise. The Firebase project, Android app ID, and release Play Integrity provider were carried forward from `0f73d67`. Live replies on a physical Android device still need verification for this build.

## Signed sideload build

- Built local changes based on `0f73d67` with `flutter build apk --release --target-platform android-arm,android-arm64`. Verified the development signing certificate matches the previous local sideload APK. The packaged app is `com.example.fleet_cards_demo` version `0.1.0+1` and requires API 24 or later. Its Dart app binaries target ARM and ARM64.
- `adb -s emulator-5554 install -r` succeeded with the exact deliverable. The Android 13/API 33 emulator launched the Arabic sign-in screen. The user then signed in on the emulator.
- APK SHA-256 `c1b2d16b2b69e86bb7cdc2ded9089d1517d9ad212d9bf40969513def423475e1`. Live Gemini and Play Integrity acceptance for this signer on a physical device remain pending.
