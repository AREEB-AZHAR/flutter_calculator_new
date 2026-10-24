# Background sync — 25 October 2026

Tally 1.8.22+32 now requests automatic synchronization after login instead of
asking whenever both the local and cloud vault contain records. Manual sync
remains available from Profile → Settings → Cloud Sync. Explicit account-link
migration choices also remain available.

## Conflict policy

Transactions and goals are compared by normalized content, including goal
entries, rather than aggregate balances, record counts or server timestamps.
The owner approved an additive local SQLite table, `ledger_sync_baselines`,
which stores the last acknowledged SHA-256 fingerprint by username,
collection and record ID. It is installed idempotently at database open;
existing records, app/database version, Firestore document formats and rules
are unchanged. Local account deletion also removes its checkpoints.

- Identical copies, independent additions, cloud-only changes and queued edits
  against an unchanged cloud checkpoint merge quietly.
- Different edits to the same record, including edit/delete disagreements,
  pause automatic sync and preserve the queued local version.
- A legacy same-ID mismatch without a known common version needs review once;
  inventing a common ancestor would risk losing data.
- A no-op local save cannot replace a newer cloud version.
- Login can show one unresolved-conflict dialog. Conflicts found later are
  indicated in Settings, without interrupting ordinary editing.
- The existing manual cloud restore, local overwrite and explicit merge
  remain deliberate user choices. They are not selected automatically.

## Scheduling and durability

`BackgroundSyncCoordinator` coalesces changes into a two-second window, allows
one active operation and retains a follow-up request for edits made during an
upload. Failures retry with exponential backoff from five seconds to five
minutes. Reconnect and foreground resume wake the queue. A foreground poll
every 15 minutes discovers cloud-only changes. This still reads the complete
ledger; it is not an incremental cloud listener and can incur read charges.

SQLite owns the durable outbox. Timers are only scheduling hints. Account,
budget and profile writes enqueue metadata in the same local transaction as
their saved data. Revisions prevent an old upload from acknowledging a newer
local edit. Account/budget empty values survive reload rather than restoring
defaults. Metadata retains its existing local-dirty/cloud-merge preference
policy; the record-level conflict detector applies to transactions and goals,
not simultaneous profile/preference edits across devices.

Ledger uploads retain the 400-document / 4 MiB chunk limits. Each cloud chunk
uses a Firestore transaction to compare the preflight versions before writing;
a changed cloud version fails without acknowledging the local chunk. A full
multi-chunk sync is resumable, not globally atomic. Metadata uploads use one
small write batch at the existing paths. See Firebase's
[transaction rules](https://firebase.google.com/docs/firestore/manage-data/transactions).

Workers check Firebase UID, active username and login generation. Logout and
account changes invalidate old work. Lifecycle ownership prevents disposal of
an old navigation screen from stopping the new screen's worker. In-flight
network requests may finish, but stale sessions cannot import their results
into the newly active account.

"Background" means quietly while the application is foregrounded. Timers stop
while it is backgrounded. Android terminated-app execution is not implemented;
queued changes resume when the authenticated app opens again. Local password
accounts without matching Firebase authentication remain local.

## Verification

Use the existing Flutter 3.41.3 / Dart 3.11.1 setup documented in the README.
No new dependency, Firebase deployment, APK build or version bump is required.

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Regression fixtures:

- `test/background_sync_coordinator_test.dart`: burst coalescing, offline wake,
  retry/backoff, pause/resume, serialization and account replacement.
- `test/background_sync_conflicts_test.dart`: quiet merges, true conflicts,
  tombstones, restart checkpoints, no-op saves, failed uploads, concurrent
  local edits, 1,001-record chunking, metadata rollback/coalescing/isolation,
  empty budgets, account cleanup and idempotent schema installation.
- `test/background_sync_dialog_test.dart`: unresolved versions are explained
  even when summary totals match.
- Existing ledger, atomic recurring, manual modal and navigation tests remain
  part of the full suite.

Raw final outputs are in `docs/audit-evidence/background-sync-analysis.txt`
and `background-sync-full-tests.txt`: **282 tests passed; analysis is clean**.
These are SQLite/fake-remote and widget
tests. Live Firestore transaction contention, device login, offline/reconnect
and actual Settings resolution still require a signed-in device check; no
production vault was modified during this task.
