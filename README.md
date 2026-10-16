# Devventory Mobile

Flutter companion for Devventory desktop. The intended release reads projects,
agent usage, Environment Tracker, and validation metadata through the existing
Firebase-authenticated Cloudflare Worker, with cached offline reads. Android
launches first, followed by iOS.

Phase 2 replaces the starter with Firebase sign-in, session restoration,
email-verification recovery, password reset, sign-out, and workspace discovery.
Phase 3 adds project list/detail browsing, complete paginated refreshes, freshness
labels, and private account/workspace-scoped SQLite caching for offline restarts.
Account creation and workspace setup remain on desktop.

Linked users now land on the Home dashboard, with project analytics rendered by
`fl_chart`, a partial-width right-side project selector, and Home/Usage/Tracker/Account
bottom tabs. Usage and Tracker clearly mark their future implementation status.
See the [dashboard/navigation UI interlude](docs/dashboard-navigation.md).

- [Master implementation plan](tasks/plan.md)
- [Implementation checklist](tasks/todo.md)
- [Phase 1 evidence and remaining gate](docs/phase-1-verification.md)
- [Application identities and setup](docs/mobile-setup.md)
- [Phase 2 implementation and acceptance](docs/phase-2-verification.md)
- [Phase 3 projects, offline behavior, and acceptance](docs/phase-3-verification.md)
- [Visual system, tactile actions, and Venty mascot](docs/visual-design.md)

## Run on Android

```powershell
flutter pub get
flutter run --flavor development -d emulator-5554
```

Select your device from `flutter devices`. Development and production are separate
Android application IDs and Firebase registrations in the existing `devventory`
identity project. Both read the production Worker; use synthetic desktop data for
testing. No service-account or publisher credentials are needed.

Native iOS registration/build validation is deferred to macOS in Phase 7. Web and
desktop targets are not configured mobile release targets.

## Local verification

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test test lib
```

When the desktop repository is checked out beside this one, also run:

```powershell
dart run tool/check_contract_sync.dart ../devventory
```

Desktop owns the canonical v1 read schema and fixtures under `cloud/contracts`.
This repository pins synthetic fixtures under `test/contracts/fixtures` so its
tests run independently. Contract examples are not production credentials or a
replacement for real-account/device acceptance.

Feature-owned unit tests are colocated under `lib/features/*/tests` and
`lib/shared/*/tests`; use the full command above, not just `flutter test`.
Cross-feature widget journeys live under `test` and native SDK journeys under
`integration_test`. See the setup guide for the test-only Auth emulator workflow.
