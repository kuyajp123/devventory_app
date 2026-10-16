# Dashboard and navigation UI interlude

## Scope

Keep the existing navy/sky-blue Soft Minimalism, bundled Inter, Venty, and tactile
primary action. Signed-out and verification recovery remain unchanged. A linked
signed-in workspace opens Home directly, without a connection-screen detour.
Missing workspace/access failures retain the existing recovery screen.

1. Reuse the complete project download, account/workspace leases, and SQLite cache.
2. Add a right-side, partial-width project drawer with search and selection. Keep
   the current screen visible under its scrim; close with selection, close button,
   outside tap, system Back, or Escape. Allow wider content at large text sizes.
3. Add Home (default), Usage, Tracker, and Account bottom destinations. Usage and
   Tracker are explicit future-feature states, not mock analytics.
4. Render real project totals and type composition with `fl_chart`. Selecting a
   project shows its summary and a details action; workspace charts remain clearly
   labeled workspace-wide. Do not imply local file metrics or activity history are
   available in the v1 metadata feed.
5. Preserve refresh/resume/backoff, offline freshness, deletion, sign-out cleanup,
   identity/workspace revocation, and unpublished-workspace recovery.
6. Verify shell behavior, chart values, narrow/large-text layout, focus/dismissal,
   accessibility, existing journeys, analyzer, and Android compilation. Update docs.

No backend changes, new cache schema, production calls, Phase 4/5 implementation,
deployment, commits, or pushes are part of this interlude.
