# Phase 3 — projects and offline reading

Implemented locally on 2026-10-16 following the user's explicit Phase 3 request.
No Worker/desktop code, Firebase configuration, production data, deployment,
release signing, commits, or pushes are part of this change.

## Delivered behavior

- The connected workspace opens a soft-minimalist project list and read-only
  detail screen. Existing Inter, navy/sky-blue accents, rounded cards, tactile
  primary actions, and Venty are reused.
- Typed v1 records validate kind, identities, names, project types, timestamps,
  nullable descriptions, and publication anchors. Only allowlisted fields persist.
- The repository traverses opaque cursors at 100 records per page. Incompatible,
  malformed, duplicate, cyclic, or failed pages cannot replace a complete cache.
- A full successful fetch replaces the saved list, including deletions and an empty
  result. Staged pages are not presented as a successful partial list.
- SQLite preserves the complete list and workspace across a process restart for
  the same restored Firebase user. Every downloaded project includes its details,
  even if that detail was never opened before going offline.
- Manual/pull-to-refresh and app resume check workspace ownership and refresh
  projects. No continuous polling or publishing is added. Server retry deadlines
  disable early retries; temporary errors preserve the last complete download.
- Download time, desktop observation time, and cloud receipt time are distinct.
  Exact times use the device timezone. Downloading now does not imply desktop
  publication is current.
- Sign-out, UID/workspace changes, and explicit authorization denial dispose old
  routes and revoke old cache access. Late results cannot repopulate a revoked
  scope. Cleanup failures have a retry path and cannot report successful sign-out.
- Never-downloaded, successfully empty, cached/offline, loading, failed saving,
  expired session, and removed-project states are distinguished.

## Contract and storage decisions

The Worker root projects list has **no global snapshot token**. The app checks
workspace identity before and after traversal and commits the completed local
scope atomically. It does not invent root snapshot pinning or claim that separate
root pages represent one point in time. Per-project `snapshotId` remains available
for later child-scope reads in Phase 5.

See [ADR-001](decisions/001-private-metadata-cache.md) for cache ownership,
transaction semantics, failure behavior, backup policy, and limitations. The
database is private metadata storage, not an encrypted credential vault. Firebase
tokens remain in SDK-managed session storage and are never serialized into it.

## Verification record

- `flutter test --no-pub test lib --reporter=expanded`: **94 passed**.
- `flutter analyze --no-pub`: **no issues**.
- `dart format --output=none --set-exit-if-changed lib test integration_test tool`:
  **unchanged**.
- `dart run tool/check_contract_sync.dart ../devventory`: **both producer fixtures match**.
- `git diff --check`: **passed**.

Final checks were rerun after the native fixture correction and year-inclusive
freshness labels. The suite includes both direct synthetic-transport checks and
an asynchronous widget-to-repository-to-SQLite journey, in addition to feature
tests and the existing authentication/UI regression suite.

Native probes on Pixel 9 Pro, Android 17/API 37, 16KB pages:

- **Seed passed:** real demo Firebase SDK identity, native SQLite, two project
  pages/101 records, and read-only detail/freshness.
- **Restore passed:** a new process restored the SDK identity and complete list
  with the Worker transport offline, opened previously unopened project 101,
  reconnected to receive an edit/deletion, removed the deleted detail, opened the
  updated project, and signed out through the actual cache-cleanup/SDK flow.
- **Signed-out passed:** another new process found no SDK session, no cached
  scopes, and a null stored owner before app startup cleanup ran; sign-in remained
  available without any workspace reads.
- `flutter build apk --debug --flavor development --no-pub`: **passed**. The normal
  app entry point was installed back over the native test APK. This is a debug
  development build, not a production-signed release. Native captures
  of project cards/detail are under `build/phase3-projects-offline.png` and
  `build/phase3-project-details.png` (ignored diagnostic artifacts; scroll/pointer
  overlays can appear in integration captures).

Tests cover canonical contract decoding, two-page traversal, partial failure,
invalid cursors/records, offline reload, atomic replacement, deletions, corruption,
UID/workspace isolation, obsolete writes, authorization denial, cleanup failure,
retry deadlines, and lifecycle navigation. Widget checks cover 320dp with 2× text
and 768/1024/1440dp, readable detail, target labels/sizes, contrast, empty/offline
states, and deletion while a detail is open.

## Reproduce native offline checks

Start a fresh local Auth emulator as described in
[mobile setup](mobile-setup.md#native-authentication-checks-without-a-production-account),
then run:

```powershell
./tool/test_projects_journey.ps1 -Device emulator-5556
```

Select a healthy Android AVD from `flutter devices`. Three separate app processes
use a named demo Firebase app and real native SQLite: download 101 synthetic
projects over two pages; restore offline, open an unopened detail, refresh an edit
and deletion, then sign out; confirm both the signed-out SDK and empty database
persist. The test inspects the database before startup cleanup in the last probe.

Worker responses and its offline transport failure are synthetic at an intercepted
`synthetic.invalid` origin. A
real local Firebase SDK token exercises the authenticated network boundary, but
never reaches production. Only synthetic emulator users and a dedicated test
database are changed. Repeated Phase 3 seed runs can sign in to the same known
synthetic emulator identity; a fresh Auth emulator is still recommended. Native
scripts use `--no-uninstall`; the test APK remains installed afterward. Run the
normal development entry point again when finished.

Do not run host tests and native Flutter builds/tests simultaneously in the same
checkout: both prepare `build/unit_test_assets`, including the native asset
manifest. One overlapping run lost the Windows SQLite mapping; isolated runs
must establish the final result, without weakening tests or changing the SDK.

Native validation found and corrected an Android-specific database-open issue:
`PRAGMA secure_delete` returns a result row and must use `rawQuery`, not `execute`.
The FFI implementation had accepted the latter. It also exposed two test-harness
constraints: await real I/O rather than treating idle frames as completed storage,
and avoid Flutter's guarded `expect` inside asynchronous transport callbacks.
Fixture checks now use ordinary validation; test assertions run in the test body.
Large-page host widget tests yield to Dio's real JSON-decoding isolate.

The initial API 35/Pixel 6a attempt crashed with a Firebase-internal
`NoSuchMethodError`; that AVD already has documented ART/System UI failures.
API 37 cold/software-rendered attempts also showed System UI timeouts
under memory pressure. Final native checks use one hardware-rendered AVD, with
idle build daemons stopped. These are environment observations, not evidence of
compatibility or release performance on physical devices. Existing FlutterFire
Kotlin, Java native-access, and SDK XML tool warnings remain; no SDK/dependency
upgrade or suppression was introduced for them.

## Remaining live acceptance and release boundaries

Using synthetic desktop metadata on the production-connected development build:

1. Refresh mobile after a desktop project edit and deletion; verify metadata parity
   and distinct freshness timestamps.
2. Fetch projects, fully stop/restart mobile offline, and open a downloaded detail.
3. Sign out, sign in as another account, and verify old content is inaccessible;
   reconnect and confirm the second account's expected workspace/projects.

These private live journeys are not established by contract fixtures or a demo
Auth emulator. Existing Phase 1/2 production evidence gaps remain separately
documented. Physical-device, signed-release, large-data/performance, and internal
distribution gates remain Phase 6. iOS native/backup/device verification remains
Phase 7. Agent usage and tracker/validation UI remain Phases 4 and 5.
