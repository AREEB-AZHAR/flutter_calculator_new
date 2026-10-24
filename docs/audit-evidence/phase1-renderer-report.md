# phase1-renderer — 24 October 2026

DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 AOT profile | REFRESH: native-verified 60 Hz, 16.666666 ms budget.
Three captures per screen/configuration. Warmed four slow drags and two flings; dialog routes use their separately documented open/focus/dismiss protocol. Native rate is checked before/after every capture. No average FPS.

| Variant | Screen | Run | Frames | Build p50/p95 ms | Raster p50/p95 ms | Worst build/raster ms | Worst stage ms | Janky % |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| a | dashboard | 1 | 258 | 0.522/1.261 | 4.527/14.010 | 4.824/22.704 | 22.704 | 3.488 |
| a | dashboard | 2 | 296 | 0.675/1.488 | 4.415/13.335 | 4.252/26.765 | 26.765 | 2.365 |
| a | dashboard | 3 | 280 | 0.703/2.338 | 4.848/15.955 | 7.903/25.093 | 25.093 | 4.643 |
| a | accounts | 1 | 342 | 0.694/1.812 | 15.984/17.501 | 6.553/24.419 | 24.419 | 28.363 |
| a | accounts | 2 | 353 | 0.726/1.854 | 3.716/7.770 | 3.166/23.939 | 23.939 | 1.133 |
| a | accounts | 3 | 436 | 0.717/1.846 | 4.201/6.507 | 4.190/23.342 | 23.342 | 0.688 |
| a | insights | 1 | 301 | 0.701/1.850 | 4.724/16.450 | 4.400/27.843 | 27.843 | 4.983 |
| a | insights | 2 | 299 | 0.707/2.085 | 4.402/13.998 | 3.806/28.025 | 28.025 | 3.679 |
| a | insights | 3 | 291 | 0.632/2.021 | 4.308/15.663 | 3.983/22.839 | 22.839 | 3.780 |
| a | goals | 1 | 374 | 0.734/1.050 | 3.646/4.837 | 1.608/18.310 | 18.310 | 0.267 |
| a | goals | 2 | 374 | 0.732/1.044 | 3.598/4.591 | 1.545/18.985 | 18.985 | 0.267 |
| a | goals | 3 | 375 | 0.743/1.133 | 3.875/8.956 | 1.893/19.642 | 19.642 | 0.533 |
| a | profile | 1 | 253 | 0.556/1.135 | 3.938/15.324 | 2.689/25.573 | 25.573 | 3.557 |
| a | profile | 2 | 365 | 0.758/1.729 | 4.545/9.171 | 3.392/24.187 | 24.187 | 0.548 |
| a | profile | 3 | 276 | 0.639/1.383 | 4.085/8.105 | 2.242/21.645 | 21.645 | 1.449 |
| a | transactions | 1 | 427 | 1.325/2.629 | 3.771/5.513 | 13.659/22.499 | 22.499 | 0.234 |
| a | transactions | 2 | 366 | 1.246/2.692 | 3.936/9.905 | 4.989/21.564 | 21.564 | 1.093 |
| a | transactions | 3 | 339 | 1.259/2.686 | 3.921/10.853 | 4.975/22.791 | 22.791 | 1.475 |
| a | transaction_dialog | 1 | 81 | 1.535/3.617 | 8.614/24.798 | 13.949/57.727 | 57.727 | 25.926 |
| a | transaction_dialog | 2 | 81 | 1.321/3.064 | 5.532/29.275 | 15.257/35.598 | 35.598 | 27.160 |
| a | transaction_dialog | 3 | 84 | 1.669/3.420 | 13.472/33.861 | 17.723/35.632 | 35.632 | 28.571 |
| b | dashboard | 1 | 280 | 0.695/1.369 | 3.569/5.737 | 5.264/7.903 | 7.903 | 0.000 |
| b | dashboard | 2 | 350 | 0.877/3.320 | 5.650/12.911 | 23.247/31.263 | 31.263 | 2.286 |
| b | dashboard | 3 | 366 | 0.717/1.858 | 4.876/9.548 | 4.004/15.397 | 15.397 | 0.000 |
| b | accounts | 1 | 472 | 1.439/6.154 | 5.249/13.320 | 18.442/27.830 | 27.830 | 2.119 |
| b | accounts | 2 | 463 | 1.123/4.685 | 5.985/18.465 | 20.223/29.542 | 29.542 | 7.991 |
| b | accounts | 3 | 395 | 0.769/2.262 | 3.392/6.763 | 3.711/13.052 | 13.052 | 0.000 |
| b | insights | 1 | 287 | 0.685/2.089 | 3.183/5.571 | 4.068/7.807 | 7.807 | 0.000 |
| b | insights | 2 | 287 | 0.680/2.051 | 3.179/5.279 | 4.272/10.458 | 10.458 | 0.000 |
| b | insights | 3 | 311 | 0.715/1.774 | 3.165/5.188 | 4.335/7.494 | 7.494 | 0.000 |
| b | goals | 1 | 374 | 0.721/0.988 | 3.139/5.779 | 1.802/9.502 | 9.502 | 0.000 |
| b | goals | 2 | 374 | 0.726/0.976 | 3.214/5.658 | 1.535/10.705 | 10.705 | 0.000 |
| b | goals | 3 | 373 | 0.733/0.978 | 3.279/5.719 | 1.792/9.561 | 9.561 | 0.000 |
| b | profile | 1 | 277 | 0.641/1.256 | 3.121/5.321 | 2.084/9.240 | 9.240 | 0.000 |
| b | profile | 2 | 277 | 0.728/1.264 | 3.218/5.106 | 1.765/8.337 | 8.337 | 0.000 |
| b | profile | 3 | 253 | 0.558/1.127 | 3.123/5.090 | 1.803/6.479 | 6.479 | 0.000 |
| b | transactions | 1 | 365 | 1.099/2.499 | 3.287/4.509 | 4.851/8.979 | 8.979 | 0.000 |
| b | transactions | 2 | 339 | 1.185/2.519 | 3.382/4.475 | 4.317/8.330 | 8.330 | 0.000 |
| b | transactions | 3 | 343 | 1.144/2.543 | 3.311/4.466 | 4.636/8.857 | 8.857 | 0.000 |
| b | transaction_dialog | 1 | 100 | 1.511/3.696 | 4.870/12.835 | 14.650/20.758 | 20.758 | 4.000 |
| b | transaction_dialog | 2 | 100 | 1.595/2.719 | 5.933/17.746 | 14.066/22.125 | 22.125 | 8.000 |
| b | transaction_dialog | 3 | 99 | 1.480/2.608 | 4.896/9.784 | 14.804/14.583 | 14.804 | 0.000 |

