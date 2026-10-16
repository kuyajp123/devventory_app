# Mobile identities and configuration

## Application identity

Keep the existing production IDs to avoid an unnecessary identity migration:

| Platform | Production ID                   | Development ID                      |
| -------- | ------------------------------- | ----------------------------------- |
| Android  | `com.devventory.devventory_app` | `com.devventory.devventory_app.dev` |
| iOS      | `com.devventory.devventoryApp`  | `com.devventory.devventoryApp.dev`  |

The release display name will be **Devventory Mobile**; development builds will
show **Devventory Mobile Dev**. Android launches first. Preserve iOS compatibility
and validate its build/signing on macOS in Phase 7. Generated desktop/web targets
are not mobile release targets.

Android flavors and both Firebase Android registrations were created in Phase 2.
iOS development identity is still reserved; create its schemes and registrations
on macOS in Phase 7. Do not rename registered IDs or reuse production native
storage for dev builds. Select an explicit Android flavor for every run/build.

## Public configuration

- Firebase project ID: `devventory` (existing identity project).
- Production Worker origin: `https://devventory-sync.devventory.workers.dev`.
- Mobile protocol: 1; all metadata requests are authenticated GET requests.
- Mobile does not configure workspace IDs, device IDs, publisher tokens, or a
  Firebase application database. Workspace identity comes from authenticated
  discovery, not a build flag.

The registered Android app IDs are:

- Development: `1:570074439211:android:bbf046d14854829c8d146e`.
- Production: `1:570074439211:android:3865ca027d3683268d146e`.

FlutterFire generated `lib/app/config/firebase_development.dart` and
`firebase_production.dart`, plus flavor-specific `google-services.json` under
`android/app/src`. These are public client configuration, not desktop options.
`AppConfiguration` selects options from Flutter's native `appFlavor`; unknown
flavors/platforms fail with a recoverable setup screen. No environment flag can
silently redirect production reads or select a workspace.

Generated Firebase client options contain public identifiers, not service-account
credentials. Passwords, refresh/ID tokens, device credentials, and release signing
keys must never enter build defines or tracked configuration. FlutterFire/Firebase
Auth handle native session persistence; keep credentials out of the metadata cache.
See the [official setup workflow](https://firebase.google.com/docs/flutter/setup).

The application uses the fixed production HTTPS Worker origin. Its shared client
only exposes GET requests to relative `/v1/` paths, attaches ID tokens per request,
rejects redirects, refreshes once after a 401, and respects rate-limit backoff.
Development also uses this production service: test accounts/workspaces must
contain synthetic data. Fixtures and Auth emulator tests need no live credentials.

## Run and regenerate configuration

```powershell
flutter run --flavor development -d emulator-5554
flutter build apk --debug --flavor development
flutter build apk --debug --flavor production
```

Only regenerate options after an intentional Firebase registration/config change.
Authenticate the Firebase CLI with an account authorized for `devventory`, install
`flutterfire_cli`, and run each flavor independently:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=devventory --platforms=android --android-package-name=com.devventory.devventory_app.dev --android-out=android/app/src/development/google-services.json --out=lib/app/config/firebase_development.dart
flutterfire configure --project=devventory --platforms=android --android-package-name=com.devventory.devventory_app --android-out=android/app/src/production/google-services.json --out=lib/app/config/firebase_production.dart
```

The Firebase project already supports desktop email/password accounts. Mobile does
not enable new providers or change console auth policies. Do not send login tokens
or CLI debug logs in chat. Firebase client API keys identify the public app; they
are not service-account keys or a substitute for Worker authorization.

## Native authentication checks without a production account

Start an Android emulator. In one terminal run:

```powershell
npx --yes --ignore-scripts --package=firebase-tools firebase emulators:start --only auth --project demo-devventory-mobile --config integration_test/firebase.json
```

In another terminal run:

```powershell
./tool/test_auth_journey.ps1 -Device emulator-5554
```

The script runs three separate app processes: synthetic sign-in/verification/reset,
restored session then sign-out, and persisted sign-out. It uses a named Firebase
app in the nonexistent `demo-devventory-mobile` project, a local Auth emulator,
and an in-memory workspace repository. It never sends emulator tokens to the live
Worker. The test creates only a synthetic emulator account. Restart the Auth
emulator between full runs to clear that synthetic account.

The script deliberately uses `--no-uninstall`: Flutter's integration-test runner
otherwise deletes the APK and its native session storage after each probe. Run
`flutter run --flavor development` afterward to replace the test entry point with
the normal application; the script leaves its test APK installed.

Debug Android network security permits HTTP only to loopback/Android's host alias
for the local emulator and development tools. Production/release uses HTTPS only.

## Phase 1 checks

```powershell
flutter analyze
flutter test test lib
dart run tool/check_contract_sync.dart ../devventory
```

Canonical contracts live in the desktop repository under `cloud/contracts`.
Pinned copies live in `test/contracts/fixtures`; do not modify their semantics in
mobile. The Dart checks establish portable decoding, not a completed feature
repository or a live Firebase integration.

The main-manifest Internet permission is present because authentication requires
it in Phase 2. Before release, Phase 6 must replace debug release signing, verify
network policy in the signed build, validate Android SDK licenses, and complete
physical-device and production-account acceptance. This is not a store-ready build.

## Implementation sources

- [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup).
- [Auth streams and native persistence](https://firebase.google.com/docs/auth/flutter/start).
- [Email verification and password reset](https://firebase.google.com/docs/auth/flutter/manage-users).
- [Flutter Android flavors](https://docs.flutter.dev/deployment/flavors).
- [Local Auth emulator](https://firebase.google.com/docs/emulator-suite/connect_auth).
- [Emulator action-code REST API](https://firebase.google.com/docs/reference/rest/auth#retrieve_out-of-band_authentication_codes).
- [Dio network options and cancellation](https://pub.dev/packages/dio).
