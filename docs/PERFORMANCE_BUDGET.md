# Performance budget and root-cause investigation

## 24 October 2026 — Phase 0: profile control experiment

**Status: Phase 0 completed; no rendering refactor or Phase 1 optimization adopted.** Source/app version: **Tally 1.8.22+32**, baseline Git **52ae233**. Device: **Redmi Note 13 (23129RAA4G), 1080×2400**. All table measurements below are **AOT profile**, at native SurfaceFlinger-verified **60.0000024 Hz** (budget **16.666666 ms**). The owner explicitly approved local profile APK builds/installation and temporary 60 Hz operation. No store signing, publishing, Firebase deployment, version bump, schema change, entitlement change or ledger change was made for this experiment.

### Blocking decision

Probe B raster p50 in its three captures: **3.620 / 3.679 / 3.930 ms**. All fall in **3.5–6 ms**, so the requested decision is **marginal device → Phase 1, including renderer A/B, then Phase 3**. The ≥6 ms branch is not selected. A universal ≥6 ms rendering floor is not established. Probe A p50 was **4.924 / 4.999 / 5.165 ms**; list p50 was lower, so these controls do not support treating every screen's raster cost as an invariant fixed floor.

Tally's build p95 is much smaller than its raster tail on this baseline. This supports investigating raster/motion behavior next; it does not identify shadows, layers, renderer or scroll physics as the cause without their isolated A/B experiments. No average FPS is used.

### Three-capture matrix

All times are milliseconds. Worst frame = `max(build, raster)`; total-span latency is retained separately in raw JSON. Jank = fraction with `max(buildMs, rasterMs) > 1000 / nativeSurfaceHz`. Percentiles use nearest rank. Every screen uses four alternating 600 ms drags and two alternating 100 ms flings, after one identical warm pass. Static control requests continuous vsync with an unchanged retained scene, because an idle static screen otherwise produces no steady-state frame sample. It does not animate or mutate widgets/layout/paint.

| Screen | Run | Frames | Build p50 / p95 | Raster p50 / p95 | Worst build / raster | Worst frame | Janky |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Probe A static | 1 | 523 | 0.290 / 0.404 | 4.924 / 6.710 | 2.741 / 9.877 | 9.877 | 0.000% |
| Probe A static | 2 | 526 | 0.284 / 0.388 | 4.999 / 7.123 | 1.370 / 13.859 | 13.859 | 0.000% |
| Probe A static | 3 | 522 | 0.292 / 0.428 | 5.165 / 7.191 | 1.369 / 19.189 | 19.189 | 0.192% |
| Probe B list | 1 | 395 | 0.615 / 1.635 | 3.620 / 7.208 | 4.120 / 15.833 | 15.833 | 0.000% |
| Probe B list | 2 | 371 | 0.613 / 1.527 | 3.679 / 8.031 | 2.012 / 16.442 | 16.442 | 0.000% |
| Probe B list | 3 | 376 | 0.580 / 1.503 | 3.930 / 7.991 | 2.813 / 17.106 | 17.106 | 0.266% |
| Dashboard | 1 | 257 | 0.506 / 1.289 | 4.543 / 14.723 | 4.384 / 23.274 | 23.274 | 3.891% |
| Dashboard | 2 | 295 | 0.596 / 1.288 | 4.619 / 17.009 | 4.083 / 24.244 | 24.244 | 8.136% |
| Dashboard | 3 | 269 | 0.591 / 1.335 | 4.588 / 15.376 | 4.592 / 22.895 | 22.895 | 4.461% |
| Accounts | 1 | 445 | 0.695 / 2.034 | 5.051 / 9.196 | 5.429 / 20.648 | 20.648 | 0.674% |
| Accounts | 2 | 445 | 0.681 / 1.831 | 4.110 / 5.569 | 5.335 / 16.778 | 16.778 | 0.225% |
| Accounts | 3 | 354 | 0.695 / 1.783 | 4.123 / 11.681 | 5.458 / 23.380 | 23.380 | 1.130% |
| Insights | 1 | 314 | 0.663 / 1.830 | 4.257 / 13.313 | 3.644 / 22.491 | 22.491 | 2.866% |
| Insights | 2 | 317 | 0.631 / 2.023 | 4.212 / 13.719 | 3.098 / 22.388 | 22.388 | 2.839% |
| Insights | 3 | 305 | 0.651 / 1.810 | 4.244 / 14.055 | 8.463 / 22.333 | 22.333 | 2.623% |
| Goals | 1 | 373 | 0.658 / 1.098 | 5.461 / 7.208 | 2.434 / 17.284 | 17.284 | 0.268% |
| Goals | 2 | 374 | 0.679 / 0.995 | 3.664 / 4.528 | 1.679 / 10.175 | 10.175 | 0.000% |
| Goals | 3 | 373 | 0.636 / 0.930 | 3.656 / 4.788 | 1.719 / 16.468 | 16.468 | 0.000% |
| Profile | 1 | 265 | 0.574 / 1.064 | 4.026 / 14.898 | 1.677 / 24.432 | 24.432 | 3.019% |
| Profile | 2 | 267 | 0.610 / 0.951 | 4.028 / 13.889 | 1.889 / 22.792 | 22.792 | 2.247% |
| Profile | 3 | 264 | 0.567 / 1.076 | 4.004 / 14.744 | 1.625 / 21.181 | 21.181 | 3.030% |
| Transactions | 1 | 336 | 0.646 / 1.803 | 3.936 / 10.259 | 3.985 / 21.668 | 21.668 | 1.190% |
| Transactions | 2 | 379 | 0.703 / 1.736 | 3.836 / 5.302 | 3.499 / 19.848 | 19.848 | 0.528% |
| Transactions | 3 | 490 | 0.678 / 1.782 | 4.017 / 5.898 | 3.939 / 22.707 | 22.707 | 0.612% |

