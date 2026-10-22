# Tally audit and optimization plan

**Date:** 23 October 2026 · **Source baseline:** `0ecfe21` · **App:** `1.8.16+26`

## Implementation status — 23 October 2026

The follow-up implementation in **1.8.17+27** addresses F1/F2 transaction/goal preservation and write truncation, and F5 recurring-write atomicity. See [SYNC_SAFETY.md](SYNC_SAFETY.md) for exact guarantees, tests, conflict/compatibility policy and remaining limitations. The findings below describe the original audit baseline; the rest of the roadmap remains pending.

## Decision

Fix ledger synchronization, recurring-write atomicity, account recovery, and purchase authority before investing in animation tuning. Then measure startup and large-ledger workloads on a physical Android device. Preserve the existing offline-first Flutter/SQLite architecture; a framework or state-management rewrite is not justified by this audit.

This deliverable is an audit and implementation plan. It does not change runtime behavior or claim that the findings have been fixed.

## Scope and evidence

Reviewed startup, navigation, global state, SQLite persistence, analytics, transactions, cloud synchronization, authentication/recovery, monetization, Android release settings, dependency manifests, and existing tests. Source references below describe the audited baseline.

- Installed SDK cache identifies Flutter **3.41.3**, Dart **3.11.1**. `pubspec.yaml` requires Dart `^3.11.1`.
- `flutter analyze --no-pub`: **passed, no issues**, 168.3 seconds.
- First complete `flutter test --no-pub --reporter expanded`: **166 passed, 5 failed**, exit 1, 90 seconds of reported test execution. A repeat capture is retained in [audit-evidence/flutter-test.txt](audit-evidence/flutter-test.txt).
- Captured repeat: **168 passed, 3 failed**, exit 1, 61 seconds. Two failures in `account_theme_isolation_test.dart` report SQLite error 5 (`database is locked`); `features_and_fixes_test.dart` expects an `Ad` label that is absent. The changing failure count means the baseline is not deterministic. See the serial diagnostic capture in [audit-evidence/targeted-tests.txt](audit-evidence/targeted-tests.txt).
- Serial diagnostic of those two files (`--concurrency=1`): **24 passed, 1 failed**, exit 1. Neither database-lock failure reproduced; the banner expectation at `test/features_and_fixes_test.dart:319` still fails. `AdBannerWidget` renders the label only after a native ad loads and skips native loading on unsupported host platforms. Add an injected fake ad loader and test loading/loaded/failure states explicitly. The serial result supports shared test-database contention as a cause of the lock failures; it does not prove all database concurrency paths are safe.
- Captured repeat's standalone 100k-record microbenchmark: insert **7,481 ms**, full query/deserialization **3,471 ms**, in-memory filter **30 ms**, and single insert **351 ms**. These are host test measurements under suite load, not phone latency or a stable benchmark. They do not substantiate the README's historical universal 12 ms write claim.
- `node --check functions/index.js`: passed. This validates JavaScript syntax only.
- No production Firebase access, real billing transaction, physical-device profile trace, app-store release, or rendered browser validation was performed. Cloud/backend exposure depends on what is actually deployed.
- No real app screenshots were found. Launcher icons are not screenshots. Capture instructions appear in the README; screenshots remain outstanding.
- Dependencies were reviewed from manifests; an advisory scan and upgrade compatibility matrix remain implementation work.

The Windows Flutter wrapper initially stalled under restricted SDK access. Running the installed Dart executable against `flutter_tools.snapshot` with SDK-cache access allowed analysis and tests to complete. This is an audit-environment detail, not an app startup defect.

## Findings ordered by risk

### F1 — P1: Ordinary sync can delete data added on another device

**Evidence:** `lib/services/cloud_sync_service.dart:635–658` and `670–689`.

When the local ledger is nonempty, normal `sync()` deletes remote documents whose IDs are absent locally, then uploads the local copy. Example: device A has transaction X; device B adds Y; A syncs its stale ledger and deletes Y. Goals follow the same pattern. Treating absence as deletion cannot distinguish a deliberate removal from a device that has never received the record.

