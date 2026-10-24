# Scrolling performance updates — through 1.8.20+30

## Accounts, Transactions and Profile follow-up — 24 October 2026

The follow-up inspects these screens' surrounding content and data work while preserving their existing transaction/loan row virtualization. The researched plan follows Flutter's guidance to avoid repeated work in `build()` and use lazy builders:

1. Cache wallet/account grouping, loan summaries/filter groups, transaction filtering and Profile spending summaries against the current immutable snapshot.
2. Build the wallet/loan/transaction headers lazily with `LazySectionSliver`; retain existing chart/ad state through automatic keep-alive. Pass the selected wallet's indexed rows directly to its chart.
3. Build Profile summary/settings sections lazily; forward the draggable sheet's controller and reset its list to the top when changing settings categories.
4. Retain search text in a screen-owned controller, debounce filtering by 180 ms, cancel obsolete timers on clear/dispose, and keep chart/list search results consistent.
5. Reuse Profile's recovery-email lookup future within a user/session, invalidate after binding or Google linking, and key the display to the user/session so old data is not carried across account changes. Update currency labels reactively without rescanning the ledger.
6. Run cache/scroll regressions, existing settings/theme/loan tests, the complete Flutter suite and analysis. Do not build an APK.

`lib/services/ledger_view_cache.dart` contains bounded per-screen caches. Wallet grouping preserves ledger order and includes unlisted wallets in Overall totals. Loan totals exclude settled entries; settlement/list replacement invalidates the result. Search remains case-insensitive across title, category and account and supports All/Income/Expense filters. Spending totals, largest expense, essential/discretionary classification and top four categories preserve the previous calculations.

Cache invalidation relies on the same existing new-list publication contract as the chart cache: replace transaction/loan lists when editing, deleting, restoring, syncing or switching sessions. Filtered/grouped results are read-only; the unfiltered result reuses the published source. Caches retain only the current source/result, with O(n) row-reference storage for grouped wallets. Initial summarization and a new search query still perform O(n) work on the UI isolate; the debounce reduces work during typing bursts, and repeated rebuilds/cache hits avoid it. A new wallet chart period still computes its own analytics. Profile's four-cell grid remains bounded and is only constructed when its section enters the viewport. Native ad raster cost, first-frame startup and full Insights report generation remain separate profiling work.

New regressions exercise 100,000-row wallet, spending and search views, zero extra source reads on cache hits, new-snapshot invalidation, loan settlement, search debounce/clear/disposal, lazy transaction rows, wallet switching and the Profile settings footer/category navigation. Evidence: [focused follow-up tests](audit-evidence/scroll-followup-targeted.txt), [full suite](audit-evidence/scroll-followup-full-tests.txt), [analysis](audit-evidence/scroll-followup-analyze.txt). **Results: 233 full-suite tests and 21 focused tests passed; analysis found no issues.** The final focused rerun also checks currency refresh while the cached Profile summary is displayed. These establish correctness and reduced repeated work, not hardware FPS; no device trace or APK was produced. Backend/deployment configuration is unchanged.

## Initial Home, Insights and Goals update — 1.8.19+29

24 October 2026. The reported symptom is sluggish scrolling on several screens. A phone model, build mode and device frame trace were not supplied, so the specific source of dropped frames has **not** been established on hardware. No APK was built.

## Plan and evidence

Following source inspection and Flutter's [performance guidance](https://docs.flutter.dev/perf/best-practices), inspect layout/build work before changing graphics or scroll physics. Flutter recommends lazy builders for large scrollable content. Keep profile-mode device measurements separate from host widget tests; [debug timing does not establish release performance](https://docs.flutter.dev/perf/ui-performance).

1. Replace eager scrolling columns with sections built near the viewport.
2. Build goal cards on demand rather than constructing every card.
3. Reuse chart period/category summaries across visual changes without rescanning an unchanged ledger snapshot.
4. Preserve chart controls and native ad instances across lazy eviction; pause tickers in cached hidden tabs.
5. Verify reachability, content filtering, state retention and the full suite. Profile a physical device as the next measurement step, respecting the standing no-APK-build instruction.

## Changes and limits

