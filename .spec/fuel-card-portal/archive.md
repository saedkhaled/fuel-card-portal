# Fuel-card portal closeout

Archived 25 November 2026 · Demo release `0.1.0+1`

All five implementation packages are complete. The delivered Flutter app uses editable synthetic JSON and runs offline in Arabic and English. The archive keeps the planning documents and completed packages at their existing paths so their evidence links continue to work. [Execution memory](memory.md) · [Fixture editing guide](../../assets/demo/README.md)

- The Android acceptance index maps all 23 reference workflows to demo behavior and its evidence. The reference audit records the limits of the sampled staging flows. [Coverage matrix](step5_android_acceptance/coverage.md) · [Reference audit](reference-audit.md#evidence-limits)
- Formatting and analysis passed, along with 26 local tests and five Android integration tests. The release APK passed installed offline checks on API 36 and a fresh offline sign-in, Home, and Cards smoke check on API 24. TalkBack focus was spot-checked on Arabic sign-in and the language sheet. Full spoken traversal across screens remains unverified. [Android acceptance handoff](step5_android_acceptance/package.md#artifact-and-verification-evidence)
- The development-signed sideload APK is `build/android-acceptance/fleet-cards-demo-release.apk`. Its SHA-256 is `960b1b69b2c3eec56507f6e0e60cdcf8246575f0653df32ed3dd0890e2e3f472`. Rebuild and install instructions are in the project README. [Build and run guide](../../README.md#build-a-sideload-apk)
