# Phase 3 — projects and offline reading

Scope: read the existing v1 projects contract, display its complete metadata in
list/detail screens using the established soft-minimalist UI, and preserve a
complete fetched list across offline restarts. No cloud writes, agent/tracker
features, API-key changes, deployment, or distribution.

## Ordered implementation

1. Typed project records and root-page traversal. Decode canonical fixtures,
   validate metadata/IDs/timestamps, follow opaque cursors, reject cyclic or
   incomplete responses, and stage all pages before replacing saved content.
   Verify decoder/repository tests before UI wiring.
2. Private SQLite scope cache. Store only allowlisted metadata. Revoke old
   account/workspace leases synchronously; serialize writes and clear previous
   scopes on sign-out, UID/workspace changes, and explicit authorization denial.
   Verify disk reopen, atomic replacement, corruption, and obsolete writes.
3. Cached workspace recovery and session composition. Offline restart can discover
   the last successfully fetched workspace for the restored Firebase user. Sign-out
   clears cache before completing; identity gates own a nested navigation stack.
   Verify cancellation, identity switches, missing workspace, and failed cleanup.
4. Projects list/detail. Browse from the connected workspace, refresh/resume without
   polling, preserve complete cached results on temporary errors, show desktop
   observation/cloud publication/mobile download times separately, and handle
   loading/empty/no-download/error/retry states. Detail uses the already-fetched
   project record; Phase 3 has no extra detail endpoint or child-snapshot reads.
5. Verification/documentation. Run full tests/analyzer/build and synthetic native
   journeys for pagination, updates/deletion, offline process restart and isolation.
   Record verified evidence separately from private production/device acceptance.

## Decisions and risks

- Root lists do not provide a global snapshot token. Completion is atomic in the
  local cache, not a claim of a point-in-time workspace view. Each project retains
  its own snapshot ID for later tracker integration.
- SQLite adds a native dependency but supplies transactional replacement rather
  than relying on preferences or multi-file rename semantics. Tests use an injected
  database factory; no new state-management/router package is needed.
- Offline metadata is private app storage, not credential storage. Firebase owns
  its session. Cache cleanup and route disposal must prevent old results from
  becoming visible or writable after account/workspace changes.
- Refreshing the complete root list applies updates and removes deleted projects;
  a failed/partial traversal must never erase a previous complete list.

The user explicitly authorized Phase 3 on 2026-10-16. Existing production/release
acceptance checkpoints remain documented rather than inferred from local tests.