**Plan:** Reserve destructive replacement for an explicit backup/restore operation. For normal sync, use a durable SQLite outbox, immutable operation IDs, record revisions, explicit deletion tombstones, and a documented conflict rule. Capture the account/UID and session generation before asynchronous work; reject results if the session changes. The tracked `firestore.rules` already checks authenticated UID ownership; connect it to `firebase.json` (currently no Firestore rules configuration), test it in the emulator, and verify deployed rules. Add schema validation and reserve authoritative entitlement writes for the backend.

**Acceptance:** Emulator-backed two-device tests preserve independently added records, propagate explicit deletions, reject cross-user access, and survive restart/offline retries without duplication. Local A must never be uploaded to authenticated cloud B. Deployed rules were not inspected; the missing deployment configuration does not prove the live database is public.

### F2 — P1: Sync silently stops uploading after 400 transactions

**Evidence:** `lib/services/cloud_sync_service.dart:650–658`; full upload/merge paths at `250–259`, `363–367`.

Normal sync breaks after 400 upserts, commits, and later reports success. With 401 or more local records, the remaining records are omitted. Other upload paths collect an unbounded ledger into one batch, so large datasets can fail on request size or other Firestore constraints. Deletions are also added to the normal batch separately from its 400-upsert counter.

**Plan:** Drain every pending operation through bounded, resumable chunks, counting all writes and respecting payload size and the active backend's limits. Persist acknowledgment checkpoints; report progress and partial failure. Use metadata/aggregate summaries rather than downloading whole collections just to display counts and balances.

**Acceptance:** Exact ID and value equality after 0, 1, 400, 401, 1,000, and 100,000-record syncs; interrupted chunk resumes; success only after every required acknowledgment. Measure reads/writes for a single edit to prove cost scales with changed records.

### F3 — P1: Paid access can be granted through production sandbox paths

**Evidence:** `lib/screens/premium_screen.dart:303`; `lib/services/in_app_purchase_service.dart:150–164`, `224–244`; `lib/services/monetization_service.dart:20–21` and promo handling.

The paywall explicitly calls `buyProduct(... allowSandboxSimulation: true)`. When the store/product is unavailable, this allows local paid entitlement grants even in release mode. Real purchase events also grant entitlement without server verification; writing the receipt into Firestore is an audit log, not verification. The client contains the HMAC signing secret and universal promo paths. A client-shipped secret cannot establish server authority.

**Plan:** Separate development/store-test builds from production. Remove simulation and universal unlocks from the production purchase flow. Validate tokens with a trusted backend and the relevant store API; bind tokens to users, reject replay, handle subscription expiration/refunds/revocation, and issue authoritative entitlements. Define a bounded offline entitlement policy. Initialize Firebase before any purchase event handler that needs its services.

**Acceptance:** Store unavailable, invalid/replayed token, expired subscription, and unauthorized promo cannot grant production access. Valid purchase/restore succeeds, including events received during startup and account switching. Use actual store sandbox accounts for purchase integration tests.

### F4 — P1: Local password recovery expects an OTP that is never emailed

**Evidence:** `lib/screens/login_screen.dart:616–626`, `767–805`, `845`; `functions/index.js:23–40`.

The screen generates a six-digit code in memory but calls Firebase `sendPasswordResetEmail`, which sends a reset link rather than that generated code. The next screen compares user input to the local code. No `sendOtpEmail` invocation appears in the login screen. Firebase credentials and the local SQLite password are separate, so resetting the former does not update the latter.

The separate callable email function accepts a client-selected OTP and recipient, disables App Check, and has no implemented throttle despite its rate-limit comment. If deployed as written, it can be abused as an email sender. Its email's expiration statement is not server-enforced.

