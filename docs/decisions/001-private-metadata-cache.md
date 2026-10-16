# ADR-001: Use a single-owner transactional metadata cache

## Status and date

Accepted for Phase 3, 2026-10-16.

## Context

Project metadata must survive an offline process restart without exposing a prior
account or workspace. A paginated refresh can fail after some pages arrive. The
existing Worker root list has no workspace-wide snapshot token; each project
record carries its own publication anchor. Firebase already owns native session
persistence and must remain separate from metadata storage.

## Decision

Use `sqflite` in private application storage, with versioned JSON documents per
workspace and record scope. A single owner row binds the database to a Firebase
UID and selected workspace. Keep one account's scopes, not a collection of
switchable offline profiles. Save only typed, allowlisted metadata and mobile
fetch timestamps. Never store tokens, passwords, paths, values, or publisher keys.

The shared cache owns SQLite transactions and account/workspace lease revocation;
features own document versions, decoding, repositories, and UI. Project fetching
stages all pages before a single transactional replacement. A failed traversal
preserves the old complete document; a successful empty result removes old
projects. This is local atomicity, not a claim of a point-in-time cloud snapshot.

Sign-out hides the navigation tree, revokes leases immediately, and awaits cache
cleanup before SDK sign-out completes. Account changes gate the new UI until old
scopes are deleted. Workspace changes discard nested routes and revoke leases
before replacement. Obsolete reads/writes cannot cross these generations. A
failed storage operation shows recovery, not a successful sign-out or a revived
old workspace lease. Startup without an SDK session clears residual metadata.

## Alternatives

- Preferences: already suitable for small settings, but not transactional scope
  replacement and growing structured metadata.
- Ad hoc JSON files: fewer dependencies, but require custom crash-safe replacement,
  cleanup, and concurrent-write semantics.
- Per-account retained databases: convenient switching, but contradicts the
  roadmap's requirement to clear prior data on identity/workspace changes.
- An ORM or new state/router package: unnecessary for two tables and the existing
  feature-controller architecture.

## Consequences and limits

- Adds native SQLite plugins; FFI is a development-only test dependency. The app
  still targets Android first, not web/desktop SQLite implementations.
- Documents make replacement simple. Very large scopes incur full decode/encode
  and in-memory staging; measure realistic scale and release performance in Phase 6.
- The project list uses lazy widgets. Project detail is included in the downloaded
  record and therefore does not require opening each project while online.
- Temporary connectivity failures retain saved content and its original download
  time. Explicit authorization denial removes access and clears its scope.
- SQLite is not an encrypted credential vault. OS app isolation and Android
  `allowBackup=false` limit normal access/cloud backup; `secure_delete` helps
  cleanup but is not a forensic-erasure promise. Android manufacturer-specific
  device transfers need explicit exclusion/verification before Phase 6 release.
  A rooted device is outside this guarantee.
- If disk cleanup cannot complete, access under a changed UID/workspace fails
  closed and offers retry. A failed sign-out remains an active session and is
  reported as a failure, not falsely treated as logged out. No filesystem design
  can guarantee a durable deletion while writes fail; startup rechecks the
  Firebase UID before exposing any saved content.
- iOS backup exclusion, native storage behavior, and device acceptance must be
  checked in Phase 7 before distribution.

## Sources

- [Flutter SQLite persistence](https://docs.flutter.dev/cookbook/persistence/sqlite).
- [sqflite platform support and usage](https://pub.dev/packages/sqflite).
- [Transaction commit/rollback semantics](https://pub.dev/documentation/sqflite/latest/sqflite/Database/transaction.html).
- [SQLite secure-delete behavior and limits](https://www.sqlite.org/pragma.html#pragma_secure_delete).
- [Android backup and device-transfer caveats](https://developer.android.com/identity/data/autobackup#EnablingAutoBackup).
- Canonical producer contract: `../devventory/docs/mobile-read-api-v1.md` and
  `../devventory/cloud/contracts/read-v1.schema.json`.
