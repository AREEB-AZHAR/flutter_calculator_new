# 26 October 2026 — Release-ad stutter investigation

## Outcome and scope

Stutter is reproduced in AOT profile with release entitlement policy and native Google test banners present. The experiments do **not** establish a production fix. Neither native refresh candidate is adopted; temporary ad instrumentation is removed from production source. The exact original release APK is restored using `install -r`, without clearing data. No release APK was built and no changes were pushed.

Device: Redmi Note 13 (23129RAA4G), Android 15, 1080 × 2400, Adreno 610. Tally 1.8.22+32, Flutter 3.41.3 / Dart 3.11.1, AOT profile. Installed release inspection is separate from profile timing evidence. [Original inspection](release-ads-installed-baseline.json), [restoration and APK hash](release-ads-restoration.json).

## Method and reproducibility

Each configuration has three captures after warming: four alternating 600 ms drags and two alternating 100 ms flings, followed by settling. Native surface period and panel refresh are recorded before and after each capture. Build and raster are separate; a frame is over budget when `max(build, raster)` exceeds 16.67 ms at 60 Hz or 8.33 ms at 120 Hz. No average FPS is used. Raw frames, counts, percentiles, worst stages and temperature/status are retained in each JSON.

[Complete inventory of every repetition](release-ads-capture-inventory.md). The inventory includes the build/raster p50/p95, worst build/raster, over-budget count and ratio, refresh, cadence and thermal state. Do not pool refresh rates or thermally different runs.

The same profile ad A/B APK is used for the primary native/placeholder captures: SHA256 `5dc396211e4860bbf81f579366fde6d23e754e8a3258aa77c41f3a4b0d7a0703`. The placeholder removes only AdWidget views, retains loaded SDK banner objects, entitlement state and outer layout, and does not click ads. This tests native-view composition cost, not all SDK activity or network work. Profile explicitly disables development entitlement grants; every capture records `adFree=false`. Direct benchmark route selection bypasses navigation interstitials; tab-transition ad behavior is not measured.

Archived diagnostics are text, not shipped entry points: [profile entry](release-ads-capture_main.dart.txt), [timing collector](release-ads-perf_capture.dart.txt), [ad capture runner](release-ads-capture_ad_view_ab.mjs.txt), [temporary ad patch](release-ads-proposed-profile-view-ab.patch.txt). To reproduce, reconstruct the ignored `build/perf-private/` sources, apply only the temporary ad patch, build that entry in profile with the pinned SDK, install with `adb install -r -t`, launch with profiling enabled, authenticate directly, and run:

```powershell
node build/perf-private/capture_ad_view_ab.mjs com.areeb.balance_tracker dashboard docs/audit-evidence/new-native-dashboard-120hz.json 120 native
node build/perf-private/capture_ad_view_ab.mjs com.areeb.balance_tracker dashboard docs/audit-evidence/new-placeholder-dashboard-120hz.json 120 placeholder
```

Use native-verified refresh and thermal status 0 for acceptance. Verify the actual engine using `ext.ui.window.impellerEnabled`, not Android HWUI's renderer label. Revert all temporary source patches afterward. SDK paths, JDK 21 and device setup remain documented in the developer setup and USB guide.

## Phase: ad-view isolation — no permanent ad change

All following primary captures have thermal status 0. Values are raster p95 milliseconds for runs 1/2/3 at actual 120 Hz, profile:

| Flow | Native view | Placeholder | Decision |
|---|---|---|---|
| Dashboard | 13.251 / 13.660 / 13.521 | 10.448 / 10.584 / 10.559 | Native view adds cost; neither meets budget |
| Accounts | 12.743 / 12.638 / 12.872 | 10.075 / 10.040 / 10.063 | Native view adds cost; neither meets budget |
| Insights | 8.573 / 8.602 / 8.617 | 8.619 / 8.631 / 8.615 | No consistent gain |
| Goals | 13.774 / 12.897 / 13.345 | 9.983 / 9.885 / 9.980 | Native view adds cost; neither meets budget |
| Profile | 9.620 / 9.658 / 9.791 | 9.540 / 9.826 / 9.727 | No consistent gain |
| Transaction dialog | 21.764 / 20.338 / 20.523 | 20.056 / 21.594 / 21.376 | No consistent gain |

