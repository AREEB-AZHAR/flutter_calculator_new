# Scrolling performance update — 1.8.19+29

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

Transactions and Accounts already use lazy transaction slivers; this update does not rewrite those lists. Chart monthly/yearly painter preparation and first-period aggregation still run synchronously, and full Insights report generation remains on the UI isolate. Very large individual cards, native ads, expensive analytics and device/debug-mode overhead remain possible contributors. No database or cloud protocol changed.

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
