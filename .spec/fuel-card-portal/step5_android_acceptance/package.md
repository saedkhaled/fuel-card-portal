# Package 05 · Android acceptance

Status awaiting 03–04 · Estimate 2–4 h

## Objective and ownership

Integrate the full Android app, verify the [acceptance matrix](../verification.md), and produce a tested, installable demo APK and a short build/run handoff.

## Tasks

- [ ] Record the route, action outcome, JSON scenario, and evidence for each R01–R23 requirement. Validate and hand off the bundled JSON files and editing guide. Check all locale strings, empty/error states, phone-sized layouts and isolated synthetic data. Fix scoped defects.
- [ ] Run format, analyze, tests, and the full Android integration journey. Exercise system save/share, note restart persistence, Back guard, Arabic RTL and airplane mode on the installed APK.
- [ ] Verify the declared minimum on an API 24 AVD if available. Record actual tested API levels. Inspect merged permissions, application ID and supported ABIs.
- [ ] Build and install the final demo APK. Verify fresh sign-in on that binary. Record checksum, build commands, signing mode, demo login and run instructions. Keep deliverables free of staging data.
- [ ] Reconcile all package states and evidence in memory. Summarize verified behavior and any remaining gaps.

## Exit

The demo artifact is installable and the evidence matrix is complete with outcomes. Package status and handoff reflect the tested build.