## B versus A: positive means improvement

Repetitions are paired by index. Deltas use unrounded numbers; a printed rounded 15.000% is not sufficient to pass. Require the same metric to improve by >=15% in all three repetitions. This threshold is an acceptance rule, not statistical significance.

| Screen | Run | Raster p95 improvement % | Janky-ratio improvement % |
|---|---:|---:|---:|
| dashboard | 1 | 59.051 | 100.000 |
| dashboard | 2 | 3.180 | 3.347 |
| dashboard | 3 | 40.157 | 100.000 |
| accounts | 1 | 23.890 | 92.530 |
| accounts | 2 | -137.645 | -605.238 |
| accounts | 3 | -3.934 | 100.000 |
| insights | 1 | 66.134 | 100.000 |
| insights | 2 | 62.287 | 100.000 |
| insights | 3 | 66.877 | 100.000 |
| goals | 1 | -19.475 | 100.000 |
| goals | 2 | -23.241 | 100.000 |
| goals | 3 | 36.143 | 100.000 |
| profile | 1 | 65.277 | 100.000 |
| profile | 2 | 44.325 | 100.000 |
| profile | 3 | 37.199 | 100.000 |
| transactions | 1 | 18.212 | 100.000 |
| transactions | 2 | 54.821 | 100.000 |
| transactions | 3 | 58.850 | 100.000 |
| transaction_dialog | 1 | 48.242 | 84.571 |
| transaction_dialog | 2 | 39.382 | 70.545 |
| transaction_dialog | 3 | 71.105 | 100.000 |