### Reproduction and measurement safeguards

- Probe project: OS temporary directory `tally_floor_probe_20261024`, generated with `flutter create --empty --platforms android --project-name floor_probe --org com.tallyperf --no-pub`. Its installed version is **0.1.0+1**. Runtime/native package metadata in each capture is authoritative; the helper's human label is not used as a package version.
- Toolchain: Flutter **3.41.3 / Dart 3.11.1**; JDK **21** on this host. No runtime dependencies were added. Probe dependencies were resolved offline.
- Both applications use the same measurement-only `SchedulerBinding.addTimingsCallback` helper. Tally's temporary entry point imports the ordinary `main.dart`; it does not edit rendering. The helper throws outside `kProfileMode`. Android's DEBUGGABLE flag alone is insufficient: Flutter 3.41's Gradle profile build type uses `initWith(debug)`; profile/AOT is checked at the Dart entry point and through the profile build logs.
- The probe started at 120 Hz, then the owner-authorized system setting changed to 60 Hz. Flutter's cached display property remained 120 Hz in the probe, while Android's active display, SurfaceFlinger period and consecutive vsync timestamps corroborated 60 Hz. Tally, started after the switch, reported 60 Hz. Raw captures preserve both readings; jank uses the native surface rate, not the stale Flutter property. A watchdog using only that cached property would misclassify this experiment.
- The standard Android preference commands did not initially switch the OEM display. Selecting **Standard 60 Hz** in the phone's own Display settings did. Native rate is sampled before and after every capture; mixed-rate captures are rejected. Original mode was Maximum 120 Hz, with peak setting 120, no min override and no explicit per-display preferred mode. Restore those after the session.
- Renderer startup logs report Impeller initialization for Vulkan and OpenGLES. These lines do not by themselves prove an isolated renderer A/B result. No renderer switch has been tested/adopted yet.
- Raw tuple columns: frame number, vsyncStart microseconds, build microseconds, raster microseconds, total-span microseconds, Flutter-reported display Hz. No account contents, VM authentication URI, screenshot or APK is committed. Battery temperature/thermal status are recorded per capture.

