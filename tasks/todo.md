# Implementation status

## Phase 1 — integration readiness and contract

- [x] Inspect both clean repository baselines and the current read/publish code.
- [x] Check live Worker deployment history without deployment or secret access.
- [x] Read local/cloud aggregate status and confirm a fresh linked publication.
- [x] Record the user's confirmation of offline desktop restart/reconnect success.
- [x] Add a producer-owned generated read schema, API guide, and all-kind fixtures.
- [x] Exercise fixtures through the actual authenticated Worker/D1 pipeline.
- [x] Add desktop-backed quota/status/timezone parity fixtures.
- [x] Pin canonical fixtures in mobile and add standalone Dart decoding checks.
- [x] Document stable app identities, public configuration, and registration order.
- [x] Complete and record automated final verification (see Phase 1 evidence).
- [ ] Deploy/confirm the already merged Worker recovery hardening and use the
      intended updated desktop build; existing production code is older.
- [ ] Complete real second-account isolation using a separate profile/database.
- [ ] Close the Phase 1 gate with deployment/build and acceptance evidence.

## Phase 2 — foundation and authentication

- [x] Replace the starter with app composition and feature-owned code/tests.
- [x] Register separate development/production Firebase Android apps and configure flavors.
- [x] Add the authenticated read-only network boundary, bounded token refresh,
      identity cancellation, safe failures, and server-directed rate-limit backoff.
- [x] Implement sign-in/restoration, verification recovery, reset, and sign-out.
- [x] Implement workspace discovery and clear loading/setup/offline/session recovery.
- [x] Add controller, contract/configuration, network, accessibility, and widget tests.
- [x] Complete native emulator build and SDK/restart journeys; record results
      (Android 17/API 37; older-image compatibility caveat is recorded).
- [ ] Complete private existing-account production workspace acceptance on Android.

## Phase 3 — projects and offline reading

- [x] Decode typed allowlisted v1 project records and canonical fixtures.
- [x] Traverse opaque root cursors; reject malformed/partial/duplicate results.
- [x] Add transactional SQLite scope replacement and persisted workspace discovery.
- [x] Revoke leases and nested routes on UID/workspace changes and access denial.
- [x] Clear saved metadata before completing sign-out; handle failed cleanup.
- [x] Add responsive list/detail, loading/empty/no-download/error recovery, and
      separate observation/receipt/download timestamps using the existing UI.
- [x] Refresh on user request/resume without polling; respect retry deadlines.
- [x] Verify controller, contract, cache, identity/navigation, and widget behavior.
- [x] Complete all three native Android project/restart probes (demo Firebase,
      intercepted Worker transport, real native SQLite); record evidence.
- [x] Finish normal development APK, analyzer, formatting, fixture parity, and
      full-suite checks (**94 passed**); record results.
- [ ] Complete private desktop-to-production-to-mobile updates/deletion,
      offline restart, and second-account acceptance.

## Phase gates

### UI interlude — soft minimalism

- [x] Preserve the navy/sky-blue accent and bundle licensed Inter typography.
- [x] Share rounded cards, adaptive headings, and accessible tactile primary actions.
- [x] Generate and bundle Venty, with the prompt and asset provenance recorded.
- [x] Restyle authentication, workspace connection, and startup/session states.
- [x] Verify 52 tests, analyzer, responsive/accessibility states, Android rendering,
      and all three native demo Firebase restart probes. See
      `docs/phase-2-verification.md` and `docs/visual-design.md`.

### Release gates

The [dashboard/navigation UI interlude](../docs/dashboard-navigation.md) adds a
Home-first shell, right-side project selector, and real project analytics without
changing the master phase order or closing the private production gates.

- [ ] Phase 2: implementation/local checks complete; private production-account
      acceptance remains before closing the gate.
- [ ] Phase 3: implementation/local verification recorded in
      `docs/phase-3-verification.md`; private production journey remains a gate.
- [ ] Phase 4: Agent usage with canonical parity and cached details.
- [ ] Phase 5: Complete tracker/validation browsing with pinned snapshots.
- [ ] Phase 6: Integrated/device verification and Android internal release.
- [ ] Phase 7: macOS/iOS verification, TestFlight, and iOS release.

On 2026-10-15 the user accepted the tested account-switch/publishing workflow,
confirmed desktop main was merged, and explicitly authorized Phase 2. The older
production-deployment/build evidence above remains a separate unverified release
checkpoint, not a reason to block the authorized mobile implementation. Do not
mark a live production journey complete from fixtures or emulator results.

On 2026-10-16 the user reported authentication working and explicitly authorized
Phase 3. This is authorization to implement projects/offline reading, not evidence
that the new project's production/device acceptance has already passed.