Dashboard native jank is 80.460 / 80.769 / 85.632%; placeholder is 97.991 / 98.420 / 98.354%. Removal changes the captured-frame population and eliminates many native-window frames; lower raster p95 cannot be described as an overall smoothness fix. Accounts/Goals likewise remain substantially over budget. Native banner views are a contributor on some screens, not a sufficient explanation for every screen.

At physical 60 Hz with native banners, Accounts raster p95 is 5.949 / 6.845 / 6.526 ms and Insights 5.507 / 5.395 / 5.540 ms. Dashboard remains inconsistent (18.039 / 8.207 / 8.441 ms), and the dialog remains slow (23.451 / 30.665 / 29.768 ms). This is a refresh configuration comparison, not proof of an adopted optimization. All rows and return-to-baseline runs remain in the inventory.

## Phase: renderer control — promising, thermally limited

The standalone probe has no ad platform views. Its arm64 engine SHA256 matches Tally's profile engine: `d42cfe4e7f60cfad84dd3db00661e7d99db4caa2162621d14d65ba3b4448b9b7`.

At physical 120 Hz, probe list raster p50 is 8.538 / 8.522 / 8.598 ms with default Impeller, versus 2.569 / 2.598 / 2.572 ms with verified Skia. Raster p95 is 10.065 / 9.929 / 10.036 versus 4.177 / 4.283 / 4.597 ms. Static Impeller p50 is 2.294 / 2.286 / 2.297 ms. The nominal Phase 0 branch is list ≥6 ms and static ≤3 ms: list painting/rendering cost, rather than a universal static engine floor or scroll physics alone. **All these later probe runs have thermal status 3 (severe)**. They are diagnostic observations, not clean adoption evidence; repeat the renderer pair at thermal 0 before accepting a new engine/default. Do not conclude the physical GPU can never support 120 Hz from the Impeller list result.

Flutter's [Adreno 610 GLES state-cost issue](https://github.com/flutter/flutter/issues/192147) and [merged GLES state-deduplication fix](https://github.com/flutter/flutter/pull/193427) describe a plausible mechanism consistent with this renderer difference. This is an inference, not a CPU-trace diagnosis of Tally. The fix merged to master on 2 October 2026; inclusion in a stable SDK has **not** been verified. Do not blindly upgrade dependencies or globally disable Impeller. Test a separate SDK containing the upstream fix, verify commit ancestry, then repeat the probe and actual ad-bearing screens before considering an all-user toolchain change.

## Phase: native refresh controls — revert both candidates