Commands (the owner has authorized these local profile builds):

```powershell
# From the temporary probe project:
flutter pub get --offline
flutter build apk --profile --no-pub --target-platform android-arm64
# From Tally; target is the temporary measurement-only entry point:
flutter build apk --profile --no-pub --target-platform android-arm64 -t <temp>/tally_profile_entry.dart
adb install -r <profile-apk>
adb shell am start -n <package>/.MainActivity
node scripts/capture_profile_frames.mjs <package> <route> docs/audit-evidence/<capture>.json 60
node --test scripts/frame_capture_stats.test.mjs
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

The capture client discovers the active process's private VM URI in memory and removes its temporary ADB forward afterward. It enforces profile mode, takes three repetitions, records raw FrameTimings and metadata, and computes the refresh-specific summaries. Probe source and the measurement entry point are archived as `.dart.txt` evidence for reproduction. No production rendering code was changed in Phase 0.

### Evidence and baseline gates

- [Probe A static: all three raw captures](audit-evidence/phase0-probe-static-60hz.json)
- [Probe B list: all three raw captures](audit-evidence/phase0-probe-list-60hz.json)
- [Dashboard: all three raw captures](audit-evidence/phase0-tally-dashboard-60hz.json)
- [Accounts: all three raw captures](audit-evidence/phase0-tally-accounts-60hz.json)
- [Insights: all three raw captures](audit-evidence/phase0-tally-insights-60hz.json)
- [Goals: all three raw captures](audit-evidence/phase0-tally-goals-60hz.json)
- [Profile: all three raw captures](audit-evidence/phase0-tally-profile-60hz.json)
- [Transactions: all three raw captures](audit-evidence/phase0-tally-transactions-60hz.json)
- [Machine-readable Phase 0 decision](audit-evidence/phase0-decision.json)
- [Probe source](audit-evidence/phase0-probe-main.dart.txt), [FrameTiming helper](audit-evidence/phase0-frame-capture.dart.txt), [Tally entry point](audit-evidence/phase0-tally-entry.dart.txt)
- [Probe profile build](audit-evidence/phase0-probe-build.txt), [Tally profile build](audit-evidence/phase0-tally-build.txt), [APK hashes](audit-evidence/phase0-build-hashes.json)
- **249/249 baseline Flutter tests passed**: [log](audit-evidence/phase0-repo-tests.txt)
- **Static analysis clean**: [log](audit-evidence/phase0-repo-analysis.txt)
- **4 capture-math tests passed**: [log](audit-evidence/phase0-capture-tests.txt). Covers quantiles, stage-max jank, measured budgets, stale display metadata and invalid/mixed samples.

The proposed Phase 4 thresholds (raster p95 ≤6 ms, build p95 ≤4 ms, janky ratio ≤1%) are **not met by the baseline on every screen**. They have not been relaxed. The integration gate, watchdog, adaptive tiers and SurfaceCard migrations are **not implemented yet**; they must follow the phase order and applicable owner approvals. These control samples do not prove overlay/DevTools agreement or performance at 120 Hz.

### Ribbon movement report (separate correctness issue)

The owner reported sudden horizontal ribbon movement on Accounts and Insights. A phone-width diagnostic reproduced both ribbons resetting from **150 px to 0 px** after their lazy header was evicted by vertical scrolling and recreated. Both unkeyed horizontal lists share the enclosing vertical PageStorage-key hierarchy. The diagnostic intentionally fails its preservation assertion; it is kept outside the default test suite and its source/log are archived, not reported as a passing regression. No evidence yet shows that the selected account or report tab itself changes.

The owner approved assigning independent storage keys. This correctness repair will be applied after the Phase 0 baseline commit and verified before/after, separately from raster optimization. Evidence: [diagnostic log](audit-evidence/phase0-ribbon-diagnostic.txt), [diagnostic source](audit-evidence/phase0-ribbon-probe-test.dart.txt).
