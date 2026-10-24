# Scroll-physics A/B — 24 October 2026

Device: Redmi Note 13 (23129RAA4G), Tally 1.8.22+32, AOT profile, native-verified 60.0000024 Hz (16.666666 ms budget). Each configuration uses the same capture client, one warm sequence, then 3 repetitions of four slow drags and two flings. No average FPS is used.

A: source 0819b92, forced BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()). B: same runtime source except removal of the app-wide getScrollPhysics override. Drag devices and explicit widget-level physics are unchanged. Only Dashboard, Accounts and Insights are benchmarked in this experiment; do not extrapolate to other screens or dialog performance.

Initial A baseline showed an offline banner before capture. B showed no banner before and after capture. Initial A/B results below are retained as observations and are not a strict matched-state causal comparison. A return-to-baseline capture is planned to check the result with the banner absent.

## Initial A and B observations

| Variant | Screen | Run | Frames | Build p50 / p95 ms | Raster p50 / p95 ms | Worst build / raster ms | Worst stage ms | Janky % |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| a | dashboard | 1 | 307 | 0.606 / 1.144 | 5.785 / 12.014 | 4.326 / 29.916 | 29.916 | 2.28 |
| a | dashboard | 2 | 293 | 0.573 / 1.205 | 4.351 / 14.444 | 4.086 / 23.882 | 23.882 | 3.072 |
| a | dashboard | 3 | 326 | 0.572 / 1.988 | 4.129 / 9.606 | 3.347 / 19.295 | 19.295 | 0.613 |
| a | accounts | 1 | 354 | 0.659 / 1.636 | 4.107 / 12.379 | 4.038 / 24.666 | 24.666 | 2.542 |
| a | accounts | 2 | 340 | 0.631 / 1.657 | 4.045 / 11.898 | 3.952 / 24.29 | 24.29 | 2.059 |
| a | accounts | 3 | 340 | 0.631 / 1.664 | 4.083 / 13.492 | 4.405 / 24.761 | 24.761 | 2.941 |
| a | insights | 1 | 294 | 0.595 / 1.8 | 4.297 / 15.617 | 3.662 / 24.107 | 24.107 | 3.741 |
| a | insights | 2 | 305 | 0.647 / 1.667 | 4.334 / 13.132 | 3.387 / 29.565 | 29.565 | 2.951 |
| a | insights | 3 | 297 | 0.605 / 2.034 | 4.426 / 16.296 | 3.333 / 23.724 | 23.724 | 4.714 |
| b | dashboard | 1 | 225 | 0.43 / 1.64 | 5.029 / 16.085 | 1.906 / 26.804 | 26.804 | 4.889 |
| b | dashboard | 2 | 236 | 0.478 / 1.77 | 4.556 / 15.837 | 4.064 / 22.631 | 22.631 | 4.237 |
| b | dashboard | 3 | 226 | 0.462 / 1.644 | 5.094 / 13.852 | 2.049 / 24.463 | 24.463 | 3.097 |
| b | accounts | 1 | 312 | 0.632 / 1.732 | 4.059 / 14.585 | 3.891 / 25.572 | 25.572 | 2.885 |
| b | accounts | 2 | 312 | 0.656 / 1.922 | 4.143 / 12.786 | 4.61 / 26.358 | 26.358 | 2.564 |
| b | accounts | 3 | 311 | 0.642 / 1.769 | 4.045 / 12.158 | 3.973 / 24.709 | 24.709 | 1.608 |
| b | insights | 1 | 251 | 0.482 / 2.081 | 4.476 / 16.521 | 2.976 / 22.348 | 22.348 | 4.781 |
| b | insights | 2 | 273 | 0.566 / 1.913 | 4.757 / 14.51 | 4.204 / 26.424 | 26.424 | 2.93 |
| b | insights | 3 | 274 | 0.513 / 1.887 | 4.46 / 16.954 | 3.461 / 23.695 | 23.695 | 5.109 |

Raw frames: phase1-physics-{a,b}-{dashboard,accounts,insights}-60hz.json. Source diff, APK hashes, focused interaction test source and validation logs are stored alongside this report. Thermal status was 0 throughout these captures; battery temperatures are retained in each raw capture.

