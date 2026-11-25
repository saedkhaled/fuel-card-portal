# Package 07 · Arabic-first AI support

Status Offline demo verified on Android · Connected support planned

## Product scope

Give signed-in customers a main **الدعم / Support** tab where they can type a question and receive an answer in Arabic based on the approved support material. Customers can ask in their own words, use Syrian colloquial Arabic, or ask a follow-up. The assistant covers fuel-card portal support topics supported by the material. When coverage is missing it asks a focused clarifying question if that could help, then offers the existing FAQ or an approved support contact.

Keep Arabic as the app’s first-run language on Android, including on English-language devices. `PortalSettings` already defaults to Arabic when there is no saved English choice, and `PortalBootstrap` already uses Arabic while loading. Preserve explicit English selections and the language picker before and after sign-in. Add regression coverage for fresh launch, restored sessions, and switching back to Arabic. Support replies in clear Arabic by default, including when a customer types English, and switches to English on explicit request when an approved answer can support it. Interface labels follow the app’s selected language.

Read the [current navigation contract](../architecture.md#navigation-and-state), [Account services package](../step4_account_services/package.md), [Flutter design handoff](../step6_figma_redesign/flutter-handoff.md), and [Android verification](../verification.md).

## Navigation and chat

- Use five primary destinations in logical order from the reading edge. **Home · Cards · Support · Stations · More**. Give Support a raised button treatment in the center of the existing bar. Implement it as a selectable destination with a visible label, selected state, and accessibility semantics. Keep it centered in Arabic RTL and English LTR.
- Keep `/balances` reachable through the existing Home shortcut and add a Balances entry under More. Retain the route and existing operations links. Keep the FAQ under More and link it from Support. Update affected navigation tests to use the new entry points.
- Give Support its own guarded shell branch at `/support` and preserve its draft and conversation while switching tabs within the same session. Android Back dismisses the keyboard first, then returns to the previous app destination or Home when entered directly. Sign-out clears the draft and transcript and discards in-flight replies.
- Use the existing visual system for the chat page. Show a short invitation, a few starter questions drawn from approved topics, the conversation, and a text composer. Show loading, retry, offline, and no-answer states in both UI languages. Keep the composer reachable with the keyboard open and announce completed replies to TalkBack.

## Support material

Start from a Q&A sheet or table supplied by the content owner. Accept an Arabic-only first version. Import CSV from Excel or Google Sheets into a versioned support catalog. A single import flow lets the owner update the online catalog without an APK release. Bundle a reviewed subset for offline use, refreshed on app releases.

| Column | Use |
| --- | --- |
| `id` | Stable identifier for citations, updates, and review |
| `topic`, `question_ar`, `answer_ar` | Required topic and approved Arabic question and answer |
| `aliases_ar` | Optional Syrian phrasing, spelling variations, and alternate questions |
| `question_en`, `answer_en` | Optional English content |
| `source_title`, `source_url`, `app_route` | Human-readable source and optional approved link or app destination |
| `status`, `updated_on` | Publication status and last content update |

Validate unique IDs, required values, approved status, and allowed routes or links. Keep the previous published version if an import fails. If the supplied table contains several related facts per row, group them into approved entries with durable source IDs. Use synthetic Q&A while building the demo. Review the real sheet and any contact details with its owner before publishing. Keep internal instructions, credentials, and customer records outside the catalog.

## Answering and connectivity

1. Normalize Arabic for matching while preserving the original displayed text. Retrieve relevant published entries using the question, approved aliases, and brief conversation context for follow-ups. Start with search over the small catalog and evaluate real questions before adding more complex retrieval.
2. Send the selected entries to a model through a small HTTPS backend for concise, natural answers. Return answer text, source IDs, and any validated app destination. The backend resolves those IDs and destinations against the retrieved catalog. The app displays the source title or a link to the appropriate screen. Use the approved FAQ text directly for an exact match where practical.
3. Route ambiguous questions to clarification. When the answer is missing, conflicting, or unsupported, show a localized fallback such as «ما عندي معلومة مؤكدة عن هالسؤال. جرّب قسم الأسئلة الشائعة أو تواصل مع الدعم.» Offer an approved contact when available. For personal balance, payment status, or current station availability, point to the relevant portal screen. Account lookups and actions are outside this release.
4. Ship the offline Flutter demo with local matching against the bundled FAQ subset. When there is a reliable match, show the approved answer and source. When there is no match, explain that full chat needs a connection and offer the FAQ. Use the same fallback on service failure or timeout, with a retry action available. Keep sign-in and existing demo workflows usable in airplane mode.
5. Store model credentials on the server. For a connected demo, use only a sandbox and synthetic content. Before a customer rollout, choose a provider and hosting, require real backend authentication, set rate limits and usage budgets, and agree on data handling and retention. Keep the first release’s transcript in memory, keep account fixtures out of model requests, and minimize logs. Use a concise composer reminder about OTPs and payment details. Check obvious sensitive values before requests leave the app. Treat source text and user messages as data, and constrain replies and links to the approved catalog.

## Offline demo scope

[Implementation and verification evidence](offline-implementation.md)

The [bundled knowledge base](../../../assets/demo/standard/support.json) holds 58 searchable passages from the public website, the supplied Arabic customer guide, and the demo app guides. Each passage has a topic, factual text, search terms, and provenance. Optional starter prompts help users explore the data. The local search ranks topic and passage terms, normalizes Arabic spelling and digits, and uses the preceding subject for short follow-ups. It shows the guide section or an official link and offers the FAQ on weak or ambiguous matches. The draft and transcript live in the Support branch for the current sign-in session.

Gemini Developer API Free is the initial pilot candidate for public FAQ material and synthetic test questions. Google lists Syria in its supported regions and says it may use free-tier requests and responses to improve its products. Cloudflare Workers AI is the free alternative to evaluate. Its Free plan has a daily inference allowance, and Cloudflare says it does not train on customer prompts or answers. Evaluate both on the same approved Arabic questions, including Syrian phrasing, and confirm deployment eligibility and free quotas before choosing the connected provider. [Gemini availability](https://aistudio.google.com/docs/available-regions) · [Gemini free-tier terms](https://aistudio.google.com/docs/terms#unpaid-services) · [Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/) · [Workers AI data usage](https://developers.cloudflare.com/workers-ai/platform/data-usage/)

## Implementation and acceptance

- [x] **Offline Flutter shell and locale.** Added the centered Support route, chat, Arabic and English interface labels, and Balances entry in More. Verified Arabic on fresh install with Android set to English, locale selection and restored preference, and the centered tab in both directions.
- [x] **Bundled sample catalog.** Add the offline repository and five synthetic Q&A entries. Tests cover exact answers, Arabic spelling and Syrian aliases, English aliases, missing and ambiguous matches, duplicate IDs, and invalid links.
- [x] **Arabic customer guide.** Add reviewed passages from the supplied guide and test paraphrases, follow-up questions, source display, and the searching state.
- [ ] **Online catalog updates.** Add a publishing path for owner updates that reach the app without an APK release.
- [ ] **Connected answers.** Add a backend and an injectable Flutter client after choosing hosting and a model. Evaluate against owner-reviewed questions and expected source IDs. Cover direct questions, Syrian phrasing, English input with Arabic output, explicit English replies, follow-ups, missing or conflicting data, account-specific requests, and instructions embedded in chat or source rows. Pass each fixture only when the answer stays within the expected facts and links resolve correctly, or the expected clarification or fallback is shown. Record the reviewed catalog version and cases.
- [ ] **Android acceptance.** Run localization generation, Flutter analysis, unit/widget tests, and installed Android walkthroughs. Check 360 dp, 1.3× text, TalkBack traversal, Arabic and mixed-direction text, keyboard and Back, tab state, direct-route guard, sign-out during a request, timeout/retry, and airplane-mode FAQ. Recheck Home and More → Balances and existing operations routes against V01, V03, V05, V07, and V08. Record commands, device/API, dataset, and results in this package before closing it.

## Planning evidence

- Baseline checked with `git status --short --branch` and `git log -1 --oneline`. Branch `codex/fuel-card-portal` was at `7aea3d0`, with pre-existing edits in the Package 06 Flutter handoff and Android `MainActivity.kt`.
- Code inspection confirmed the Arabic default and stored locale, the five shell destinations, the existing Home → Balances shortcut, the FAQ under More, and an existing Arabic-first widget assertion. Planning completed through source inspection. See the offline implementation evidence for the updated Android results.
- Approved support content, an approved contact if offered, and a provider and hosting decision are inputs for the connected customer rollout.
