# phase1-rows — 24 October 2026

DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 AOT profile | REFRESH: native-verified 60 Hz, 16.666666 ms budget.
Three captures per screen/configuration. Warmed four slow drags and two flings; dialog routes use their separately documented open/focus/dismiss protocol. Native rate is checked before/after every capture. No average FPS.

| Variant | Screen | Run | Frames | Build p50/p95 ms | Raster p50/p95 ms | Worst build/raster ms | Worst stage ms | Janky % |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| a | dashboard | 1 | 334 | 0.528/1.284 | 16.104/18.196 | 4.617/22.904 | 22.904 | 28.443 |
| a | dashboard | 2 | 271 | 0.641/2.329 | 4.862/13.372 | 25.580/35.602 | 35.602 | 3.690 |
| a | dashboard | 3 | 284 | 0.572/1.285 | 4.642/15.774 | 4.453/23.018 | 23.018 | 4.577 |
| a | accounts | 1 | 437 | 0.629/1.636 | 4.186/7.136 | 4.128/23.954 | 23.954 | 1.373 |
| a | accounts | 2 | 345 | 0.613/1.720 | 4.054/13.203 | 3.911/24.469 | 24.469 | 2.319 |
| a | accounts | 3 | 362 | 0.660/1.649 | 4.081/10.601 | 4.193/24.262 | 24.262 | 1.381 |
| a | insights | 1 | 301 | 0.595/1.698 | 4.333/14.382 | 3.546/24.131 | 24.131 | 3.322 |
| a | insights | 2 | 302 | 0.619/1.697 | 4.346/13.553 | 4.123/24.608 | 24.608 | 3.311 |
| a | insights | 3 | 313 | 0.648/1.769 | 4.342/12.429 | 3.787/23.164 | 23.164 | 2.556 |
| a | transactions | 1 | 342 | 0.657/1.768 | 3.933/10.490 | 3.640/22.171 | 22.171 | 1.462 |
| a | transactions | 2 | 339 | 0.667/1.778 | 3.803/12.545 | 4.152/20.148 | 20.148 | 1.180 |
| a | transactions | 3 | 360 | 0.718/1.810 | 3.930/7.363 | 3.922/19.133 | 19.133 | 0.833 |
| b | dashboard | 1 | 297 | 0.631/1.389 | 4.670/12.679 | 4.377/24.637 | 24.637 | 3.030 |
| b | dashboard | 2 | 280 | 0.595/1.293 | 4.339/12.581 | 4.523/20.864 | 20.864 | 1.786 |
| b | dashboard | 3 | 257 | 0.498/1.214 | 4.554/15.513 | 4.085/22.216 | 22.216 | 3.891 |
| b | accounts | 1 | 338 | 1.002/2.295 | 4.079/14.025 | 4.825/24.242 | 24.242 | 2.959 |
| b | accounts | 2 | 349 | 1.057/2.280 | 4.052/9.497 | 4.648/24.078 | 24.078 | 2.292 |
| b | accounts | 3 | 353 | 1.076/2.251 | 4.139/11.079 | 4.654/24.062 | 24.062 | 2.266 |
| b | insights | 1 | 303 | 0.635/1.597 | 4.538/14.895 | 4.395/22.867 | 22.867 | 4.290 |
| b | insights | 2 | 287 | 0.602/2.014 | 4.265/13.284 | 4.062/23.041 | 23.041 | 3.136 |
| b | insights | 3 | 310 | 0.627/1.767 | 4.446/12.205 | 3.713/23.880 | 23.880 | 2.581 |
| b | transactions | 1 | 394 | 1.258/2.585 | 4.005/5.300 | 5.821/19.750 | 19.750 | 1.015 |
| b | transactions | 2 | 364 | 1.214/2.630 | 4.034/6.513 | 4.649/18.241 | 18.241 | 0.275 |
| b | transactions | 3 | 368 | 1.154/2.210 | 4.539/7.641 | 6.043/17.487 | 17.487 | 0.272 |

## B versus A: positive means improvement

Repetitions are paired by index. Deltas use unrounded numbers; a printed rounded 15.000% is not sufficient to pass. Require the same metric to improve by >=15% in all three repetitions. This threshold is an acceptance rule, not statistical significance.

| Screen | Run | Raster p95 improvement % | Janky-ratio improvement % |
|---|---:|---:|---:|
| dashboard | 1 | 30.320 | 89.346 |
| dashboard | 2 | 5.915 | 51.607 |
| dashboard | 3 | 1.655 | 14.996 |
| accounts | 1 | -96.539 | -115.483 |
| accounts | 2 | 28.069 | 1.146 |
| accounts | 3 | -4.509 | -64.079 |
| insights | 1 | -3.567 | -29.142 |
| insights | 2 | 1.985 | 5.296 |
| insights | 3 | 1.802 | -0.968 |
| transactions | 1 | 49.476 | 30.558 |
| transactions | 2 | 48.083 | 76.717 |
| transactions | 3 | -3.776 | 67.391 |