Variant B validation: 2 focused interaction tests passed (Android boundary clamping, iOS bounce, drag devices unchanged); all 253 full-suite tests passed; analysis clean. These are correctness checks, not frame-rate evidence.

Reference: Flutter platform physics defaults, https://api.flutter.dev/flutter/widgets/ScrollBehavior/getScrollPhysics.html ; also checked against local Flutter 3.41.3 source packages/flutter/lib/src/widgets/scroll_configuration.dart.

## Owner feedback and comparison limits

The owner reported: "only on 60hz it feels okay". This is recorded as refresh-rate feedback, not confirmation that B is clearly better than A at the same 60 Hz. No 120 Hz frame capture was taken in this experiment. Do not reinterpret the 60 Hz measurements as 120 Hz results. The tighter 8.33 ms budget is a comparison threshold, not a measured 120 Hz outcome.

The return A process was launched while the panel was at 120 Hz, then OEM Standard 60 Hz was selected before capturing. Flutter's cached Display.refreshRate remained 120 in return A, while the native surface period and vsync-start intervals confirmed 60 Hz. Raw data preserve both readings. All jank calculations use the native surface rate; there are no mixed-native-rate comparisons. No native display-policy code was changed.

## Return A: matched-state baseline

Dashboard had no offline banner before capture; Insights had no banner after the final capture, matching the corresponding B visual checks. Intermediate banner transitions were not independently logged. The same capture script warms each route and performs three identical gesture sequences. Return A was installed from the same saved original profile APK; its SHA256 matches A.

| Screen | Run | Frames | Build p50 / p95 ms | Raster p50 / p95 ms | Worst build / raster ms | Worst stage ms | Janky % |
|---|---:|---:|---:|---:|---:|---:|---:|
| dashboard | 1 | 258 | 0.493 / 1.275 | 4.526 / 15.872 | 4.484 / 23.669 | 23.669 | 4.651 |
| dashboard | 2 | 257 | 0.483 / 1.105 | 4.312 / 17.448 | 4.128 / 25.875 | 25.875 | 6.615 |
| dashboard | 3 | 259 | 0.47 / 1.119 | 4.366 / 17.214 | 4.122 / 23.982 | 23.982 | 5.405 |
| accounts | 1 | 355 | 0.645 / 1.673 | 4.055 / 12.045 | 3.851 / 23.615 | 23.615 | 1.127 |
| accounts | 2 | 354 | 0.677 / 1.778 | 4.098 / 7.142 | 4.065 / 23.099 | 23.099 | 1.412 |
| accounts | 3 | 382 | 0.71 / 1.726 | 4.107 / 5.392 | 3.98 / 22.662 | 22.662 | 0.785 |
| insights | 1 | 296 | 0.601 / 1.694 | 4.253 / 14.71 | 2.969 / 22.508 | 22.508 | 4.054 |
| insights | 2 | 281 | 0.574 / 1.745 | 4.22 / 16.548 | 3.787 / 23.274 | 23.274 | 4.626 |
| insights | 3 | 307 | 0.722 / 1.805 | 4.283 / 15.232 | 3.909 / 22.99 | 22.99 | 4.235 |

## Per-run changes: B versus return A

Positive values mean improvement, negative values mean regression. Each run is paired by repetition index; this is not a statistical confidence interval or an average-FPS comparison. A consistent same-metric improvement of at least 15% in all three repetitions is required.

| Screen | Run | Raster p95 improvement % | Janky-ratio improvement % |
|---|---:|---:|---:|
| dashboard | 1 | -1.342 | -5.111 |
| dashboard | 2 | 9.233 | 35.942 |
| dashboard | 3 | 19.531 | 42.699 |
| accounts | 1 | -21.088 | -156.01 |
| accounts | 2 | -79.025 | -81.538 |
| accounts | 3 | -125.482 | -104.716 |
| insights | 1 | -12.311 | -17.928 |
| insights | 2 | 12.316 | 36.658 |
| insights | 3 | -11.305 | -20.663 |

## Phase report format