**Plan:** Choose a single recovery authority. Prefer Firebase-managed recovery for Firebase identities; local-only accounts need an explicit offline recovery design. If retaining OTPs, generate, hash, expire, rate-limit, and consume challenges on the server, then authorize the local credential transition with a verified result. App Check supplements these controls; it does not replace ownership or abuse prevention.

**Acceptance:** Real email delivery completes recovery and subsequent login; wrong, expired, reused, and excessive attempts fail. Restart and resend behavior are defined. No UI claims delivery when the send fails.

### F5 — P1: Recurring processing has a crash window that can lose an occurrence

**Evidence:** `lib/services/state.dart:819–875`.

The processor adds the active transaction to an in-memory list, marks the plan processed in SQLite, schedules the next plan, and only later saves the ledger. A crash between these writes leaves a processed plan without its financial entry. Saving the entire ledger also adds avoidable work for each processing pass.

**Plan:** In one SQLite transaction, insert the occurrence under a stable unique ID, mark that occurrence processed, create its successor, and enqueue cloud work. Publish notifier changes and schedule notifications after commit. Define catch-up and month-end/leap-year rules; current date constructors can roll invalid month days forward.

**Acceptance:** Fault injection at each write boundary and serialized restart produce exactly one ledger entry per due occurrence, with no lost entries or duplicate successor. Test long offline periods, month ends, leap years, and concurrent invocations.

### F6 — P1: Vault encryption and password claims exceed implementation

**Evidence:** `lib/services/database/app_database.dart:37–48`; `lib/services/database/security_helper.dart:12–15`; dependencies in `pubspec.yaml`.

The database opens with standard SQLite; no application-level database encryption/key configuration is present. OS app isolation is separate from encrypted database contents. Password storage uses one salted SHA-256 pass, which is deliberately fast and unsuitable as a password KDF if the database is copied. These are distinct weaknesses.

**Plan:** Remove the inaccurate encryption claim immediately. Benchmark a maintained encryption solution on supported platforms before adopting it, with OS-backed key storage, recovery/key-loss policy, backup handling, and migration rollback. Version password hashes and migrate successful legacy logins to an established password KDF such as Argon2id with parameters measured on target hardware.

**Acceptance:** Inspect migrated database and backup bytes; verify required key access, wrong-key failure, restart, restore, key loss, and legacy password upgrade. Encryption must not silently make existing ledgers unrecoverable.

### F7 — P2: First frame waits on optional services

**Evidence:** `lib/main.dart:48–83`.

Notifications, language, version, monetization, billing/product lookup, ads, theme, and Firebase setup are awaited sequentially before `runApp`. Optional plugin/network latency delays the splash itself; an unhandled early failure can prevent rendering.

**Plan:** Render a bootstrap shell early. Load the minimal cached appearance state, show bounded loading/error states, and move ads/product discovery/reminder scheduling after the first frame or feature demand. Preserve early purchase-stream listening and Firebase dependency ordering. Parallelize only proven independent reads; avoid concurrently opening the database until its initialization future is memoized.

**Acceptance:** First frame remains available when billing, ads, or network stalls or fails. Record cold-start first-frame and usable-dashboard p50/p95 before and after on the same device.

### F8 — P2: Large ledgers still impose full-list work on the UI path

**Evidence:** `lib/services/database/app_database.dart:1011–1017`; `lib/screens/all_transactions_screen.dart:54–67`; `lib/screens/insights_screen.dart:42–45`; `lib/widgets/interactive_chart_card.dart:86`; `lib/services/state.dart:262`.

All transactions are loaded at login. Search filters and allocates a new list on rebuild, including each text change. Analytics caching hashes every transaction even on a cache hit, and chart aggregation scans its input on rebuild. The transaction list already uses a lazy `SliverList`; the missing optimization is bounded data/computation, not replacing its list widget.

**Plan:** Add keyset pagination ordered by `(date, id)` with username/date filtering; push summary aggregation to SQLite. Use bounded search with debounce and cancellation or generation tokens. Replace whole-list hash cache checks with explicit data revision keys plus period/currency/date-boundary inputs. Profile before adding an isolate; use an isolate only for expensive pure computation with transfer overhead measured. Preserve exact report outputs through a golden dataset comparison.