The owner approved testing mode-ID requests. Candidate 1 requests the nearest supported same-resolution display mode plus the existing rate hint; System/unsupported clears both. Window attributes confirm the requested 60 Hz mode ID, but the panel/surface remains 120 Hz. Candidate 2 additionally disables Android 15 touch boost only for explicit accepted 60 Hz requests. [Android's API documentation](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#setFrameRateBoostOnTouchEnabled(boolean)) confirms API 35 availability; earlier Android versions are guarded.

```text
PHASE: native refresh-control experiment
DEVICE: Redmi Note 13 | APP: 1.8.22+32 profile | REFRESH: 120 Hz surface
BASELINE: app60 hint raster p95 13.458 / 13.462 / 13.503 ms
CHANGE: add mode ID; then separately disable touch boost for explicit 60
RESULT: mode-ID raster p95 13.396 / 13.765 / 13.940 ms
RESULT: touch-boost raster p95 13.996 / 13.411 / 13.477 ms
DELTA: no consistent >=15% raster-p95 improvement; all runs thermal 3
DECISION: revert both; no accepted refresh fix
RISK: OEM policy remains in control; hot captures cannot certify smoothness
FILES: temporary MainActivity.kt patch; archived as text, source restored
```

[System/60/120 UI and window checks](release-ads-touch-boost-controls.json) verify mode requests and boost restoration, but **all three panel readings remain 120 Hz**. Missing `frameRateBoostOnTouch=true` in the 60-Hz window dump reflects the disabled flag; System/120 restore it. Cadence must be interpreted separately from panel rate: the mode-ID capture has median sampled deltas near 16.7 ms, while touch-boost runs are near 8.36 ms. Thermal throttling and skipped frames prevent treating those deltas alone as proof of a controlled effective rate. Full metrics are in the inventory. [Mode-ID patch](release-ads-proposed-mode-pin.patch.txt), [combined touch-boost candidate](release-ads-proposed-touch-boost.patch.txt).

## Limits, next work and validation

The original release APK and 120 Hz app preference are restored, with original OEM/system settings and no global preferred-mode override. Financial screenshots, APK backups and VM connection details remain outside Git. No ledger, sync, schema, purchase, notification, icon, version or production ad logic changes are adopted.

The performance mission remains incomplete. Clean thermal-0 renderer controls, an isolated SDK containing the upstream fix, ad-bearing Tally confirmation, dialog stalls and a second device are still needed. Watchdog/tier/SurfaceCard/integration gates are not implemented by this investigation. Correctness tests cannot certify visual smoothness. See the adjacent `release-ads-analysis.txt` and `release-ads-full-tests.txt` for final-source validation; the first analysis attempt caught a measurement-entry testing-member warning and was corrected before the final run.


## Cooled renderer follow-up — supersedes the thermal limitation for this pair

After cooling, both list configurations were repeated on the same installed probe APK, **thermal status 0 before/after every capture**, native **120 Hz**, AOT profile. Engine-state queries confirm Impeller enabled for baseline and disabled for Skia. This supplies a clean renderer A/B; earlier thermal-3 observations remain archived separately.

```text
PHASE: 0 / renderer control — cooled standalone list
DEVICE: Redmi Note 13 (23129RAA4G) | APP: probe 0.1.0+1 profile | REFRESH: 120 Hz actual
BASELINE: build p50/p95 0.579/1.372, 0.584/1.361, 0.578/1.354 ms
          raster p50/p95 8.020/8.765, 7.965/9.047, 8.019/8.916 ms
          janky 27.778 / 27.842 / 28.618%
CHANGE: same APK and gesture protocol; switch verified Impeller to Skia
RESULT: build p50/p95 0.565/1.359, 0.576/1.697, 0.576/1.448 ms
        raster p50/p95 2.384/2.876, 2.411/4.980, 2.385/3.003 ms
        janky 0 / 0.469 / 0%
DELTA: raster p95 -67.188 / -44.954 / -66.319% | jank -100 / -98.314 / -100%
DECISION: renderer is a measured contributor; no global renderer override adopted
RISK: single device and simple list; full Tally/native-ad flows need confirmation
FILES: raw probe-cooled-* captures, engine checks, report and inventory
```

The probe's list p50 remains ≥6 ms under Impeller, but falls below 3 ms under Skia on the same physical device. This rules out an unavoidable hardware-only 120-Hz limit for this workload. It does not identify individual engine CPU/GPU operations or certify the upstream patch. Prefer testing a separate SDK containing that fix and confirming real app screens over a universal deprecated opt-out. No SDK change was made here.


The cooled default-renderer static control has raster p50 **2.211 / 2.277 / 2.249 ms**, p95 **2.441 / 2.909 / 2.793 ms**, with thermal status 0 throughout. Therefore the clean 120-Hz Phase 0 decision is explicitly **list ≥6 ms, static ≤3 ms → content-rendering/engine cost**, with Skia demonstrating that it is not an unavoidable device-only limit. No widget refactor is adopted under that branch.

Final validation: **306 Flutter tests passed**, **analysis has no issues**, and **four capture-math tests passed**. The measurement entry was converted back to an ignored text archive after diagnostic hooks were removed, resolving both its testing-member warning and obsolete widget references. `node scripts/report_release_ad_captures.mjs` exactly recomputes **99 captures / 54,827 raw frames**; **69 captures** have thermal 0 before/after, **30** are constrained. [Recomputation output](release-ads-capture-validation.txt).

Upstream follow-up is deliberately conservative: [merge-to-stable ancestry](release-ads-upstream-stable-ancestry.json) is diverged, and [the checked stable source](release-ads-upstream-stable-source.json) does not contain the patch's `RenderPassStateCache` name. Neither proves the absence of an equivalent cherry-pick. Release metadata lookup failed, so no stable version is asserted to include the fix. The shared SDK remains untouched; testing an isolated engine containing the verified fix remains necessary before proposing an all-user upgrade.
