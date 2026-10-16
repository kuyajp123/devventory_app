# Phase 1 verification — 2026-10-15

Status: local contract implementation complete; production integration gate
remains open. Later mobile feature phases have not started.

## Baselines and live evidence

- Desktop base: `0f1ef9d`, including merged authentication/recovery work and the
  subsequent development/installed profile isolation. Both checkouts were clean
  before this implementation. Source changes here add contract tooling/tests/docs;
  they do not change Worker runtime, desktop domain behavior, or database schemas.
- Wrangler's read-only deployment history still reports live Worker version
  `41fe33a5-5ed6-4108-856b-d68c73498df5` (deployed 2026-10-14 02:17:38 UTC).
  The merged recovery hardening is not confirmed deployed; the recorded live
  version predates it. No deployment was performed by this work.
- Read-only installed-profile query: sync enabled, account linked, no blocked
  code, zero pending scopes, last success `2026-10-15T03:41:25.051Z`.
- Read-only development-profile query: sync disabled, account linked, zero pending
  scopes, last success `2026-10-14T02:40:46.664Z`. Preserve this profile separation.
- Remote D1 aggregate SELECT: one owned workspace, one active publisher, 24 visible
  scopes, latest publication `2026-10-15T03:41:25.051Z`; zero rows written.
  This supports fresh linked-publication evidence, not second-user isolation.
- The user confirmed **Only offline restart/reconnect completed** in this session.
  This is user-reported acceptance; this agent did not perform that device action.

Only timestamps, counts, status, and deployment identifiers were inspected for
these checks. No production records, saved credentials, or token values were
printed or copied. Local/cloud data was not modified.

## Local deliverables

The desktop repository now owns a read response schema derived from its upload
allowlist, generated JSON Schema, complete endpoint/consistency guide, and
synthetic fixtures. Worker tests publish synthetic snapshots into disposable D1
and compare actual authenticated reads against the portable examples. Rust tests
check quota thresholds, precedence, elapsed resets, next-reset selection, and IANA
calendar/DST examples against the existing domain functions.

Mobile pins the read/quota fixtures and runs Dart decoding checks without Firebase
registration, HTTP integration, or changes to the starter app. App identifiers and
configuration/registration order are established in `mobile-setup.md`.

## Acceptance still required

1. Deploy/confirm the already merged recovery-hardening Worker and use the updated
   desktop build. Follow the desktop authentication setup guide's rollout steps;
   no new migration, secret rotation, ownership adoption, or data rebuild is needed.
2. On a separate profile/database containing only synthetic data, sign into a
   separate verified account, set up its workspace, and confirm it cannot see the
   existing owner's cloud metadata. Do not switch the real owner's local database
   to the test account or send credentials in chat.
3. Record the tested desktop build/profile, Worker version, and isolation outcome.
   Confirm publication/reconnect acceptance also applies to that intended build.

Synthetic isolation tests remain necessary but do not replace this real-account
checkpoint. This was the original Phase 1 pause point.

### User acceptance and continuation, 2026-10-15

The user reported completing offline restart/reconnect, tested the second-account
workflow, accepted its behavior, confirmed desktop main was merged, and explicitly
requested Phase 2 implementation. Local mobile integration is therefore proceeding.
The separate-profile/build identifiers and updated live Worker deployment have
not been independently reconfirmed here. Preserve those as release evidence gaps;
do not infer a deployment from a Git merge or claim independent production isolation
proof from the user's workflow acceptance alone.

## Automated verification

| Check                                  | Result                                                         |
| -------------------------------------- | -------------------------------------------------------------- |
| Worker TypeScript check                | Pass                                                           |
| Full cloud suite                       | 38 passed, 0 failed                                            |
| Contract export drift check            | Pass                                                           |
| ESLint for added TypeScript/JavaScript | Pass                                                           |
| Desktop repository Prettier check      | Pass                                                           |
| Worker deployment dry run              | Pass; no deployment performed                                  |
| Focused Rust quota fixture test        | Pass; 15 status and 6 timing scenarios                         |
| Rust formatting check                  | Pass                                                           |
| Full Rust library suite                | 168 passed, 0 failed                                           |
| Flutter analysis                       | Pass; no issues                                                |
| Full Flutter suite                     | 5 passed, 0 failed (4 contract checks and original smoke test) |
| Producer/mobile fixture comparison     | Both files match                                               |
| Git whitespace checks                  | Pass in both repositories                                      |

The source review covered schema derivation, upload/read compatibility, fixture
scope/pagination, safe issue messages, generated-schema drift, and repository
ownership. No runtime Worker handler, desktop domain, dependency, or migration was
changed. Rust linking still emits the existing libsodium PDB/default-library
warnings. Android/iOS runtime, signing, Firebase registration, and production
private-account journeys are not claimed by these checks.