```text
PHASE: 1 H2 - Scroll physics (dashboard)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE (return A): build p50/p95 0.493/1.275, 0.483/1.105, 0.47/1.119; raster p50/p95 4.526/15.872, 4.312/17.448, 4.366/17.214; janky 4.651, 6.615, 5.405%
CHANGE: Remove only app-wide forced-bounce override; keep drag devices and explicit widget physics.
RESULT (B): build p50/p95 0.43/1.64, 0.478/1.77, 0.462/1.644; raster p50/p95 5.029/16.085, 4.556/15.837, 5.094/13.852; janky 4.889, 4.237, 3.097% (3 captures)
DELTA: raster p95 improvement -1.342, 9.233, 19.531%; janky-ratio improvement -5.111, 35.942, 42.699%
DECISION: revert - no consistent >=15% improvement, no explicit same-rate owner feel confirmation.
RISK: Edge motion changes; B interaction tests cover Android clamping, iOS bounce and unchanged drag devices. Those variant tests are archived after reversion.
FILES: Temporary lib/main.dart edit and variant test reverted; documentation and raw evidence retained.
```

```text
PHASE: 1 H2 - Scroll physics (accounts)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE (return A): build p50/p95 0.645/1.673, 0.677/1.778, 0.71/1.726; raster p50/p95 4.055/12.045, 4.098/7.142, 4.107/5.392; janky 1.127, 1.412, 0.785%
CHANGE: Remove only app-wide forced-bounce override; keep drag devices and explicit widget physics.
RESULT (B): build p50/p95 0.632/1.732, 0.656/1.922, 0.642/1.769; raster p50/p95 4.059/14.585, 4.143/12.786, 4.045/12.158; janky 2.885, 2.564, 1.608% (3 captures)
DELTA: raster p95 improvement -21.088, -79.025, -125.482%; janky-ratio improvement -156.01, -81.538, -104.716%
DECISION: revert - no consistent >=15% improvement, no explicit same-rate owner feel confirmation.
RISK: Edge motion changes; B interaction tests cover Android clamping, iOS bounce and unchanged drag devices. Those variant tests are archived after reversion.
FILES: Temporary lib/main.dart edit and variant test reverted; documentation and raw evidence retained.
```

```text
PHASE: 1 H2 - Scroll physics (insights)
DEVICE: Redmi Note 13 23129RAA4G | APP: 1.8.22+32 profile | REFRESH: 60 Hz native
BASELINE (return A): build p50/p95 0.601/1.694, 0.574/1.745, 0.722/1.805; raster p50/p95 4.253/14.71, 4.22/16.548, 4.283/15.232; janky 4.054, 4.626, 4.235%
CHANGE: Remove only app-wide forced-bounce override; keep drag devices and explicit widget physics.
RESULT (B): build p50/p95 0.482/2.081, 0.566/1.913, 0.513/1.887; raster p50/p95 4.476/16.521, 4.757/14.51, 4.46/16.954; janky 4.781, 2.930, 5.109% (3 captures)
DELTA: raster p95 improvement -12.311, 12.316, -11.305%; janky-ratio improvement -17.928, 36.658, -20.663%
DECISION: revert - no consistent >=15% improvement, no explicit same-rate owner feel confirmation.
RISK: Edge motion changes; B interaction tests cover Android clamping, iOS bounce and unchanged drag devices. Those variant tests are archived after reversion.
FILES: Temporary lib/main.dart edit and variant test reverted; documentation and raw evidence retained.
```

## Final status

Original source and original profile variant restored. Restored analysis is clean and all 251 Flutter tests pass. Experimental B passed 253 tests with clean analysis. The owner feedback is preserved above without claiming that the symptom is fixed.
The OEM Maximum 120 Hz preference was restored and verified at 120.00001 Hz after capture; see phase1-physics-phone-restored.json. This restoration is not a 120 Hz performance benchmark.
Next recommended isolated tests: list-row RepaintBoundary removal, then alive-tab and renderer experiments under the mission approvals. H2 remains unproven as a motion-perception explanation; this experiment rejects shipping it as a measured frame-timing fix.
No production rendering change is retained by this phase. The capture script invoked no financial save or sync upload/restore action; conflict prompts were dismissed with Keep Using Offline Only. Phase commits remain local pending push approval.
