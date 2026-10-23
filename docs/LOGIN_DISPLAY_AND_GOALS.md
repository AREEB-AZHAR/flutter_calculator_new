# Login, display preferences and hidden goals

Version **1.8.21+31**, 24 October 2026. No APK was built.

## Findings and implementation plan

1. Remove purchase verification from local login while keeping production paid access server-authorized. The purchase-security change (`908ebd8`) awaited the backend before reading the local profile. An unavailable backend could therefore delay the profile. Preserve the stored paid palette while verification is unavailable; deferred palette restoration checks session identity and intervening user changes.
2. Render the dashboard before cloud comparison. Keep explicit conflict choices; automatically merge when only one side contains data, because the user can now edit while metadata loads. Include goals when checking whether a vault contains records. Schedule optional reminders separately, retain atomic recurring writes, and skip redundant ledger reads/reminders when no occurrence is due.
3. Add **FREEVIP exclusively to debug builds**, as confirmed by the owner. Keep its device-wide preference separate from store receipts. Release/profile binaries ignore the code and preference. Leave it until the owner requests removal.
4. Offer **System / 60 / 120 Hz** through Android's window refresh preference. Filter modes to the current resolution, reject unsupported rates, persist accepted preferences and reapply on resume. This is a display hint, not guaranteed rendered FPS.
5. Expose archived goals and add confirmed permanent removal. Old soft-delete archives funded/completed goals; ordinary loading hides archives while sync includes them. This reproduces a hidden-record path; the owner's actual device data has not been inspected. Delete entries, goal and durable outbox tombstone atomically, retaining financial transactions. Allow explicit cloud refresh to discover cloud-only goals.
6. Load goals and scoped entries in two SQL reads rather than N+1. Verify entry grouping, user isolation, rollback, restart and repeated sync after removal.
7. Follow up on the owner's **release build on Redmi Note 13**, worst on Dashboard, Accounts and Insights, occasionally Profile and the transaction popup. Insights previously hashed every transaction on every cache check and hashed fresh `MapEntry` objects, defeating report reuse. Git history traces that implementation to `a1a5f49`; this identifies a code defect, not the author or cause of all device jank. Replace this with snapshot identity comparisons, invalidated on data, period, currency or date changes. Cache Dashboard's liquid balance, and bound transaction-dialog width to avoid intrinsic measurement of the whole form. Existing Accounts/Profile/chart caches remain in place.

