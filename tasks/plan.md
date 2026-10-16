# Devventory Mobile — Master Implementation Plan

## Goal

Build a read companion for existing Devventory desktop users: projects, agent
accounts/quotas, Environment Tracker, and validation results. Release Android
first, then iOS. Preserve successfully fetched data for offline reads with clear
freshness. Account creation and workspace/publisher setup stay on desktop.

## Architecture

Desktop SQLite is the source of truth. Desktop publishes metadata snapshots to
Cloudflare Worker/D1. Flutter authenticates with the same Firebase identity project
and reads only the Worker GET endpoints. Firebase is not an application database.
Mobile never receives publisher credentials or sends publishing requests.

Use `lib/app` for composition, `lib/features` for product capabilities, and
`lib/shared` for true infrastructure. Features own their UI, models, state,
repositories, helpers, and tests, with public entry points. Widgets delegate data
access. Cache records by Firebase UID/workspace; clear them on sign-out or identity/
workspace change. Paths, file contents, environment values, secrets, Vault data,
and assets are outside the cloud/mobile allowlist.

## Phases and gates

| Phase                                    | Deliverables                                                                                                                                                                                        | Gate                                                                                                                                          |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Integration readiness and contract    | Confirm desktop/live Worker state, complete production acceptance, establish application identities/configuration, document the v1 read API, export a schema, and add producer/consumer fixtures.   | Fresh authenticated publication, offline desktop restart/reconnect, and real second-account isolation pass; contract and fixture checks pass. |
| 2. Flutter foundation and authentication | Feature structure, app shell/navigation, shared network boundary, FlutterFire configuration, sign-in/session restoration, verification recovery, password reset, sign-out, and workspace discovery. | Existing desktop user reaches their workspace; missing/unverified/rejected sessions recover clearly.                                          |
| 3. Projects and offline reading          | Project list/detail with typed repositories, persistent account-scoped cache, pagination, refresh, freshness, and loading/empty/error states.                                                       | Published changes refresh correctly; fetched data survives offline restart; account changes cannot expose prior cached data.                  |
| 4. Agent usage                           | Accounts, quota details, percentages, reset timing, tracking/staleness indicators, on-demand loading, and canonical desktop parity.                                                                 | Shared fixture cases pass, including threshold/reset/timezone boundaries and account precedence; offline usage reads work.                    |
| 5. Tracker and validation                | Environments, sources, keys, cells, occurrences, rules/targets, issues, and validation health using summaries/drill-down.                                                                           | All published kinds are reachable; pinned reads/cache replacement stay consistent; unfetched and empty/offline details are distinguishable.   |
| 6. Android verification and release      | Cross-system journeys, accessibility, large-data behavior, lifecycle refresh, safe diagnostics, CI, release signing/network configuration, setup docs, and internal-test build.                     | Automated/device checks pass; signed Android distribution build reads production; internal acceptance precedes production release.            |
| 7. iOS verification and release          | macOS Firebase/signing configuration, iOS device checks, TestFlight, and platform corrections.                                                                                                      | All authentication/data/offline/isolation journeys pass on signed iOS distribution builds.                                                    |

Phases are sequential. Contract-only artifacts and fixture checks are Phase 1
work; application wiring begins only after its production acceptance gate.
Each later feature phase includes its own UI, repositories, cache, and tests.
Deployments and distribution are explicit release steps.

On 2026-10-15 the user accepted the tested desktop account workflow, confirmed
main was merged, and authorized Phase 2. The user-reported acceptance and the
remaining independently unverified production rollout evidence are distinguished
in `docs/phase-1-verification.md`; a merge is not treated as a deployment.

## Interface and verification requirements

- Desktop owns the read schema and canonical fixtures. Keep protocol v1 and
  publisher behavior compatible; coordinate schema/fixture/consumer updates.
- Follow cursors, pin child reads to the root record's snapshot across all pages/
  kinds, bound expired-snapshot restarts, and publish caches only after a complete
  successful scope fetch. Root lists have no workspace-wide snapshot guarantee.
- Centralize tokens, machine-readable errors, bounded refresh/retry, rate-limit
  backoff, and cancellation on identity changes.
- Display desktop observation, cloud publication, mobile fetch, and quota usage
  staleness separately. Refresh on resume/request instead of continuous polling.
- Verify decoding, quota parity, cache replacement, isolation, cancellation,
  failures, deletion, and pagination; use widget tests and device user journeys.

## Defaults

Sign-in, email-verification recovery, password reset, and sign-out are mobile
capabilities. Sign-up, metadata editing, publishing, device registration, desktop
validation execution, notifications, and background reminder scheduling are
deferred. Cache successfully fetched scopes; unopened details can need a
connection. Report actual verification evidence at each phase gate.