**Acceptance:** Profile 1k/10k/100k ledgers; initial list queries return a bounded page; editing one record avoids full-ledger persistence; search results stay current after fast typing/account switches; summary totals match the full dataset.

### F9 — P2: Goal loading performs one extra query per goal

**Evidence:** `lib/services/database/app_database.dart:1135–1156`.

`loadGoals` queries goals, then awaits a separate entries query inside the goal loop. This is an N+1 database pattern and increases login/refresh latency with goal count.

**Plan:** Fetch the user's matching entries once and group by goal ID, or use an appropriately scoped join. Select indexes using `EXPLAIN QUERY PLAN`, rather than adding speculative indexes.

**Acceptance:** Bounded query count independent of goal count, stable entry ordering, and unchanged account/archive isolation.

### F10 — P2: Android release settings prioritize build speed over distribution readiness

**Evidence:** `android/app/build.gradle.kts:36–49` and disabled lint-vital task configuration.

Release currently uses debug signing, disables shrinking, and disables release lint checks. This is unsuitable as the final store release setup, and it prevents meaningful optimized artifact-size comparison.

**Plan:** Configure an owner-controlled upload key outside Git, restore release lint, then test minification/resource shrinking against Firebase, notifications, ads, and billing. Build an app bundle and compare delivered size. Retain a fast development flavor if useful.

**Acceptance:** Signed internal-track bundle installs and passes real auth, notifications, purchases, and offline ledger smoke tests. No keys/passwords committed. Signing and shrinker changes need independent validation.

### F11 — P2: Tests and documentation do not establish runtime performance

**Evidence:** `test/smoothness_benchmark_test.dart:65–89`; `test/benchmark_100k_transactions_test.dart`; `test/web_compatibility_test.dart`.

Widget pump stopwatch timings measure the headless harness, not device raster timing. The 100k benchmark constructs its own database and primarily prints timings; it does not prove full-app startup, memory use, sync, or scrolling at that scale. Web-named widget tests run on the host by default. Ordinary SQLite/FFI and `dart:io` services require a real browser compile/runtime check before advertising supported web operation.

**Plan:** Keep correctness tests, fix existing failures, add integration tests with real frame timing and controlled datasets, and check browser support explicitly. Distinguish unsupported/mocked notification behavior from successful native scheduling. Keep claims tied to a named device/build/dataset.

**Acceptance:** Green deterministic baseline; reproducible profile traces, memory snapshots, and real platform smoke checks. A passing analyzer alone is not release readiness.

### F12 — P3: Lifecycle and schema maintenance can be simplified incrementally

**Evidence:** `lib/screens/main_nav_screen.dart:22–98`; `lib/services/database/app_database.dart:29–34`, `48`, `125–215`; `lib/services/connectivity_service.dart:60–65`.

Visited tabs are retained in a lazy `IndexedStack`, contrary to older README descriptions of destroying every off-screen tab. The database uses version 1 with repeated exception-swallowing schema alterations on open; the initialization future is not memoized. Connectivity polls DNS every 12 seconds, including periods when lifecycle-aware suspension would be preferable.

**Plan:** Keep lazy tab caching until memory traces justify changing it; wrap inactive tab animation subtrees with correctly scoped `TickerMode` and measure. Add versioned transactional migrations with explicit failure reporting and a shared database initialization future. Pause optional polling in background and use actual operation errors as the authority on service reachability.

**Acceptance:** Bounded memory after repeatedly visiting tabs; inactive animations stop; concurrent first database requests share one initialization; old fixture databases migrate or fail visibly without data loss; background polling stops.

## Implementation sequence and estimated effort

Estimates are engineering days, not commitments, and exclude store approval or unavailable credentials/hardware.

