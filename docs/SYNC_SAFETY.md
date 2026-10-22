# Sync and recurring transaction safety

Implemented 23 October 2026 in **1.8.17+27**, following audit findings F1, F2 and F5. This document describes the implemented scope; the original audit remains a historical baseline.

## What changed

| Area | Current behavior |
| --- | --- |
| Ordinary sync / Mix Data | Upload explicit local mutations, retain remote-only records, then import remote records. Local absence never means cloud deletion. |
| Large ledgers | Every record is processed. Writes are chunked at at most 400 documents and approximately 4 MiB of encoded payload, with a conservative per-document check. |
| Offline mutations | SQLite triggers persist a coalescing transaction/goal outbox in the same transaction as the local write. No Firebase connection is needed to retain a deletion. |
| Deletion / Undo | Deletes write durable remote tombstones. An unedited stale device honors them; an explicit undo is a new upsert. Archived goals remain archived records rather than being deleted. |
| Interrupted upload | Each acknowledged chunk removes only the revisions it actually sent. Failure retains unsent mutations; reopening the database and syncing retries them. |
| Concurrent local edit | An edit during upload gets a new revision. Acknowledgment of the older revision cannot remove it, and import skips pending records. The UI reports pending work rather than full completion. |
| Account switch | Sync captures username, Firebase UID and session generation, checks them at asynchronous boundaries and before commits/imports, and aborts mismatched work. Imported global-ID collisions with another local user are rejected. |
| Explicit Upload Fresh Data | The user's overwrite choice remains destructive by design. Only this path marks cloud-only records deleted. It uses the same bounded writer. |
| Explicit Load Saved Data | Applies the chosen cloud ledger locally in a SQLite transaction, clears only superseded outbox revisions and avoids echo uploads. Edits made after the restore snapshot stay pending. |
| Automatic / Post Now | One SQLite transaction inserts the occurrence, marks its plan processed, creates its successor, and generates the outbox entry. Manual posting uses the same writer and waits before showing success. |

The Firestore adapter reads from the server for ledger reconciliation. A failed server read reports incomplete sync instead of interpreting an offline cache as an authoritative backup.

## Conflict and compatibility policy

- For records with the same ID, a pending explicit local edit uses **last successful commit wins**. An unedited legacy local copy defers to the remote version. This is not field-level conflict merging or a distributed revision history.
- A retry after an uncertain commit is idempotent for the ledger entry/ID. If another device changes the same ID before that retry, the last-commit rule still applies; no automatic conflict UI has been added.
- Tombstones are retained. There is no automatic tombstone garbage collection; removing them without device-acknowledgment tracking could resurrect stale records.
- Upgrade every device to this version before using the new sync format. Older builds do not understand tombstones and still contain the destructive sync implementation. Mixed-version sync is not safe.
- The durable outbox covers **transactions and savings goals**, including goal contribution payloads. Accounts/budget/profile metadata retain their own merge/update behavior; loans and planned schedules have not gained a new cloud replication protocol in this change. Generated financial occurrences do enter the transaction outbox.
- A full overwrite spanning multiple Firestore chunks is not globally atomic. If interrupted, it reports failure and can be rerun; completed chunks remain committed. Ordinary incremental chunks are checkpointed individually.
- This fixes correctness and write truncation, not large-ledger read performance: sync still reads complete transaction/goal collections. Pagination, aggregate summaries and server-side same-record conflict arbitration remain future work.

## Recurring rules

1. Plans are day-based: a plan dated today is due, including one with a later time today. Future days remain pending unless the user chooses Post Now.
2. The occurrence uses the original plan ID. The successor has a deterministic SHA-256-derived ID, so retries/concurrent calls cannot create duplicate successors.
3. Daily/weekly successors preserve calendar time. Monthly/yearly successors clamp to the last valid day while retaining the original day/month anchor: January 31 → February 28/29 → March 31; leap-day yearly plans return to February 29 in the next leap year.
4. Automatic processing catches up at most 1,000 occurrences per pass. Remaining backlog stays pending for the next pass. Invalid recurrence values fail and roll back the occurrence.
5. UI notifiers and reminder scheduling run after commit and only for the captured active session. Notification failure cannot prevent ledger persistence. Scheduling is best effort and can be retried from the persisted pending schedules; it is not an exactly-once notification protocol.
6. Automatic login-time processing queues cloud work without uploading before the user's cloud/local conflict choice. Manual posting requests a sync after commit; otherwise pending work drains on the next ordinary sync.

