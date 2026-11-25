# Gemini pilot for Arabic Support

Status Firebase Spark pilot verified on the Android emulator · Sideload configuration verified · Physical-device attestation pending · Baseline `69b986c` on `codex/fuel-card-portal`

## Connection from Android devices

Flutter calls Firebase AI Logic using the Gemini Developer API and `gemini-3.5-flash-lite`. Google’s managed gateway handles App Check. This setup requires a Firebase Android app and internet access from the device. There is no project-owned backend to run. The app includes the prototype project’s Firebase client configuration and initializes Firebase when an eligible question is sent. [Flutter setup](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter) · [App Check](https://firebase.google.com/docs/ai-logic/app-check)

## Firebase project setup

The pilot uses **Golden Gate Support** (`golden-gate-support-saed`) on the Spark plan. Gemini Developer API is enabled, App Check is enforced, and the emulator has a registered debug token. Optional AI Monitoring was left disabled. [Firebase Console](https://console.firebase.google.com/project/golden-gate-support-saed/ailogic)

The default Android build uses the checked-in Firebase client identifiers. Build with `flutter build apk --release` for sideload testing. Use `flutter run` for debug testing or `flutter run --dart-define=SUPPORT_OFFLINE_ONLY=true` to exercise local support. For a separate Firebase project, override all four client values together using the optional steps below. The App Check debug token and signing key stay outside the repository.

1. In the Firebase console, register the Android app ID `com.example.fleet_cards_demo` in a dedicated project. In AI Logic, select **Gemini Developer API** and complete the guided setup. Review the active project quota and the provider’s terms before running the pilot. [AI Logic setup](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter) · [Gemini free-tier terms](https://aistudio.google.com/docs/terms#unpaid-services)
2. In the Android app settings, download the Firebase configuration. Copy the four client values below from the matching entry for `com.example.fleet_cards_demo` to a JSON file outside the repository. The Firebase client API key identifies the Firebase project. The Gemini API key stays with Google’s managed service.

   | Launch value | Field in the Firebase Android configuration |
   | --- | --- |
   | `SUPPORT_FIREBASE_API_KEY` | Matching client’s `api_key[].current_key` |
   | `SUPPORT_FIREBASE_APP_ID` | Matching client’s `client_info.mobilesdk_app_id` |
   | `SUPPORT_FIREBASE_PROJECT_ID` | `project_info.project_id` |
   | `SUPPORT_FIREBASE_SENDER_ID` | `project_info.project_number`, as a JSON string |

3. Launch the normal Flutter entry point. The example assumes the four client values are in `firebase-support.json`. In VS Code, put the same `--dart-define-from-file=…` argument in the Dart debug configuration’s `toolArgs`.

   ```sh
   flutter run -d <android-device-id> --dart-define-from-file=/absolute/path/to/firebase-support.json
   ```

4. For debug verification on the emulator, send an eligible question such as «كيف بتشتغل بطاقة البوابة الذهبية؟». Register the generated App Check debug token in the Firebase console for the Android app and retry. Keep the token private. For a distribution build, register the signing certificate and configure Play Integrity in App Check. Keep App Check enforcement enabled. Verify the intended distribution channel with a signed device build. [Emulator debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider) · [Play Integrity](https://firebase.google.com/docs/app-check/android/play-integrity-provider)

## Answering behavior

- A configured app sends questions to Gemini before trying a local answer. It includes up to four matching excerpts from the website, customer guide, or bundled app instructions. It can send a request with zero excerpts. A previous topic title can help resolve short follow-ups. The original Word document stays outside the app. The full transcript and app account records stay on-device.
- Gemini can help with common questions about Golden Gate, its services, the app, or the website even when there is no matching excerpt. It can offer practical next steps without asserting unverified features or company facts. Specific facts still require evidence. Unrelated requests get a scope redirect. The app keeps messages containing apparent credentials or sensitive identifiers on-device. [Free-tier terms](https://aistudio.google.com/docs/terms#unpaid-services)
- Flutter validates Gemini's factual answer IDs against the excerpts sent in that request. Practical guidance can use an empty source ID. The chat displays the reply without provider or source labels. No model tools are enabled. [Structured output](https://firebase.google.com/docs/ai-logic/generate-structured-output)
- The app shows **Golden Gate AI Assistant** in English and «مساعد البوابة الذهبية الذكي» in Arabic. When the model identifies an introduction request, Flutter renders the same localized introduction used for matching offline identity questions. Both introductions contain the exact product name.
- The searching indicator remains active while the device waits. Missing configuration, invalid output, failed requests, or an eight-second deadline use the bundled search. Tabs preserve the active conversation within the session. Disposed Support screens ignore late replies.

## Acceptance

- [x] **Credential-free coverage.** Use a fake generator to verify website and guide payloads, follow-up topic, local handling for personal requests, source ID validation, provider failure, chat citations, and fallback.
- [x] **Live Gemini.** Send a public card question, a paraphrase, and a card follow-up. Verify the replies in Arabic against the public passages and confirm the official source link.
- [x] **Emulator App Check and offline fallback.** Register the emulator debug token, observe the searching indicator and Gemini label, then verify the local reply in airplane mode.
- [ ] **Release verification.** Verify Play Integrity with the release signing certificate and intended distribution channel. Exercise sign-out while a request is pending. See V01, V07, and V08 in the [Android verification matrix](../verification.md).

## Emulator evidence

- `flutter analyze --no-pub` and `flutter test --no-pub` passed. The test suite ran 42 tests.
- `flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=<local-config>` built the configured APK. The regular debug APK rebuilt and installed after Arabic integration testing has SHA-256 `2eff22194fcdd75c509ae17b760fb68a61074b75468fff5de416557ae9e88715`.
- `adb -s emulator-5554 install -r <debug-apk>` and `adb -s emulator-5554 shell am start -W -n com.example.fleet_cards_demo/.MainActivity` succeeded on Android API 36. The model was `gemini-3.5-flash-lite` and the catalog schema version was 2.
- The Arabic card question returned an Arabic Gemini answer about prepaid refuelling. “Where can I use it” showed the searching state and then returned an Arabic answer about Golden Gate and Taiba stations. Both showed the official website as the source. Play Integrity has yet to be verified with the release signing certificate and intended distribution channel.
- `adb -s emulator-5554 shell cmd connectivity airplane-mode enable` let the prepaid card question return a local Arabic answer with a guide citation. After restoring connectivity, a rephrased question about businesses returned an Arabic Gemini answer confirming suitability for companies and fleets.
- `flutter test --no-pub integration_test/live_arabic_support_test.dart -d emulator-5554 --dart-define-from-file=<temporary-test-config>` passed from the staging checkout with the registered emulator credential. «بطاقة الوقود بتنفع للشركات كمان؟» and «طيب وين فيني استعملها؟» each showed the searching indicator and returned a live Arabic Gemini reply with the official source. The Arabic balance question used the local app instructions.
- After enabling guide excerpts, `flutter test --no-pub integration_test/live_guide_support_test.dart -d emulator-5554 --dart-define-from-file=<temporary-test-config>` passed in staging on API 36. General Syrian-Arabic questions about Sham Cash processing and monthly fees received live Arabic Gemini answers citing «دليل خدمة العملاء». The balance question still used the local app instructions. The guide's advice to check the current monthly amount appeared in the answer.
- The guide update passed `flutter test --no-pub` (43 tests), `flutter analyze --no-pub`, and `git diff --check`. The regular configured ARM64 debug APK installed and launched on `emulator-5554` after the live test. Its SHA-256 is `5ed5bea045421847f442b761d5b735e3b3ead91b40bddf809126cbdc58f4162b`.
- Gemini-first routing passed `flutter test --no-pub` (46 tests) and `flutter analyze --no-pub`. The tests confirm that the Arabic manager question reaches Gemini with zero excerpts, unrelated questions reach Gemini and receive a separate refusal, and failed requests use the labeled on-device search. The configured ARM64 APK installed on `emulator-5554` with SHA-256 `d0670233c106154240b8e415cb1847da76b5d1349185cf74aa829d2d79450a0d`.
- The scope and chat update passed `flutter test --no-pub` (46 tests), `flutter analyze --no-pub`, and `git diff --check`. The final ARM64 debug APK installed and launched on Android API 36 with SHA-256 `eab4b7e8478fcd64baef7682620d81a96ee48fd8c9b2df1eab40a7a579a4324e`. Live questions about the company manager and a cake recipe returned the scope redirect. The Sham Cash processing question returned the guide's 24-working-hour timeframe. All three replies appeared in Arabic without provider or source labels.
- The general support update passed `flutter test --no-pub` (48 tests), `flutter analyze --no-pub`, and `git diff --check`. The configured ARM64 debug APK installed and launched on API 36 with SHA-256 `1b1f68f4845189cdadbfdd30540b6098b5265d395770b7a16cf3f4ab78ff5b40`. The emulator answered app-usage, app-benefit, and website questions in Arabic and redirected an unrelated cake recipe request. The chat showed no provider or source labels.
- The assistant naming update passed `flutter test --no-pub` (49 tests), `flutter analyze --no-pub`, and `git diff --check`. Widget coverage verifies both localized titles and the English introduction. The emulator showed the Arabic title and returned the branded Arabic introduction for an indirect identity question online. The configured ARM64 debug APK installed on API 36 with SHA-256 `91786f104239d3703fd79aefdb47de27dbf63a26a7581f6ad5132547ce4da75a`. On that build, a paraphrased identity question returned the branded introduction in airplane mode. Connectivity was restored afterward.
- For sideload testing, the Play Integrity API was enabled, the APK signer’s SHA-256 fingerprint was registered, and the App Check configuration was verified via the Firebase API. It allows off-Play installs and requires `MEETS_DEVICE_INTEGRITY`. Cloud Billing was confirmed disabled. [Firebase sideload settings](https://firebase.google.com/docs/app-check/android/play-integrity-provider#configure-advanced-settings-optional)
- `flutter build apk --release` built the configured APK without Dart defines. `apksigner verify --print-certs` and `aapt dump badging` verified the development signature, API 24 minimum, and ARM64, ARMv7, and x86-64 support. APK SHA-256 `27e526eeb7be2cb3834411fffad47a6c921bb9b7d1b35f40381ccbbf5274439e`. The installed APK launched on Android API 36 and initialized Firebase and Play Integrity when asked about app features. Successful release attestation and a live response on a physical phone remain unverified. All 49 Flutter tests and Flutter analysis passed with the default client config.
