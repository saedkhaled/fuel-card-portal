# Package 07 · Arabic-first AI support

Status Offline demo verified on Android · Gemini pilot planned

## Product scope

Give signed-in customers a main **الدعم / Support** tab where they can type a question and receive an answer in Arabic based on the approved support material. Customers can ask in their own words, use Syrian colloquial Arabic, or ask a follow-up. The assistant covers fuel-card portal support topics supported by the material. When the offline catalog lacks a reliable match, the tab offers the existing FAQ. The Gemini pilot adds focused clarifying questions when they can resolve ambiguity.

Keep Arabic as the app’s first-run language on Android, including on English-language devices. `PortalSettings` already defaults to Arabic when there is no saved English choice, and `PortalBootstrap` already uses Arabic while loading. Preserve explicit English selections and the language picker before and after sign-in. Add regression coverage for fresh launch, restored sessions, and switching back to Arabic. Offline replies use the stored Arabic passages, including for supported English search terms. The Gemini pilot tests an explicit request to reply in English. Interface labels follow the app’s selected language.

Read the [current navigation contract](../architecture.md#navigation-and-state), [Account services package](../step4_account_services/package.md), [Flutter design handoff](../step6_figma_redesign/flutter-handoff.md), and [Android verification](../verification.md).

## Navigation and chat

- Use five primary destinations in logical order from the reading edge. **Home · Cards · Support · Stations · More**. Give Support a raised button treatment in the center of the existing bar. Implement it as a selectable destination with a visible label, selected state, and accessibility semantics. Keep it centered in Arabic RTL and English LTR.
- Keep `/balances` reachable through the existing Home shortcut and add a Balances entry under More. Retain the route and existing operations links. Keep the FAQ under More and link it from Support. Update affected navigation tests to use the new entry points.
- Give Support its own guarded shell branch at `/support` and preserve its draft and conversation while switching tabs within the same session. Android Back dismisses the keyboard first, then returns to the previous app destination or Home when entered directly. Sign-out clears the draft and transcript and discards in-flight replies.
- Use the existing visual system for the chat page. Show a short invitation, a few starter questions drawn from approved topics, the conversation, and a text composer. Show catalog loading and retry, searching, and no-answer states in both UI languages. Keep the composer reachable with the keyboard open and announce completed replies to TalkBack.

## Offline Support design

The [bundled schema-2 catalog](../../../assets/demo/standard/support.json) contains 58 topic passages from Golden Gate’s website, the supplied Arabic customer guide, and demo app guides. Its records carry a stable `id`, Arabic `title_ar` and `passage_ar`, and search `terms`. Optional `example_ar` fields supply starter prompts. A `subject` links related passages for follow-ups. Each record has at least one provenance field or destination from `guide_section`, `source_url`, and `app_route`. The loader validates unique IDs, required text, official website URLs, and allowlisted routes. Catalog changes ship with a new APK.

1. Display the question immediately and show the searching indicator. Keep one lookup in progress while allowing the user to draft the next question.
2. Normalize Arabic spelling and digits and map common equivalent terms. Rank matches across passage titles, search terms, and body text. Use the previous subject for short follow-ups that refer back to it.
3. Show the matching stored Arabic passage and its guide section, official link, or app destination. Weak or ambiguous results show the FAQ option. Station coverage refers to the products listed in the source, with official links for current availability. The offline path runs on-device and can complete in airplane mode.
4. Keep the draft and conversation in the signed-in session. Cover paraphrases, follow-ups, source display, weak matches, and the searching state in local regression tests. Verify a guide answer and its citation on the installed Android build in airplane mode.

See the [offline implementation and verification evidence](offline-implementation.md#searchable-customer-guide-follow-up--25-november-2026).

## Connected Support

The [Gemini pilot plan](gemini-pilot.md) covers the backend, source validation, Arabic reply generation, and the three test stages. The pilot uses the existing on-device search as its fallback. Online catalog publishing is a separate follow-up.

## Implementation and acceptance

- [x] **Offline Flutter shell and locale.** Added the centered Support route, chat, Arabic and English interface labels, and Balances entry in More. Verified Arabic on fresh install with Android set to English, locale selection and restored preference, and the centered tab in both directions.
- [x] **Offline knowledge base and ranked search.** Bundled 58 passages from the website, supplied guide, and demo guides. Verified paraphrases, short follow-ups, provenance, weak matches, the searching state, and a guide reply in airplane mode.
- [ ] **Online catalog updates.** Add a publishing path for owner updates that reach the app without an APK release.
- [ ] **Gemini pilot.** Implement the [planned backend and Flutter integration](gemini-pilot.md). Verify the fake-provider suite, live synthetic cases, and installed Android walkthrough.
- [ ] **Connected Android acceptance.** Run localization generation, Flutter analysis, unit/widget tests, and installed Android walkthroughs. Check 360 dp, 1.3× text, TalkBack traversal, Arabic and mixed-direction text, keyboard and Back, tab state, direct-route guard, sign-out during a request, timeout/retry, and airplane-mode FAQ. Recheck Home and More → Balances and existing operations routes against V01, V03, V05, V07, and V08. Record commands, device/API, dataset, and results in this package before closing it.

## Planning evidence

- Baseline checked with `git status --short --branch` and `git log -1 --oneline`. Branch `codex/fuel-card-portal` was at `7aea3d0`, with pre-existing edits in the Package 06 Flutter handoff and Android `MainActivity.kt`.
- Code inspection confirmed the Arabic default and stored locale, the five shell destinations, the existing Home → Balances shortcut, the FAQ under More, and an existing Arabic-first widget assertion. Planning completed through source inspection. See the offline implementation evidence for the updated Android results.
- Approved support content, an approved contact if offered, and a provider and hosting decision are inputs for the connected customer rollout.