```text
PHASE: 1 - phase1-rows (dashboard)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.528/1.284, 0.641/2.329, 0.572/1.285; raster p50/p95 16.104/18.196, 4.862/13.372, 4.642/15.774; janky 28.443, 3.690, 4.577%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.631/1.389, 0.595/1.293, 0.498/1.214; raster p50/p95 4.670/12.679, 4.339/12.581, 4.554/15.513; janky 3.030, 1.786, 3.891% (3 captures)
DELTA: raster p95 improvement 30.320, 5.915, 1.655%; janky improvement 89.346, 51.607, 14.996%
DECISION: revert: numeric threshold not met
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-rows-{a,b}-dashboard-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-rows (accounts)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.629/1.636, 0.613/1.720, 0.660/1.649; raster p50/p95 4.186/7.136, 4.054/13.203, 4.081/10.601; janky 1.373, 2.319, 1.381%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 1.002/2.295, 1.057/2.280, 1.076/2.251; raster p50/p95 4.079/14.025, 4.052/9.497, 4.139/11.079; janky 2.959, 2.292, 2.266% (3 captures)
DELTA: raster p95 improvement -96.539, 28.069, -4.509%; janky improvement -115.483, 1.146, -64.079%
DECISION: revert: numeric threshold not met
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-rows-{a,b}-accounts-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-rows (insights, unchanged control)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.595/1.698, 0.619/1.697, 0.648/1.769; raster p50/p95 4.333/14.382, 4.346/13.553, 4.342/12.429; janky 3.322, 3.311, 2.556%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.635/1.597, 0.602/2.014, 0.627/1.767; raster p50/p95 4.538/14.895, 4.265/13.284, 4.446/12.205; janky 4.290, 3.136, 2.581% (3 captures)
DELTA: raster p95 improvement -3.567, 1.985, 1.802%; janky improvement -29.142, 5.296, -0.968%
DECISION: unchanged control
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-rows-{a,b}-insights-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-rows (transactions)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.657/1.768, 0.667/1.778, 0.718/1.810; raster p50/p95 3.933/10.490, 3.803/12.545, 3.930/7.363; janky 1.462, 1.180, 0.833%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 1.258/2.585, 1.214/2.630, 1.154/2.210; raster p50/p95 4.005/5.300, 4.034/6.513, 4.539/7.641; janky 1.015, 0.275, 0.272% (3 captures)
DELTA: raster p95 improvement 49.476, 48.083, -3.776%; janky improvement 30.558, 76.717, 67.391%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-rows-{a,b}-transactions-60hz.json; source/configuration metadata; validation logs.
```

## Final source selection

Adopt only AllTransactionsScreen's row-boundary removal. Restore Dashboard and Accounts; Insights was an unchanged control. Transactions meets the janky-ratio criterion in all three captures: 30.558 / 76.717 / 67.391% improvement. Its build p95 changes from 1.768 / 1.778 / 1.81 ms to 2.585 / 2.63 / 2.21 ms. Raster p95 does not improve in every capture, so the adoption is explicitly based on janky ratio, not raster p95.

The absolute janky-frame counts are 5 / 4 / 3 before and 4 / 1 / 1 after. These small counts limit confidence; this is not a permanent root-cause finding. The proposed Phase 4 budgets are still not met in every capture. The initial Dashboard A capture was a high-raster outlier and is retained in full; it is not discarded to improve a result. Even with that outlier the Dashboard change does not meet the strict unrounded acceptance rule.

Structural diagnostic: before, 2 boundaries between each transaction row and its scrollable in all three screen fixtures; full B, Dashboard 1 shared section boundary, Accounts/Transactions 0. Selected source restores Dashboard/Accounts and retains Transactions only. Row keys and edit/delete callbacks, chart/ad/section boundaries, physics, schema, sync and entitlements are preserved. Unmeasured loan/goal/guide rows were not changed.

References: [Flutter RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html), [delegate boundary tradeoff](https://api.flutter.dev/flutter/widgets/SliverChildListDelegate/addRepaintBoundaries.html). These explain the hypothesis; capture data, not documentation, determine adoption.

Selected-source validation completed: 251 full-suite tests passed; analysis clean; three actual-screen boundary diagnostics passed with Dashboard 2, Accounts 2, Transactions 0 boundaries per sampled row before the scrollable. See phase1-rows-selected-{analysis,full-tests,structure-tests}.txt. No APK, private screenshot or VM authentication URI is committed. The authorized temporary 60 Hz phone preference continues for the independent renderer comparison and will be restored afterward.

### 24 October 2026 — Follow-up supersedes adoption

The initial Transactions-only selection above is superseded. Fresh selected-build captures in phase1-renderer-a-transactions-60hz.json produced jank **0.234 / 1.093 / 1.475%**. Against the original baseline, the three relative jank improvements are **83.981 / 7.377 / -76.991%**, failing consistent replication. This later sequential set is not a randomized experiment and its selected build restores other screens; the uncertainty is why the conservative final decision is **revert Transactions too**, not claim a robust improvement. All original row boundaries are restored. See phase1-rows-followup-decision.json and phase1-renderer-final-structure-tests.txt. The renderer comparison held its installed experimental APK immutable despite the later working-tree revert.
