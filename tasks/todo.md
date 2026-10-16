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

## Phase gates

- [ ] Phase 2: implementation/local checks complete; private production-account
      acceptance remains before closing the gate.
- [ ] Phase 3: Projects, atomic account-scoped offline cache, and refresh.
- [ ] Phase 4: Agent usage with canonical parity and cached details.
- [ ] Phase 5: Complete tracker/validation browsing with pinned snapshots.
- [ ] Phase 6: Integrated/device verification and Android internal release.
- [ ] Phase 7: macOS/iOS verification, TestFlight, and iOS release.

On 2026-10-15 the user accepted the tested account-switch/publishing workflow,
confirmed desktop main was merged, and explicitly authorized Phase 2. The older
production-deployment/build evidence above remains a separate unverified release
checkpoint, not a reason to block the authorized mobile implementation. Do not
mark a live production journey complete from fixtures or emulator results.