```text
PHASE: 1 - phase1-renderer (dashboard)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.522/1.261, 0.675/1.488, 0.703/2.338; raster p50/p95 4.527/14.010, 4.415/13.335, 4.848/15.955; janky 3.488, 2.365, 4.643%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.695/1.369, 0.877/3.320, 0.717/1.858; raster p50/p95 3.569/5.737, 5.650/12.911, 4.876/9.548; janky 0.000, 2.286, 0.000% (3 captures)
DELTA: raster p95 improvement 59.051, 3.180, 40.157%; janky improvement 100.000, 3.347, 100.000%
DECISION: revert: numeric threshold not met
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-dashboard-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (accounts)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.694/1.812, 0.726/1.854, 0.717/1.846; raster p50/p95 15.984/17.501, 3.716/7.770, 4.201/6.507; janky 28.363, 1.133, 0.688%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 1.439/6.154, 1.123/4.685, 0.769/2.262; raster p50/p95 5.249/13.320, 5.985/18.465, 3.392/6.763; janky 2.119, 7.991, 0.000% (3 captures)
DELTA: raster p95 improvement 23.890, -137.645, -3.934%; janky improvement 92.530, -605.238, 100.000%
DECISION: revert: numeric threshold not met
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-accounts-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (insights)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.701/1.850, 0.707/2.085, 0.632/2.021; raster p50/p95 4.724/16.450, 4.402/13.998, 4.308/15.663; janky 4.983, 3.679, 3.780%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.685/2.089, 0.680/2.051, 0.715/1.774; raster p50/p95 3.183/5.571, 3.179/5.279, 3.165/5.188; janky 0.000, 0.000, 0.000% (3 captures)
DELTA: raster p95 improvement 66.134, 62.287, 66.877%; janky improvement 100.000, 100.000, 100.000%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-insights-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (goals)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.734/1.050, 0.732/1.044, 0.743/1.133; raster p50/p95 3.646/4.837, 3.598/4.591, 3.875/8.956; janky 0.267, 0.267, 0.533%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.721/0.988, 0.726/0.976, 0.733/0.978; raster p50/p95 3.139/5.779, 3.214/5.658, 3.279/5.719; janky 0.000, 0.000, 0.000% (3 captures)
DELTA: raster p95 improvement -19.475, -23.241, 36.143%; janky improvement 100.000, 100.000, 100.000%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-goals-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (profile)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 0.556/1.135, 0.758/1.729, 0.639/1.383; raster p50/p95 3.938/15.324, 4.545/9.171, 4.085/8.105; janky 3.557, 0.548, 1.449%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 0.641/1.256, 0.728/1.264, 0.558/1.127; raster p50/p95 3.121/5.321, 3.218/5.106, 3.123/5.090; janky 0.000, 0.000, 0.000% (3 captures)
DELTA: raster p95 improvement 65.277, 44.325, 37.199%; janky improvement 100.000, 100.000, 100.000%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-profile-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (transactions)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 1.325/2.629, 1.246/2.692, 1.259/2.686; raster p50/p95 3.771/5.513, 3.936/9.905, 3.921/10.853; janky 0.234, 1.093, 1.475%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 1.099/2.499, 1.185/2.519, 1.144/2.543; raster p50/p95 3.287/4.509, 3.382/4.475, 3.311/4.466; janky 0.000, 0.000, 0.000% (3 captures)
DELTA: raster p95 improvement 18.212, 54.821, 58.850%; janky improvement 100.000, 100.000, 100.000%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-transactions-60hz.json; source/configuration metadata; validation logs.
```