## Schema and architecture

The database version is now **2**. The additive upgrade retains existing records and adds `ledger_outbox`, `ledger_import_guard`, transaction/goal mutation triggers, and recurrence anchor columns. The import guard suppresses outgoing echo mutations inside the same SQLite transaction. A shared initialization future prevents concurrent callers from opening the app database twice.

| File | Responsibility |
| --- | --- |
| `lib/services/ledger_sync.dart` | Durable SQLite outbox, snapshots, guarded imports, chunking, merge/restore/overwrite algorithms |
| `lib/services/cloud_sync_service.dart` | Firebase identity checks, SDK adapter, progress/result notifications and metadata |
| `lib/services/atomic_plans.dart` | Atomic recurring/manual occurrence writer, bounded catch-up and calendar rules |
| `lib/services/database/app_database.dart` | Schema initialization, delta bulk saves and local persistence entry points |
| `lib/services/state.dart` | Session generations and UI publication after commit |
| `test/ledger_sync_and_atomic_plans_test.dart` | Real-SQLite regression tests with a controlled remote implementation |
| `test/flutter_test_config.dart` | Separate OS-temp database directory per test file, avoiding contention and personal-ledger access |

Before installing an experimental build over financial data, close the app and retain a backup of the database and any journal/WAL companions. An older build cannot simply open a database whose version it does not support. Test migration/restore using a copy first.

## Reproduce validation locally

Use the README's Flutter 3.41.3 / Dart 3.11.1 setup, then run from the repository root:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub test/ledger_sync_and_atomic_plans_test.dart --reporter expanded
flutter test --no-pub --concurrency=1 --reporter expanded
flutter build apk --debug --no-pub
```

The regression suite covers 0/1/400/401/1,000/100,000 transactions, exact record/value reconciliation, bounded payloads, remote-only goals and contributions, two persisted device databases, tombstones/undo, partial failures/reopen, uncertain commits, account mismatch/import rollback, schema migration, recurring concurrency/retry, write-failure rollback at all three persistence stages, catch-up, leap years and month ends.

Tests use a controlled remote, not production Firebase or a live Firestore emulator. Native Firebase authentication, deployed rules, network/plugin behavior and physical-device notification delivery still need integration smoke validation. The old partner-banner test expected the obsolete plain `Ad` label; it now checks the actual `Ad • Partner` fallback and its removal, without changing ad runtime behavior. Tests allocate unique OS-temp directories; some Windows native handles live until test-isolate exit, so fixture deletion is deferred rather than racing callbacks.

Results are recorded in [the complete suite log](audit-evidence/sync-implementation-full-tests.txt), [targeted regression log](audit-evidence/sync-regression-tests.txt), [analysis log](audit-evidence/sync-implementation-analyze.txt) and [Android build log](audit-evidence/sync-android-build.txt).

Final local verification on 23 October 2026:

| Check | Result |
| --- | --- |
| Complete suite on final code, serial | **198 passed**, exit 0, reported execution 4m 40s |
| Targeted sync/recurring plus existing feature tests | **42 passed**, exit 0 |
| Static analysis | **No issues found**, exit 0 |
| Final incremental Android debug build | **Built successfully**, exit 0, Gradle 178.3s |
| Diff whitespace validation | `git diff --check` passed |

APK: `build/app/outputs/flutter-apk/app-debug.apk`. This is a debug validation artifact, not a production-signed store release. The final suite was repeated after review preserved the automatic notification after recurring commits and the existing cloud-avatar restoration behavior.

Implementation follows [Firestore's batch/transaction guidance](https://firebase.google.com/docs/firestore/manage-data/transactions) and [sqflite's transaction guidance](https://pub.dev/packages/sqflite): local atomicity uses only the transaction handle, and cloud work occurs after the local commit.
