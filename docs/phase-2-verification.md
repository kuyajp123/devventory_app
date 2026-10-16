# Phase 2 — foundation and authentication

## Delivered scope

Flutter's starter has been replaced by a dark Material 3 companion shell with
email/password sign-in, native SDK session restoration, email-verification recovery,
password reset, sign-out, and authenticated workspace discovery. Only Android is
registered/configured now. No account creation, publishing, project browser,
persistent metadata cache, or notifications are included in this phase.

`lib/app` composes dependencies and lifecycle behavior. The `auth` and `workspace`
features own their models, repositories, controllers, presentation, and unit tests,
exporting public entry points. `lib/shared` contains only the network/token boundary
and UI elements consumed by both features. Package imports preserve explicit
boundaries. Built-in `ChangeNotifier`/`ListenableBuilder` controllers are sufficient
for these two small flows; no extra state/router framework is introduced yet.

## Identity, trust boundaries, and lifecycle

- FlutterFire uses the existing Firebase identity project, with separate Android
  development/production registrations. The native SDK persists credentials;
  application models contain only UID, email, and verification status. Passwords
  remain transient in form fields and are cleared after submission/disposal.
- Mobile sends a fresh SDK-provided ID token only to the configured HTTPS Worker.
  There are no cloud mutation methods, publisher/device tokens, workspace-ID build
  flags, or Firebase application databases in this client.
- The network boundary rejects absolute/non-v1 paths and redirects. A 401 gets one
  forced-refresh retry, then reauthentication guidance. 403 verification is distinct
  from permissions; 429 gets a per-account cooldown, not a retry loop; unavailable
  service/network/unsupported response states are recoverable without losing the
  SDK session. Backend messages/headers/tokens are not logged or shown verbatim.
- Verification reloads the current User then forces a new verified ID token before
  leaving recovery. Local resend throttling complements Firebase limits. Reset
  feedback does not reveal whether an address exists.
- Every request checks UID before sending and before returning. Sign-out and UID
  changes dispose/cancel workspace requests. Late session reloads cannot restore
  old accounts, and locally rejected sessions remain gated against cached events.
- Refresh occurs on resume or explicit user request. There is no continuous network
  polling. The displayed connection-check time is mobile fetch time, not desktop
  observation time or evidence that any metadata snapshot was uploaded.
- No workspace is automatically created or replaced. Missing workspace or publisher
  states direct the user to desktop Cloud Sync. A ready connection does not imply
  published projects exist. Phase 3 will distinguish empty project data and cache it.

## Verification

Unit/widget checks cover canonical workspace fixtures; protocol/identity rejection;
native flavor/config matching; auth restoration, verification, reset and sign-out;
obsolete async results; request authorization, one-time retry, redirect rejection,
identity isolation, rate-limit backoff; workspace cancellation; recovery states;
and narrow-screen/large-text layout.

Native SDK probes use only `demo-devventory-mobile` and the local Auth emulator.
Their workspace is synthetic/in-memory: they are not production Worker acceptance.
See `mobile-setup.md` for repeatable commands.

### Automated results, 2026-10-15

- `flutter test test lib --no-pub`: 32 passed, 0 failed.
- `flutter analyze --no-pub`: no issues.
- Dart formatting and producer/mobile fixture comparison: pass.
- Development debug APK: built successfully.
- Production-flavor debug APK: built successfully with its distinct native
  application ID and matching Firebase options. This is not release signing.
- Normal development application (`lib/main.dart`, not the test entry point):
  initialized Firebase and displayed the signed-out screen on Android 17/API 37.
  The screenshot was visually checked; no overflow or Flutter exception appeared.
  Local capture: `build/phase2-signin.png` (ignored build artifact).
- `tool/test_auth_journey.ps1 -Device emulator-5554`: all three native probes pass
  on Android 17/API 37. The first signs in through the real SDK, sends/applies an
  emulator verification action, refreshes verified claims, discovers a synthetic
  workspace, and requests a reset email. The second restores the verified session
  in a new process without another password, then signs out. The third starts a
  new process and confirms sign-out persisted and no workspace was requested.

### Native compatibility observation

The first native probe on `Pixel_6a`, Android 15/API 35, 16 KB x86_64 image
`AE3A.240806.043/12960925` (security patch 2024-09-05) crashed in the Android
runtime during Firebase background/DataStore startup, before the test could
complete: `SIGSEGV` followed by ART's `copied_methods_start <= methods->size()`
assertion. No speculative dependency downgrade or app workaround was applied.
The same native authentication flow passes on `Pixel_9_Pro`, Android 17/API 37,
16 KB x86_64 image `CP41.260831.007/16416850`. This narrows the failure to an
image/runtime compatibility combination but does not prove Android 15 physical
devices are unaffected. Recheck on a patched Android 15 image/device and cover
the supported Android range before release; the old-image failure is not marked
resolved or silently skipped.

A bounded follow-up with a full cold boot (no snapshot load/save) and the normal
production-flavor debug APK did not establish a healthy Android 15 run: activity
launch timed out and the emulator displayed **System UI isn't responding**.
Other system-process crashes were also visible. This confirms that this old AVD
is not a reliable acceptance environment; it does not establish the app's behavior
on a healthy/patched Android 15 device. Capture: `build/phase2-api35.png`.

Flutter 3.47's integration runner also uninstalls test APKs by default. The first
restart experiment correctly found no session after that uninstall. The checked-in
script now uses `--no-uninstall` to preserve native storage across process restarts.
That harness correction is separate from authentication persistence behavior.

Build warnings about FlutterFire plugins using Kotlin Gradle Plugin and mismatched
SDK XML tooling were observed. The pinned current toolchain builds successfully;
reevaluate the upstream plugin warning before a future Flutter upgrade.

## Remaining acceptance / release boundaries

An existing desktop user must privately sign in on the Android build, reach the
expected production workspace, fully restart and confirm restoration, then sign
out and verify a different account's connection/setup state. Do not send credentials
or tokens in chat. Physical-device, signed-release and store acceptance remain
Phase 6. iOS registration, schemes, native validation and distribution remain
Phase 7 on macOS. Debug release signing is deliberately not a production signature.