```text
PHASE: 1 - phase1-renderer (transaction_dialog)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE A: build p50/p95 1.535/3.617, 1.321/3.064, 1.669/3.420; raster p50/p95 8.614/24.798, 5.532/29.275, 13.472/33.861; janky 25.926, 27.160, 28.571%
CHANGE: One isolated configuration change; see configuration metadata/source patch.
RESULT B: build p50/p95 1.511/3.696, 1.595/2.719, 1.480/2.608; raster p50/p95 4.870/12.835, 5.933/17.746, 4.896/9.784; janky 4.000, 8.000, 0.000% (3 captures)
DELTA: raster p95 improvement 48.242, 39.382, 71.105%; janky improvement 84.571, 70.545, 100.000%
DECISION: numeric threshold met; final adoption and permissions recorded below
RISK: Run-to-run variation; sequential configuration order; warm-state/thermal metadata and raw frames retained. No 120 Hz inference.
FILES: phase1-renderer-{a,b}-transaction_dialog-60hz.json; source/configuration metadata; validation logs.
```

## Configuration, interpretation and final comparison decision

A and B use the exact same prebuilt profile APK, compiled from source commit 09ade47 (Transactions-only row selection). APK hashes are recorded in the metadata and verified against the installed binary. The working-tree row change was later reverted after its gain did not replicate; that does not mutate the installed benchmark APK. These renderer numbers therefore apply to the documented fixed experimental binary, not a claimed remeasurement of the restored row policy. Other than the launch renderer flag, both launches use --profile --no-pub --no-resident --no-dds and the same gesture/capture client. No native project configuration was changed for the comparison.

The first DDS-enabled launch yielded two failed raw-VM WebSocket connections and zero captures. Both measured launches disable DDS. See phase1-renderer-launch-diagnostic.json. A logcat reports Impeller Vulkan/OpenGLES initialization; B logcat explicitly acknowledges Impeller opt-out and the read-only built-in engine extension ext.ui.window.impellerEnabled returns false. Software rendering was not requested. Local pinned-engine source selects Skia OpenGLES in that configuration; the opt-out was not silently ignored. See phase1-renderer-b-engine.json and phase1-renderer-engine-selection-source.txt. The engine warns that the opt-out is deprecated and may go away in a future Flutter release; do not treat it as a permanent cross-version guarantee.

**Numeric outcome:** Insights, Goals, Profile, Transactions and the transaction dialog qualify via raster p95 or janky ratio in all three repetitions. Dashboard and Accounts do not. Goals qualifies through removal of only 1/1/2 janky frames, while its raster p95 worsens in two runs; report this tradeoff rather than claiming every metric improved. Profile/Insights/Transactions have zero janky frames in all three Skia captures. Dashboard and Accounts retain profile-mode UI/raster spikes; no trace was collected to attribute those individual spikes to shaders, DVFS, GC or a particular widget.

**Owner feedback:** after all captures finished, the owner tried Skia at 60 Hz and answered "Clearly better overall". This satisfies the mission's subjective acceptance alternative for considering a renderer switch; it does not erase the mixed numeric results. A permanent switch is native Android configuration and requires the owner's separate approval. A concrete proposal is in phase1-renderer-proposed-native.patch.txt; it is not applied at this comparison stage.

**Residual risk:** transaction-dialog Skia jank is still 4 / 8 / 0%, despite improving from 25.926 / 27.160 / 28.571%. The full performance gate is not met in every flow. Captures are protocol-warmed; shader-compilation timelines were not collected, so cache-completeness and the cause of transient spikes are unproven. Sequential configuration order and low janky-frame counts limit confidence. No 120 Hz or release-mode performance benchmark was taken.

Dialog preparation was held consistent: return from Transactions to Dashboard at the Recent Transactions scroll position, then open/focus Description/dismiss through the barrier. No text or financial save is submitted. Flutter timings measure the app surface, not SwiftKey's separate process. Promo redemption stays debug-only and was not enabled in profile.

Final source validation after reverting the row experiment: 251 tests passed; analysis clean; structural fixtures show the original 2/2/2 row-boundary ancestry. Four capture-math tests passed. Every one of these 42 profile captures was recomputed exactly from raw frames. Neither the row experiment nor this comparison establishes a permanent elimination of the full symptom. The renderer choice is a measured contributor in several flows; the stronger root-cause statement remains unproven.

Primary references: https://docs.flutter.dev/perf/impeller ; local engine revision and API-selection/query excerpts are archived. The final adoption/restoration status is appended after the native-configuration decision.
