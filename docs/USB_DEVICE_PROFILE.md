# USB device investigation: keyboard lag and budget crash

24 October 2026 · Source version **1.8.22+32** · Delivery branch **main**

## Plan and findings

1. Inspect the connected Redmi Note 13, confirm the installed build, and attach to its existing Dart VM without building or reinstalling an APK.
2. Test the claim that editing controls are loaded for every transaction. Inspect widget lifetimes and list builders rather than removing transaction editing speculatively.
3. Capture keyboard and scrolling frame timings, then trace widget builds separately. Isolate background tabs from keyboard-only layout changes and remove redundant dialog intrinsic layout.
4. Reproduce the budget dropdown assertion; ensure the initial selection belongs to the filtered available categories, including the empty case. Verify saving the default selection without manually changing it.
5. Add host regressions, check the live device without saving financial changes, update documentation, and commit/push to **main** as requested. No APK build.

The connected device is **Redmi Note 13 / 23129RAA4G**, running **1.8.21+31, DEBUGGABLE**. The fixes were hot-reloaded into that running process. Hot reload does not replace the installed APK: restarting the process loses the hot-reloaded patch until the owner supplies a newly built APK. The source version is now 1.8.22+32; native installed package metadata remains 1.8.21+31.

The local ledger contained **45 transactions**. `TransactionTile` stores tap/delete callbacks; `showTransactionDialog` constructs the editor on demand. Existing list builders virtualize rows. Cached tabs can retain some offscreen rows, but there was no editor per transaction. Removing edit capability would not address the demonstrated issue.

The main navigation shell retains visited tabs. Each nested `Scaffold` previously received changing keyboard insets even when its tab was hidden or a dialog covered it. One instrumented keyboard show/hide capture recorded **99 Scaffold builds** and **1,101 MediaQuery builds**. `KeyboardStablePage` now preserves bottom padding and strips the keyboard's bottom inset only inside the non-editing main-tab subtree. Editors pushed onto the root Navigator still receive the real keyboard geometry. Full size, orientation, theme and accessibility changes continue to propagate. Inline search routes outside that subtree keep their normal keyboard behavior.

`FormDialog` gives transaction, promo and add-budget forms a bounded width and flexible scrolling body with fixed actions. It avoids `AlertDialog`'s intrinsic layout pass. With keyboard isolation alone, the trace still recorded **71 RenderFlex intrinsic events**; the final capture recorded **zero** and **zero Scaffold builds** during the same kind of keyboard interaction. Narrow dropdown labels and the promo title now constrain/wrap instead of overflowing.

The budget crash came from `initialValue: categoryIcons.keys.first` combined with items filtered to exclude existing budgets. When the first category already had a budget, no dropdown item matched the initial value. It also initialized the saved selection to an empty string, so adding without changing the dropdown could silently do nothing. The code now chooses and saves the first available category, and reports an all-categories-budgeted message instead of constructing an invalid dropdown. The repaired panel was opened on the phone and cancelled without saving a budget.

References: Flutter requires [exactly one matching dropdown item](https://api.flutter.dev/flutter/material/DropdownButtonFormField/DropdownButtonFormField.html), explains [Scaffold keyboard resizing](https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html), and documents [physical-device performance profiling](https://docs.flutter.dev/perf/ui-performance). **Debug JIT timings are not release benchmarks.**

## Device measurements and limits

The [aggregate capture](audit-evidence/usb-phone-profile.json) contains timing statistics and widget-event counts only: no VM-service authentication URI, ledger contents, account address, raw screenshots or financial amounts. Keyboard samples are individual diagnostic captures at different moments; no controlled release A/B speedup is claimed. Build instrumentation adds overhead, so instrumented numbers must not be compared directly to uninstrumented ones.

| Debug interaction | Build p50 / p95 | Raster p50 / p95 |
| --- | --- | --- |
| Original transaction keyboard, 77 frames | 16.53 / 30.21 ms | 7.59 / 16.13 ms |
| Optimized transaction keyboard, 78 frames | 16.14 / 25.08 ms | 6.93 / 8.87 ms |
| Dashboard scroll, 241 frames | 4.87 / 15.30 ms | 7.19 / 13.05 ms |
| Accounts scroll, 314 frames | 3.60 / 13.84 ms | 7.75 / 11.55 ms |
| Insights scroll, 345 frames | 2.36 / 8.43 ms | 9.07 / 12.41 ms |

Scroll captures used four ADB swipes per screen after tab navigation settled. Isolated build spikes remained: Dashboard **85.61 ms**, Accounts **50.89 ms**, Insights **94.88 ms**. The first promo open after hot reload also had a **204.76 ms** build spike. These debug captures include JIT/first-use costs and do not establish that all perceived lag is fixed. The verified result is reduced background/intrinsic work and repaired form behavior. A future profile-mode capture supplied by the owner is needed to assess representative release-frame performance; no profile APK was built here.

## Architecture, setup and reproduction

- `lib/widgets/keyboard_stable_page.dart`: keeps non-editing cached tabs at a stable keyboard-independent size; `main_nav_screen.dart` wraps the shell with it.
- `lib/widgets/form_dialog.dart`: bounded, scrollable form layout shared by transaction, promo and add-budget editors.
- `dashboard_screen.dart`: valid available-category selection and empty-category guard.
- `test/keyboard_and_budget_regression_test.dart`: budget selection/save/empty-list coverage, zero background builds across animated inset changes, root-dialog inset delivery, real size-change propagation, and narrow transaction/promo layouts.

Use the root README's Flutter **3.41.3 / Dart 3.11.1** setup and SDK path instructions. No new dependency, permission, backend configuration or database migration is required.

```powershell
adb devices -l
adb shell dumpsys package com.areeb.balance_tracker
# Open the existing debug app. Obtain its private VM service URI locally:
adb logcat -s flutter
# Use the DEVICE-side service port/token, not an already-forwarded host port:
flutter attach -d <device-id> --debug-url http://127.0.0.1:<device-port>/<token>/
# r = hot reload; d = detach while leaving the app running. Do not use q to detach.
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Use DevTools frame/timeline views through the attached VM. For diagnostics, capture `Flutter.Frame` extension events and enable widget-build tracing only in a separate capture. Warm the interaction, keep the same data/refresh preference, record the number of frames and compare build/raster percentiles. Do not publish the private VM URI or personal screenshots. This session retained the owner's selected 60 Hz preference and did not alter financial records.

## Validation

All **249 Flutter tests passed**, including **19 focused tests**, and static analysis found **no issues**.

- [Full Flutter test log](audit-evidence/usb-keyboard-budget-full-tests.txt)
- [Focused keyboard, budget and theme log](audit-evidence/usb-keyboard-budget-targeted.txt)
- [Static analysis log](audit-evidence/usb-keyboard-budget-analysis.txt)
- [Sanitized device measurements](audit-evidence/usb-phone-profile.json)

The phone was no longer connected when final delivery resumed, and the earlier attachment terminal had ended; no further live verification was possible. No APK was built or installed. Real-device checks verified transaction/promo opening, keyboard show/hide, budget-add opening and scrolling across Dashboard, Accounts and Insights. Dialogs were cancelled; no financial record was created, edited or deleted.

For public README screenshots, use a sample-data account and capture the add-budget panel, transaction keyboard layout and promo editor without personal identifiers. Private device screenshots inspected during diagnosis are intentionally not committed.