Research: Android recommends [`preferredRefreshRate` for rate-only preferences](https://developer.android.com/media/optimize/performance/frame-rate). Flutter recommends [lazy construction and avoiding repeated work](https://docs.flutter.dev/perf/best-practices), with [frame profiling on a physical device](https://docs.flutter.dev/perf/ui-performance). Keep System as default, use debug FREEVIP for ad-free functional checks, and profile the same device/data/routes across commits before attributing broader regressions. The reported installed build is release, so debug overhead does not explain that report.

## Using the changes

- **Debug ad-free testing:** Profile → Open Settings → Appearance → Display & testing → Enter testing code → `FREEVIP`. It grants local debug Pro/no-ads across accounts and restarts. **Disable FREEVIP** removes the override and refreshes genuine entitlements. It will not work in the owner's current release APK. No receipt or backend purchase is created.
- **Refresh preference:** use System, 60 Hz or 120 Hz in the same card. Unsupported choices are disabled. Other platforms use System. Battery saving, thermal state and OS policy may override the hint. A 120 Hz display does not establish 120 rendered FPS.
- **Hidden goal cleanup:** Goals → top-right **Manage all goals** icon → inspect archived records. If needed, **Refresh from cloud**, then trash → **Remove goal**. This permanently removes goal/deposit history and queues sync deletion; financial ledger transactions remain. No records are automatically purged by this update. Cloud tombstone documents intentionally remain with `_deleted: true` to prevent resurrection and are excluded from visible counts.

Remove the testing exception later by setting `MonetizationService.testingVipCodeEnabled` to `false` or removing its paths/UI. Existing `tally_testing_freevip` flags are ignored when disabled and can be removed. Never enable release local-grant paths for testing.

## Architecture and setup

| Area | Implementation |
| --- | --- |
| Login | `monetization_service.dart` starts background verification; `state.dart` loads local data and guards deferred palette/reminder work by session. |
| Cloud | `main_nav_screen.dart` starts comparison after its first frame; `login_screen.dart` no longer waits on remote vault metadata. Explicit restore/overwrite remain deliberate destructive choices. |
| Display | `DisplayRateService`, `TestingPerformanceSettings` and Android `MainActivity` use `com.areeb.tally/display_rate`. Unsupported/plugin-error cases select System. |
| Goals | `GoalManagerDialog` lists archives; `AppDatabase.permanentlyDeleteGoal` commits removal and existing outbox triggers together. Reminder cancellation follows commit. |
| Rendering work | `InsightsReportCache` and `LiquidBalanceCache` rely on AppState publishing replacement collections after mutations. Never mutate published collections/records in place. `transaction_dialog.dart` gives its scrollable form bounded width. |

Follow the root README clone, SDK, Firebase and run instructions. Audited tools: Flutter **3.41.3**, Dart **3.11.1**, AGP **8.11.1**, Kotlin **2.2.20**, Gradle **8.14**, compatible JDK 17/21. This host uses `C:\Program Files\Java\jdk-21.0.11`. Keep SDK paths in untracked `android/local.properties`. No new dependency, permission, secret or database migration is required.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter test --no-pub test/login_display_goal_repair_test.dart
# Optional native Kotlin compile only; no APK assembly/packaging:
cd android
.\gradlew.bat :app:compileDebugKotlin -x compileFlutterBuildDebug --console=plain
```

## Validation

Final checks passed:

| Check | Result / evidence |
| --- | --- |
| Full Flutter suite | **244 passed**, [log](audit-evidence/login-display-goals-full-tests.txt) |
| Focused login, FREEVIP, display, goals, report caches and related screens | **20 passed**, [log](audit-evidence/login-display-goals-targeted.txt) |
| Settings navigation | **4 passed**, [log](audit-evidence/login-display-goals-settings-tests.txt) |
| Static analysis | **No issues**, [log](audit-evidence/login-display-goals-analysis.txt) |
| Android Kotlin compilation | **BUILD SUCCESSFUL**, [log](audit-evidence/login-display-goals-kotlin.txt); Flutter compilation excluded, no assemble/package task |
| Server unit tests | **10 passed**, [log](audit-evidence/login-display-goals-server-tests.txt) |
| Firestore emulator tests | **10 passed**, [log](audit-evidence/login-display-goals-emulator-tests.txt); demo project only |

New regressions cover pending verification without blocking local profile loading, stored paid-palette preservation, stale-session guards, debug override persistence/disable, unsupported refresh fallback, archived entry loading, confirmed UI deletion, atomic rollback, durable restart/sync tombstones and cache hits with zero additional row reads. Settings tests use the sheet's controller to reach lazy sections. The installed APK was not replaced; the existing local debug APK remains dated 23 October. ADB listed no connected devices, so no physical frame trace was available.

 Host tests use isolated real SQLite, a controlled ledger remote and mocked display messages. They do not establish live Firebase behavior, notification delivery or device FPS. Live purchase/recovery activation remains subject to the billing prerequisites in [the setup guide](PURCHASE_AND_RECOVERY_SECURITY.md).

## Device follow-up

1. On the Redmi Note 13, record OS version and UI/raster frame times on the same data and scroll routes across commits. Check Dashboard, Accounts, Insights, Profile and transaction-popup opening/keyboard animation. Source findings do not establish end-to-end FPS or blame another contributor.
2. In debug, redeem FREEVIP; check existing banners disappear, tab interstitials are skipped and the preference survives restart. Disable it and confirm entitlement checks resume. A release/profile build must ignore the flag.
3. Check each supported refresh choice, the reported device rate, and fallback under power saving or unsupported-rate conditions.
4. Log in with unavailable network/backend: local profile opens while paid access remains locked. Verify deferred paid-palette restoration and account switching with real purchases once the backend is deployed.
5. With sample data, cancel goal removal once, then confirm it, restart offline and sync twice after reconnecting. The goal stays absent and financial transactions remain.
6. Capture real screenshots of Appearance → Display & testing and Goals → Manage all goals using fictitious values and hidden account identifiers. Place them in `assets/screenshots/`; host widget tests do not substitute for device screenshots.
