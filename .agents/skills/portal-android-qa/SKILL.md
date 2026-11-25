---
name: portal-android-qa
description: Verify the fuel-card portal Flutter demo on Android, inspect mock exports and RTL behavior, and produce evidence for the sideload APK handoff.
---

# Fuel-card portal Android verification

Follow the relevant V-IDs in [verification.md](../../../.spec/fuel-card-portal/verification.md). Use Flutter `integration_test` for app flows and ADB for the system actions specified there. Confirm the intended emulator, app ID, and install mode before interacting. Prefer a task-owned device when the current one is busy.

- Test using synthetic scenarios. Run the installed APK walkthrough offline and verify the artifact independently of `flutter run`. Check Arabic navigation, soft keyboard, larger text, and OS save/share cancellation. Inspect both file formats against a known fixture query.
- For APK reference follow-up, use normal UI and a user-supplied test account when authorized. Observe confirmations and exit external payment, sharing, contacting or navigation surfaces before taking any such action. Record anonymized behavior and note what remains unsampled.
- Capture the exact commands, actual API levels, test results and checksum. Send evidence to the package owner for reconciliation.
