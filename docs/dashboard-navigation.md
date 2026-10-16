# Dashboard and navigation UI interlude

## Behavior

An existing verified user with a linked workspace lands directly on Home. Signed-out
users still see sign-in; unverified users retain verification recovery. Discovery,
unpublished-workspace, and access-denial recovery still precede data access.

Home displays workspace project totals and a real project-type composition chart.
The upper-right folder control opens a right-side drawer, leaving the current screen
visible under a light scrim. The drawer uses 62% width, capped at 420dp; large text
uses 78% for readability. It provides search, an All projects option, selected-state
indicators, and a lazy project list. Selection closes the drawer and returns to Home
with a selected-project summary and a details action. Workspace charts remain
explicitly workspace-wide. Close, outside tap, Back, and Escape dismiss the drawer.

Home is the default bottom destination. Usage and Tracker are honest coming-later
states for the planned phases, not simulated measurements. Account retains workspace
connection information, recovery, refresh, and sign-out. Back returns from details or
another tab to Home; it closes an open drawer first.

## Data and ownership

- App composition owns tabs and selection in `lib/app/companion_home.dart`.
- Dashboard analytics and chart presentation belong to `lib/features/dashboard`.
- Project selection belongs to `lib/features/projects`; app/dashboard imports use
  the feature's public entry point. Existing standalone project views remain usable.
- There is one project controller per UID/workspace shell. Choosing a project or tab
  does not perform a second project download. Refresh/resume uses existing preflight,
  pagination, authorization, backoff, and atomic cache replacement.
- Selection is session-only. Replacing the account/workspace tree removes the drawer,
  selection, chart data, and details. Sign-out still clears metadata before SDK logout.
- Unknown project data displays an unavailable marker, never zero. Successfully empty
  data has its own chart explanation. Offline/error/freshness notices reuse Phase 3.
- No new API endpoints, publication behavior, snapshot assumptions, or cache schema.

Desktop dashboard models were checked before choosing metrics. Its indexed files,
assets, and scan history are not synced to mobile. Environment coverage and validation
analytics require the later tracker phase, and agent quotas require Phase 4. The new
chart therefore summarizes the current published project records, not activity over
time, usage history, or local file inventory. This is not desktop dashboard parity.

## Design and accessibility

The frontend/UI-UX skills guided visible selection, semantic controls, accessible
chart text equivalents, recovery, and input completeness. The Design Motion
**Charts That Lie** reference informed truthful scope and proportional composition;
its catalog-only Tabs/Modal entries were considered but no detailed rules were
inferred from them. Navy/sky-blue tokens, bundled Inter, 28dp cards, Venty, and tactile
primary buttons are retained. The screenshot references informed the partial-screen
drawer and compact rounded bottom bar, not a branding change or a decorative 3D tilt.

The chart is decorative to assistive technology; the adjacent visible legend gives
every category, count, and percentage. Controls have labeled targets, the drawer
uses Flutter's focus/local-history behavior, and chart animation is disabled when
reduced motion is requested. Standard drawer motion follows framework accessibility
animation behavior. Long titles wrap in the drawer; 2x text gets more drawer space.

Implementation references:
[fl_chart package and license](https://pub.dev/packages/fl_chart),
[PieChart API](https://pub.dev/documentation/fl_chart/latest/fl_chart/PieChart-class.html),
[Flutter end drawer](https://api.flutter.dev/flutter/material/Scaffold/endDrawer.html),
and [NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar-class.html).
The package addition resolves to fl_chart 1.2.0 and equatable 2.1.0; unrelated pinned
runtime packages are unchanged.

## Verification

On 2026-10-16:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub test lib --reporter expanded`: **104 passed**.
- Dart formatting: 77 files checked, none changed.
- `flutter build apk --debug --flavor development --no-pub`: passed. The normal
  development entry point, not the test harness, is packaged in
  `build/app/outputs/flutter-apk/app-development-debug.apk`. Existing Java native
  access and FlutterFire/Kotlin Gradle warnings remain unchanged.
- New tests cover default Home, partial/right drawer geometry, search, selected
  state, tab retention, closing by Escape/outside tap/Back, Back-to-Home, account
  changes with an open drawer, failed sign-out recovery, and no-download vs empty.
- Responsive/accessibility checks cover 320dp with 2x text and a 280dp keyboard,
  plus 768/1024/1440dp. Target sizes, labels, contrast, long names, and truthful
  seven-category chart values/reduced motion are covered.
- The native synthetic journey passed on Pixel 9 Pro / API 37: native SQLite,
  rendered Home/chart/drawer, search, selection/detail, offline refresh preserving
  cached content, tabs, and sign-out. It uses a fake local identity and synthetic
  repository, not production Firebase or Worker calls.
- The native journey was repeated after the contrast/recovery fixes; it passed
  again. Home and the partially open drawer were visually inspected from Android
  captures. Optional captures are generated locally under `build/home-preview.png`
  and `build/drawer-preview.png`, not versioned assets.
- Producer/consumer fixture parity, repository whitespace, and Markdown formatting
  checks passed. The existing desktop checkout's installed Prettier was reused;
  no formatter dependency was added to the mobile project.

To reproduce the native UI probe without production accounts:

```powershell
flutter test integration_test/home_shell_journey_test.dart --flavor development -d emulator-5556 --no-pub --no-uninstall
```

Use an Android emulator ID from `flutter devices`. Add
`--dart-define=VISUAL_PREVIEW=true` for short Home/drawer capture pauses. The test's
metadata database is native in-memory SQLite; it does not erase the app's normal
saved metadata or access a real Firebase session.

Two regressions were proven before correction: system Back was not reaching the
drawer through the old now-unnecessary nested navigator, and failed sign-out
feedback was hidden by the new Home-first entry. The shell now uses one navigation
route, with account/workspace-keyed presentation state and visible Home recovery.
The Android visual pass also caught and corrected the selector icon's contrast.

The prior authentication/project integration scripts were adapted to the new entry
and details actions; their three-process SDK journeys were **not rerun** for this UI
interlude. The existing private production acceptance and Android/iOS release gates
remain unchanged. This verification does not establish production account acceptance,
physical-device compatibility, release signing, or distribution readiness.