| Area | Source finding and change |
| --- | --- |
| Home | A `SingleChildScrollView` laid out the full dashboard column. `LazySectionList` now builds/layouts nearby sections using `ListView.builder`. |
| Insights | All selected report cards were constructed and laid out together. Their builders are now lazy. Existing tests scroll to each report section and verify domain filtering across the full report. |
| Goals | The list constructed every active/ended goal card before scrolling. Separate sliver builders now construct visible cards while preserving group order, stable goal keys and actions. |
| Chart | Every rebuild filtered the full ledger and recomputed category totals. A per-chart single-entry summary cache reuses unchanged period/account inputs. Chart selection stays alive when scrolling offscreen. |
| Ads | Banners retain state across lazy eviction to avoid repeated ad loads and native platform-view recreation. Native rendering still needs device profiling. |
| Cached tabs | `TickerMode` now disables tickers for hidden tabs without destroying their state. Hidden tabs may still receive data notifications; this is not a blanket suspension of background work. |

At the 1.8.19 baseline, Transactions and Accounts already used lazy transaction slivers; their header/data-work follow-up is documented above. Chart monthly/yearly painter preparation and first-period aggregation still run synchronously, and full Insights report generation remains on the UI isolate. Very large individual cards, native ads, expensive analytics and device/debug-mode overhead remain possible contributors. No database or cloud protocol changed.

The summary cache relies on the existing `AppState` contract: every ledger mutation publishes a **new list** and transaction fields are immutable. A new list, account or period invalidates the cache. Do not mutate a published list in place. The cache retains only the current chart summary, not an unlimited history. Chart/ad keep-alive retains those stateful sections after first use; other sections remain evictable. PageStorage keys preserve scroll position across ordinary rebuilds/tab caching.

## Validation and reproduction

Run from the repository root with the README toolchain (Flutter 3.41.3 / Dart 3.11.1):

```powershell
flutter test --no-pub --concurrency=1 test/scroll_performance_test.dart test/insights_screen_widget_test.dart test/cloud_sync_modal_and_tab_cache_test.dart --reporter expanded
flutter test --no-pub --concurrency=1 --reporter expanded
flutter analyze --no-pub
```

Structural regressions exercise a 1,000-section scroll view (fewer than 20 mounted text sections near the viewport), a 500-goal list with navigation to the final goal, chart/ad instance retention, hidden-tab ticker state, and a 100,000-row summary. Repeated cache hits must perform **zero additional row reads**; period/account/new-list changes must recompute correct totals. These are operation/layout guarantees, not FPS benchmarks.

Evidence: [targeted tests](audit-evidence/scroll-targeted-tests.txt), [full regression suite](audit-evidence/scroll-full-tests.txt), [static analysis](audit-evidence/scroll-analyze.txt). Final results: **227/227 full-suite tests**, **13/13 focused tests**, and **no static analysis issues**. A subsequent brace/style cleanup and replacement of deprecated test-only ticker API calls were covered by the focused rerun and clean analysis; runtime behavior was unchanged.

For hardware follow-up, first record phone model, Android version, app version, build mode, refresh rate, ledger/goal count and whether native ads are visible. Using an already available matching profile build, record repeated slow drags and flings through Home, Insights, Goals, Accounts and Transactions in DevTools Performance. Separate UI build/layout time from raster time; compare against the actual device frame budget (about 16.7 ms at 60 Hz or 8.3 ms at 120 Hz). Repeat the same data and gesture route before/after changes. Capture report tab changes, chart controls, returning to cached tabs and goal edit/delete as functional checks. Do not build an APK without a new explicit instruction lifting the restriction, and do not claim phone improvements from headless timings.


## 24 October 2026 — Phase 0 profile controls supersede debug timing assumptions

The [three-run profile matrix](PERFORMANCE_BUDGET.md) now measures the Redmi Note 13 at native-verified 60 Hz. Probe B raster p50 **3.620 / 3.679 / 3.930 ms** selects the marginal-device branch. Dashboard build p95 **1.289 / 1.288 / 1.335 ms** contrasts with raster p95 **14.723 / 17.009 / 15.376 ms**. Earlier cache/lazy-layout tests prove reduced work, not that build time caused the persistent symptom. No Phase 1 A/B change is adopted or reverted yet. Continue with isolated physics/layer/tab/renderer experiments only after the relevant interaction/native approvals. Do not infer release performance or a universal ≥6 ms floor from old debug samples.

## 24 October 2026 — Ribbon reset and layout corrections

After the Phase 0 baseline, the owner approved independent ribbon storage keys and the layout repairs uncovered by the diagnostic. Accounts and Insights now restore **150 px**, compared with **0 px** before, after a lazy-header eviction at **1800 px** vertical offset. Two actual-screen regression tests cover the transition at 400 × 800 with 1000 synthetic transactions. The repaired chart/control and Insights summary layouts wrap at narrow widths; Accounts captions ellipsize. No framework overflow remains in these two fixtures. This is a correctness result, not evidence of a raster improvement or a selected-account change.