| Phase | Work | Estimate | Exit condition |
| --- | --- | --- | --- |
| 0: Reproducible baseline | Classify current failures, isolate test databases/plugins, profile target Android phone, seed 1k/10k/100k fixtures | 1–2 days | Test failures explained; baseline traces and dataset retained |
| 1: Ledger safety | F1, F2, F5; versioned migration needed for outbox/revisions; Firestore rules tests | 4–7 days | Two-device, restart, crash, chunk-resume, ownership tests pass |
| 2: Identity and revenue | F3, F4; remove false security claims; implement chosen KDF/encryption migration from F6 | 4–8 days | Real recovery and verified purchase paths; migration/recovery evidence |
| 3: Startup and scale | F7–F9; memoize database open; measure tab lifecycle before changing caching | 3–5 days | Same-device before/after startup, search, frames, memory improve without correctness regressions |
| 4: Release and maintenance | F10–F12, dependency advisory/compatibility review, CI checks, platform support table | 2–3 days | Signed optimized internal build and supported-platform smoke evidence |

Recommended first implementation slice: reproduce F1/F2/F5 with focused regression tests, then repair persistence/sync. First performance slice after that: instrument and shorten pre-first-frame initialization. Avoid a broad rewrite, blanket repaint boundaries, mass dependency upgrades, or speculative GPU changes.

## Measurement protocol and proposed targets

Targets are proposals; none are claimed as achieved. Choose a representative lower/midrange Android phone and keep OS, refresh rate, build mode, temperature, dataset, and network conditions recorded.

1. Run `flutter run --profile -d <device-id>`; retain DevTools performance/memory exports and app commit ID.
2. Capture at least 10 cold starts and 30 repeats of tab switches, search, chart changes, add/edit/delete, theme changes, and a sync cycle. Measure first-visit and cached-tab behavior separately.
3. Use 1k, 10k, and 100k records across multiple years/accounts and enough goals to expose N+1 loading. Repeat with offline, slow network, store unavailable, and account switching during requests.
4. Report first-frame and usable-dashboard p50/p95, UI/raster frame durations and missed-frame ratio, search p95, incremental write latency, SQLite query count, cloud reads/writes, memory after repeated navigation, and delivered app size.
5. Proposed initial gates: cold-start first frame p95 under 1 second and usable dashboard p95 under 2 seconds on the agreed device; search p95 under 150 ms including debounce; at least 99% of steady-state UI/raster frames within the chosen refresh budget (16.67 ms at 60 Hz, 8.33 ms at 120 Hz); no unbounded memory growth after repeated cycles. Recalibrate targets from the baseline rather than weakening correctness to hit them.
6. Sync correctness gates are absolute: all acknowledged operations survive restart, no cross-user access, no unrelated remote deletion, and exact reconciliation at every tested size.

## Verification commands for implementation work

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter pub outdated
flutter run --profile -d <android-device-id>
flutter build appbundle --release
# Only when web is a supported target; then launch and exercise it in a real browser:
flutter build web --release
# Functions syntax check; add emulator-backed integration/rules tests separately:
node --check functions/index.js
```

Never treat these commands as evidence of success until their outputs are captured. Use a separate development Firebase project/emulators and store test accounts for destructive/recovery/purchase tests. Do not test destructive synchronization against a user's only ledger.

## Primary guidance consulted before finalizing recommendations

- [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance): use a physical device in profile mode to assess UI/raster performance.
- [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices): reduce build cost and expensive operations; prefer lazy construction where appropriate.
- [Play Billing fraud and abuse protections](https://developer.android.com/google/play/billing/security): verify purchases through trusted backend logic and handle revocation.
- [Firebase transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions): atomicity and bounded write design; do not infer unlimited-scale sync from a single batch.
- [Cloud Functions App Check enforcement](https://firebase.google.com/docs/app-check/cloud-functions): enforce attestation alongside application authorization and abuse controls.
- [OWASP password storage guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html): use a password KDF, not a single fast hash.
- [Flutter Android release guide](https://docs.flutter.dev/deployment/android): signing, shrinking, and release artifact verification.