[Focused evidence](audit-evidence/ribbon-storage-after-tests.txt), [full suite: 251 passed](audit-evidence/ribbon-storage-full-tests.txt), [analysis clean](audit-evidence/ribbon-storage-analysis.txt). The [performance budget document](PERFORMANCE_BUDGET.md) retains every Phase 0 capture and describes pending experiments. No scroll-physics, ad, entitlement, database or native display-policy change was adopted.

Follow-up physical profile captures after repair still exhibit raster spikes; the transaction dialog is particularly affected (raster p95 **33.512 / 26.929 / 30.546 ms**, jank **42.045 / 30.233 / 26.966%**, native 60 Hz). See [all three runs and safeguards](PERFORMANCE_BUDGET.md). These do not establish a cause or an optimization delta. The existing promo security gate prevents profile-mode redemption and was preserved. The original Maximum 120 Hz phone preference was restored after the follow-up.

## 24 October 2026 — Isolated H2 physics A/B reverted

With owner approval, the app-wide forced bounce override was removed temporarily; drag devices and all explicit widget physics were preserved. Three native-verified **60 Hz AOT-profile** captures per configuration on the **Redmi Note 13**, **1.8.22+32**, covered Dashboard, Accounts and Insights. The initial connectivity-banner mismatch was recorded and an original-variant return set added. [Full A/B evidence](audit-evidence/phase1-physics-ab-report.md) includes raw frames, stage percentiles, worst stages, jank and per-run comparisons.

The platform-default variant's Dashboard raster p95 remained **16.085 / 15.837 / 13.852 ms**; it did not establish a consistent performance fix and the original source was restored. The owner's report that 60 Hz feels okay does not prove that the physics change caused an improvement. No 120 Hz capture was taken here. Experimental **253-test** suite and restored **251-test** suite both passed with clean analysis. The variant's interaction tests are archived; later layer-count/renderer/tab experiments remain pending.

## 24 October 2026 — Row repaint-boundary A/B selection

The physical **Redmi Note 13**, **1.8.22+32 AOT profile**, native **60 Hz** experiment retains all three captures per screen/configuration in the [H3 report](audit-evidence/phase1-rows-report.md). Transactions alone meets the acceptance rule: jank **1.462 / 1.180 / 0.833% → 1.015 / 0.275 / 0.272%**. Keep its explicit/automatic row-boundary removal; restore Dashboard and Accounts; Insights is unchanged. Chart, ad and section boundaries remain. Higher Transactions build p95 (**2.585 / 2.630 / 2.210 ms**) and small absolute janky counts limit the result. No root-cause repair is claimed.

Selected source passed **251 tests**, clean analysis, and a three-screen structural probe confirming boundary ancestry **2 / 2 / 0** for Dashboard/Accounts/Transactions. The renderer comparison uses the selected binary as an independent configuration experiment. Full reports include negative results; the definition of done for the wider mission is still unmet.

## 24 October 2026 — Correction after selected-row follow-up; H4 renderer findings

The initial Transactions-only row adoption is superseded: follow-up jank **0.234/1.093/1.475%** was inconsistent, so all original row boundaries are restored. The earlier positive result remains above as historical evidence. [Follow-up decision](audit-evidence/phase1-rows-followup-decision.json).

The independent same-APK renderer matrix contains **42 AOT-profile captures** at native **60 Hz** on **Redmi Note 13, 1.8.22+32**. Engine-verified Skia improves five measured flows consistently, while Dashboard and Accounts are mixed. Insights raster p95 **16.450/13.998/15.663 → 5.571/5.279/5.188 ms**; transaction-dialog jank **25.926/27.160/28.571% → 4/8/0%**. The owner reported Skia clearly better overall. [Full report](audit-evidence/phase1-renderer-report.md) records all three runs, negative results, source/binary context and limitations. A global native setting requires separate approval; the reviewable patch is prepared but not applied at this comparison stage. Final original-row source: **251 tests passed**, analysis clean. No permanent root-cause fix is claimed.

### Final all-user decision — 24 October 2026

Keep the supported Flutter renderer default; do not apply the historical Skia manifest proposal. The owner requested a policy for all user builds, and a single Redmi with mixed Dashboard/Accounts results is insufficient for a deprecated global override. Positive Skia findings remain in the full report. All original row boundaries, the original profile APK/default engine and Maximum 120 Hz phone preference are restored. [Final decision](audit-evidence/phase1-renderer-final-decision.json). All benchmark figures are still 60 Hz profile; no release/120 Hz performance claim or root-cause-elimination claim is made. Final analysis is clean and 251 tests pass.
