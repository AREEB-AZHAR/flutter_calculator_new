# 💰 Tally — Smart Personal Finance & Expense Tracker

> *"Just tally it up!"* — A blazing-fast, modern personal finance manager built with **Flutter** & **Material 3**. Designed with fluid micro-interactions, dark glassmorphism styling, graphic theme customization, offline-first encrypted SQLite storage, and stutter-free 60/120fps mobile rendering.

---

## 📱 Visual Showcase & Screenshots

> [!TIP]
> **Screenshots Placeholder**: Capture and place your high-resolution screenshots in `assets/screenshots/` (e.g. `splash.png`, `dashboard.png`, `home_tour.png`, `accounts_tour.png`, `biometric_prompt.png`, `settings_guide.png`, `pro_paywall.png`, `google_auth.png`, `rewarded_ad.png`, `theme_passes.png`, `saved_accounts.png`).
> Recommended screens to capture:
>
> 1. **Biometric Quick Setup Modal**: Post-login prompt asking to enable screen lock/fingerprint.
> 2. **Home Screen Feature Tour**: Highlighting transaction auto-fill and category tips.
> 3. **Accounts Screen Walkthrough**: Explaining how to add new custom account types.
> 4. **Settings & Features Guide**: The educational bottom sheet explaining all settings.
> 5. **Tally Pro Locked Preview & Paywall**: The Insights preview lock screen with feature checklist and CTA.
> 6. **Native Ad Banner & Google Sign-In**: Contextual partner banner on Dashboard and Google button on Login.
> 7. **30-Second Non-Skippable Rewarded Ad Dialog**: Live countdown timer, progress bar, and reward unlock modal.
> 8. **Google Play Billing Checkout & Premium Screen**: Official in-app purchase tiers with one-tap checkout and restore purchases.
> 9. **Personal Wealth Accountant (Smart Insights)**: Multi-horizon dashboard showing Executive CPA brief, 50/30/20 breakdown, loans hub, and payment liquidity split.
> 10. **Global Onboarding Setup Modal**: First-time currency selection, 7-language selector, and default notification opt-in.
> 11. **Ambient Offline Banner & Offline Google Guard**: Real-time connectivity warning and offline Google account intercept modal.
> 12. **Cloud vs. Local Sync Conflict Comparison**: Side-by-side comparison cards (balances, transactions, goals, timestamps) with overwrite and offline-only data loss alerts.
> 13. **Saved Accounts Lock Screen Switcher**: One-tap account selection displaying user avatars, Biometric unlock, Google Account, and password auto-fill.

| Flowing Splash | Home & Offline Banner | Insights Pro Lock | Sync Conflict Cards | Saved Accounts Switcher |
| :---: | :---: | :---: | :---: | :---: |
| *(Add Splash Screenshot)* | *(Add Dashboard Banner Screenshot)* | *(Add Pro Paywall Screenshot)* | *(Add Sync Conflict Screenshot)* | *(Add Saved Accounts Screenshot)* |

---

## ✨ Features & Capabilities

### 1. 🌈 Flowing Colors Brand Splash & Cold-Boot Polish

- **Dynamic Gradient Sweep**: Fluid linear gradient shader washing vibrant colors (electric violet, ocean cyan, emerald green, solar amber) through the text **"TALLY"**.
- **Zero Black-Screen Startup**: Immediate rendering prevents the default blank/black frame cold-boot hitch on mobile devices.
- **Glowing Ambient Pulse**: Breathing micro-animations and smooth cross-fade transition into the login or dashboard shell.

### 2. ⚡ Zero-Lag On-Demand Tab Lifecycle & Rehydration
 
- **Instant Login Rendering**: Only the active Home dashboard (Tab 0) is built upon authentication, completely eliminating startup hitches caused by mounting all 5 analytical screens simultaneously.
- **On-Demand Tab Destruction & Rehydration**: When navigating between tabs, off-screen tabs are actively destroyed and removed from the Flutter element tree, discarding their widget instances, GPU textures, ticker listeners, and controller overhead to keep memory clean and tabs 100% fluid.
- **Instant In-Memory Cache Restoration**: When switching back to a destroyed tab, state is immediately restored from high-speed in-memory `AppState` ValueNotifiers with zero disk latency and a crisp, instantaneous zero-delay frame swap.
- **Atomic 100,000-Transaction SQLite Engine**: Benchmarked with 100k records; single-transaction operations persist in **12 ms** with indexed query execution (`idx_transactions_username_date`).

### 3. 🌐 "Overall" Consolidated Accounts & Wallet Intelligence

- **Consolidated Multi-Wallet View**: Accounts screen includes an **"Overall" (🌐 All Accounts)** mode displaying cumulative balance, total expenditure across all cards/wallets, and unified transaction feeds.
- **Multi-Month Wallet Analytics**: Chart dynamically filters for individual accounts or displays consolidated multi-month trend analysis when "Overall" is selected.

### 4. 🔄 Unified Bidirectional Currency Synchronization

- **Instant Dual-Location Sync**: Switching currencies from either the **Home Dashboard AppBar** or the **Profile Settings modal** immediately syncs across the entire application and updates the SQLite database persistently.
- **Visual Feedback**: Active currency checkmarks and theme-tinted badges in both picker interfaces.

### 5. 🎨 Graphic Theme Studio & Custom Identity

- **Fine-Grained Graphic Color Control**: Fine-tune primary and secondary accent colors with interactive Hue, Saturation, and Lightness (HSV) sliders or direct Hex input (`#8B5CF6`).
- **Curated Theme Palettes**: Quick-select from designer palettes (Violet Neon, Ocean Cyan, Emerald Matrix, Solar Amber, Rose Velvet, Cyberpunk Teal).
- **Custom Profile Photo Uploads**: Upload profile pictures from the device gallery with automatic fallback to stylized initial avatars.
- **Personal Bio & Display Name**: Edit custom profile text, displayed across the app header and profile dashboard.

### 6. 🛡️ Secure SQLite Database Vault & Cloud Architecture

- **On-Device Encrypted SQL Ledger**: All user accounts, transactions, budgets, goals, and customized profiles are securely stored in an on-device SQLite database (`finance_vault.db`).
- **Cryptographic Password Protection**: User passwords are protected using SHA-256 cryptographic hashing with unique random salts.
- **Strict User Isolation**: Foreign-key scoped queries guarantee that no account can ever access another user's financial records.
- **Full `.sql` Script Export**: One-tap generation and export of your complete SQL database dump for backups or offline inspection.
- **Firebase Ready (Hybrid Architecture)**: Abstracted database repository ready for instant multi-device cloud synchronization with Firebase Firestore & Firebase Auth.

### 7. 📈 Interactive Multi-Month Analytics Charts

- **Multi-Month Navigation**: Browse previous and future months seamlessly with `<` and `>` arrow selectors.
- **Chart Style Toggle**: Switch instantly between a **Smooth Line Flow** (daily balance and cumulative progression) and a **Segmented Donut Breakdown** (category distribution).
- **Metric Filter Selectors**: Toggle focus between **Spend (Expenses)**, **Income (Received)**, and **All (Net)**.
- **Dual-Screen Availability**: Embedded on both the **Home Dashboard** and the **Accounts & Wallets** screen.

### 8. 🧠 Executive Spending Behavior Summary

- **Dynamic Spending Persona**: Real-time behavioral badges based on cumulative savings velocity:
  - 🌟 *Master Wealth Builder* (Savings rate ≥ 40%)
  - 💎 *Balanced Strategist* (Savings rate 20% – 40%)
  - ⚡ *Active Cashflower* (Savings rate 5% – 20%)
  - 🔥 *Lifestyle Maximizer* (High expenditure burn rate)
- **Financial Vital Signs**: Track Lifetime Inflow, Lifetime Outflow, Accumulated Retained Wealth, and the **Needs vs Wants** essential allocation ratio.
- **Top Spending Drivers Leaderboard**: Interactive progress indicators displaying your top 4 expense categories by volume and percentage.
- **Peak Outflow Detector**: Real-time callout identifying the single largest expense recorded.

### 9. ⚙️ Dedicated Profile Settings Modal

- Access theme customizers, image uploaders, display name editors, currency switchers, password managers, and SQL data export from a central modal sheet.
- **One-Tap Home Redirection**: Tapping the user avatar in the Home page AppBar instantly navigates directly to the Profile tab.

### 10. ⏰ 3-Hour Expense Tally Reminders & Secret Dev Easter Egg

- **Offline-First Periodic Reminders**: Scheduled notifications reminding you to tally up recent expenses every 3 hours across active daytime hours (**9:00 AM, 12:00 PM, 3:00 PM, 6:00 PM, and 9:00 PM**).
- **Quiet Hours at Night**: Completely silent between **11:00 PM and 9:00 AM** to respect your sleep.
- **20 Friendly Conversational Prompts**: Rotates between 20 warm, casual check-ins that feel like a friend asking about coffee, snacks, impulse buys, or savings goals.
- **🕵️ Secret Dev Mode (10-Toggle Easter Egg)**: Flipping the reminder toggle switch in Settings 10 times in a row unlocks instant test reminder dispatching with a secret confirmation snackbar.
- **Cross-Platform Scheduling**: Uses `flutter_local_notifications` and `timezone` with Android `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` permissions to ensure alarms persist across device reboots.

### 11. 🎨 Ledger Brand Identity, Animated Startup & Dynamic Contrast System

- **Official Ledger Brand Mark**: Hand-crafted four vertical strokes and diagonal slash — the oldest counting system, built into high-resolution launcher icons and vector assets (`assets/icons/`).
- **Native 60fps Multi-Stage Animated Startup**:
  - **Stage 1 (Icon Drawing)**: Mathematical Bezier path rendering of the 4 vertical marks in cream (`#F6F0E1`) and slash in coral (`#E4572E`) on `#17493B` forest green.
  - **Stage 2 (Responsive Shrink & Wordmark)**: Icon shrinks smoothly (130px → 80px) and glides upward; the "TALLY" wordmark types in letter-by-letter with the exact uwash swoosh sweeping underneath. Guaranteed vertical and horizontal centering across all screen dimensions.
  - **Stage 3 (Continuous Hero Glide)**: The "TALLY" wordmark glides seamlessly into the top of the Login screen, while login inputs fly up from the bottom of the screen.
- **Strict Icon-to-Background Theme Alignment**:
  - **Ledger**: Background matches the official icon `#17493B` (deep forest green), surface `#103A2E`, text `#F6F0E1` (mark cream), and primary/slash accents `#E4572E`.
  - **Paper**: Background matches `#F6F0E1` (vintage paper), surface `#FFFFFF`, text `#17493B` (ink forest green), and primary/slash accents `#E4572E`.
  - **Ink**: Background matches `#191915` (deep charcoal/carbon), surface `#23231D`, text `#E8A13C` (amber slash font) & `#F3EDE0` (chalk), and across-slash accents `#E4572E`.
- **Background-Collision Protection & Dynamic Text System**:
  - Automatically heals legacy profiles and prevents custom primary colors from ever colliding with background colors.
  - Eliminates hardcoded white/black text across all screens, ensuring pristine contrast and readability regardless of chosen theme.

### 12. 🧭 Interactive Step-by-Step Feature Tours (New Users & Replayable)

- **Home / Dashboard Onboarding**: Introduces new users to Tally's core financial hub:
  - Explains the floating `+` button for rapid transaction recording.
  - **Auto-Fill Magic**: Highlights that users can leave the **Title** field empty to automatically auto-fill it with their selected category name.
  - **Category Auto-Switching**: Clarifies how selecting "Income" automatically defaults to "Salary".
  - **Interactive Analytics**: Teaches users how to toggle weekly, monthly, and yearly chart perspectives.
- **Accounts & Wallets Walkthrough**: Automatically triggered once when users navigate to the Accounts screen:
  - Explains multi-wallet separation across Bank, Cash, Savings, and Credit Cards.
  - Shows how to add custom account types via the `+ Add Account` button or the Settings icon (`⚙️`).
  - Illustrates the difference between the **Overall (🌐 All Accounts)** aggregate balance and isolated wallet analytics.
- **Replay Anytime**: Users can reset and re-launch both walkthroughs on demand from the Profile Settings menu.

### 13. 🔐 Post-Login Biometric Quick Setup Prompt

- **Seamless Prompting**: Upon logging in, Tally verifies whether the user has configured biometric login or device screen lock.
- **One-Tap Enrollment**: If not configured, displays an elegant, non-intrusive popup offering immediate configuration via native biometric authentication (Fingerprint, Face ID, or PIN).
- **Session-Aware**: Prompts smoothly upon session login without interrupting tab switching, and resets state upon logout.

### 14. 📚 Comprehensive "What Each Setting Does" Features Guide

- **In-App Educational Guide**: Accessible from the Profile AppBar and the top of the Settings bottom sheet.
- **Detailed Explanations**: Breaks down what every single setting and function does in clear, user-friendly language:
  - Brand Palettes (Ledger, Paper, Ink) & instant application-wide styling.
  - Launcher App Icons and OS home-screen restart requirements.
  - Theme Studio custom primary, secondary, and typography color picker.
  - Biometric & screen lock local security.
  - Encrypted SQLite vault architecture & `.sql` database script export.
  - Cloud Sync (Firebase Firestore ready) integration.
  - Real-time dynamic currency switcher.

### 15. 💎 Tally Pro & Freemium Monetization Engine

- **Strategic Power-User Gating**: Follows 2026 leading fintech best practices (e.g. Copilot Money, Monarch, Splitwise) keeping essential utility (expense logging, balance tracking, multi-account management) 100% free while gating advanced capabilities behind **Tally Pro**:
  - **Smart Insights & Predictive Velocity**: Gated behind an elegant, frosted preview lock screen displaying daily spending run-rate mockups, savings trajectory analysis, and direct "Unlock Tally Pro" CTA.
  - **Graphic Theme Studio**: Fine-grained RGB/HSV sliders, bespoke color palettes, and text tone customizers require Pro membership.
  - **Custom Dynamic Launcher Icons**: Custom Android home screen icon aliases (Ink, Paper, Ledger) are reserved for Pro members.
  - **100% Ad-Free Experience**: Pro automatically deactivates all sponsored banner placements across the entire app.
- **Separate "Remove Ads" Option ($1.99)**:
  - Users who only want an ad-free interface without paying for full analytical Pro features can purchase the dedicated "Remove Ads" tier directly in Profile Settings.
- **VIP Promo Code Unlock Modal**:
  - Interactive unlock modal supporting codes `PROVIP` or `FINTECH2026` (unlocks full Pro tier) and `NOADS` (unlocks ad-free experience), with instant "Reset to Free Tier" for developer and QA validation.

### 16. 📢 Native Contextual Partner Ad Banners (100% Removable)

- **Fintech-First Non-Intrusive Design**: Replaced aggressive, trust-destroying popups or interstitials with sleek, theme-matched partner banner cards.
- **Integrated Placements**: Embedded naturally between the Total Balance Card / Interactive Chart and Recent Transactions on `DashboardScreen`, as well as on `AccountsScreen` and `AllTransactionsScreen`.
- **Dynamic Sponsor Rotation**: Styled with rounded container borders, an unobtrusive "Ad" chip, financial partner benefits (e.g. high-yield savings, cloud infrastructure, smart bookkeeping), and a quick "Hide" shortcut that opens the paywall modal.
- **Zero-Footprint Dismissal**: When the user unlocks Pro or purchases "Remove Ads", the banner returns `SizedBox.shrink()` (0 pixels height) with no layout shift or leftover padding.


### 17. 🔑 Google Account Authentication & Cloud Ledger Binding

- **1-Tap Google Sign-In**: Added authentic "Sign in with Google" button on `LoginScreen` with the official Google logo.
- **Cross-Platform Compatibility**: Uses native Google Identity Services on mobile/web with a styled Google Account Picker fallback for Windows desktop, emulators, and local test environments.
- **Encrypted Database Identity Binding**: Associates all SQLite accounts, transactions, budgets, goals, and customized profiles directly to the user's Google email (`user_id`), preserving data across logouts and devices.
- **Account Binding Badge**: Displays an authentic Google status badge (`[G] Bound to Google: user@gmail.com`) in the Profile identity card, with a 1-tap "Link Google Account" button for legacy local accounts.

### 18. 💎 Recalculated Pro Pricing & Google Play Billing

- **Dedicated Premium Screen**: Accessible directly from the Profile identity card ("Get Tally Pro / Manage Subscription") with live billing state synchronization.
- **Recalculated Tier Matrix & Unit Economics**:
  - **Monthly Plan**: **$2.99 / month** — flexible low-barrier entry with full analytical access.
  - **Annual Plan**: **$19.99 / year** ($1.67 / mo) — **save 44%** compared to monthly billing, with a prominent "Best Value" highlight badge.
  - **Lifetime Access**: **$39.99 one-time** — 2.0x annual price; pay once and own Tally Pro forever with no recurring charges.
  - **Remove Ads Only**: **$1.99 one-time** — standalone microtransaction for users wanting an ad-free interface without analytical pro gating.
  - **Buy Me a Coffee**: **$2.99 one-time** — warm community support tier ("Support indie development! Removes all sponsored partner ads forever, plus receive a 7-Day Tally Pro trial pass as our special thank-you gift").
- **Official Google Play Billing Integration**:
  - Direct integration via Flutter's official `in_app_purchase` package with `<uses-permission android:name="com.android.vending.BILLING"/>`.
  - Official Play Store Product IDs: `tally_pro_monthly`, `tally_pro_yearly`, `tally_pro_lifetime`, `tally_remove_ads`, `tally_coffee_tip`.
  - Handles real-time store queries, purchase stream listeners, `completePurchase()`, pending order states, and a dedicated **"Restore Purchases"** action.
  - Fallback desktop and test simulation ensuring flawless development and QA validation on Windows and test harnesses.

### 19. 🤝 Accounts Receivable & Payable (Loans & Debts Ledger)

- **Dedicated Dual-Mode Ledger**: Integrated into `AccountsScreen` under the **Loans & Debts** segment tab.
- **Receivables & Payables Segmentation**:
  - **Money Lent Out (Receivable)**: Track money you loaned to friends, colleagues, or clients with outstanding balances and due dates.
  - **Money Borrowed (Payable)**: Keep precise track of borrowed sums and debts to ensure timely repayment and protect financial integrity.
- **Summary Header Metrics**: Real-time cards calculating Total Receivable, Total Payable, and Net Credit/Debt Position.
- **Automated Push Reminder Notifications**:
  - Automatically schedules local push notifications on the user-specified reminder date.
  - For Receivables: Friendly check-in prompt: *"Reminder: Did you receive $X from Person for [Reason]?"*
  - For Payables: Alert prompt: *"Payment Due: $X to Person for [Reason] is scheduled for today."*
- **One-Tap Settlement**: Mark loans settled with a single tap, updating history and recalculating balances instantly.

### 20. 📅 Automated Recurring & Planned Transactions

- **Auto-Recurring Engine**: Recurring transactions (Daily, Weekly, Monthly) are automatically evaluated on app launch and user login. Due instances are posted directly to the official SQLite ledger with duplicate protection.
- **Interactive Planned & Future Sheet**: A dedicated bottom sheet modal (`PlannedTransactionsSheet`) staging future-dated financial commitments.
- **Early Execution & Cancellation**: Users can inspect upcoming commitments, manually post them immediately with "Post Now", or delete them before they mature.

### 21. 📊 Enhanced Single-Scroll All Transactions & Dynamic Chart Analytics

- **Unified Continuous Scroll**: Completely replaced nested inner scrolling views with a unified, conflict-free `CustomScrollView` ensuring buttery 60/120fps physics.
- **Real-Time Dynamic Search**: Typing into the search bar instantly filters records and dynamically recalculates total spending, income, counts, and charts in real time.
- **Tri-Mode Flexible Visualizer**:
  - **Segmented Donut**: Category allocation breakdown.
  - **Daily Line Flow**: Interactive cumulative net balance trend.
  - **Bar Chart**: Periodic volume bars for immediate comparative analysis.
- **Scope Navigation**: Toggle between Year-to-Date and Month-level analytical scopes with dynamic axis labels.

### 22. 🔄 Two-Way Cloud Deletion Reconciliation & Security

- **Bidirectional Sync Protocol**: Ensures SQLite local changes and Cloud Firestore cloud documents stay in 100% lockstep.
- **Safe Cloud Deletion Purge**: When an account, transaction, loan, or goal is deleted on a local device, `CloudSyncService.sync` identifies cloud documents whose IDs are no longer present in local storage and safely purges them from Firestore, preventing zombie reappearance upon re-login.
- **Cryptographic User Isolation**: All Firestore paths are strictly scoped under `users/{user_id}/...`, guaranteeing that only the authenticated user can read or mutate their financial data.

### 23. 🎨 Zero-Glitch Dynamic Palette Engine & Theme Contrast Alignment

- **Unified Single-Frame Rebuilds**: Replaced cascading nested `ValueListenableBuilder`s with a unified `AnimatedBuilder(animation: Listenable.merge([...]))` in `main.dart` and `profile_screen.dart`.
- **Eliminated Multi-Frame Flashes**: Eliminates the 4-frame visual glitch previously triggered when selecting theme presets.
- **Smooth 150ms Palette Lerping**: Added `themeAnimationDuration: const Duration(milliseconds: 150)` with `Curves.easeInOut` for smooth, polished color transitions.
- **Theme-Adaptive Semantic Accents**: Replaced hardcoded neon accents with theme-adaptive colors (`#059669` / `#D97706` / `#DC2626` in light mode, `#10B981` / `#FBBF24` / `#F87171` in dark mode) ensuring crisp contrast across all 9 presets.

### 24. 🎬 Non-Skippable 30-Second Rewarded Ad & 1-Time Theme Unlock Passes

- **Authentic 30-Second Rewarded Ad Experience**:
  - Integrated Google Mobile Ads official rewarded ad unit IDs (`ca-app-pub-3940256099942544/5224354917` on Android, `ca-app-pub-3940256099942544/1712485313` on iOS).
  - Cross-platform fullscreen rewarded ad dialog (`Fullscreen30SecAdDialog`) for desktop and testing with real-time countdown timer (`30s` down to `0s`), animated progress indicator, and exit-prevention confirmation guard.
  - **Non-Skippable PopScope Enforcement**: Users attempting to dismiss the ad early receive a confirmation warning (*"Ad Incomplete: Watching the full 30s ad is required to unlock your 1-time theme pass. Keep watching or discard?"*).
  - Claim button unlocks dynamically upon timer completion (0s) with celebration icons and haptic feedback.
- **Theme Pass Inventory & Micro-Unlock Engine**:
  - Watching a 30s rewarded ad awards **+1 Theme Pass** directly to the user's local inventory (`AppState.themePassesNotifier`).
  - Base presets (**Ledger**, **Paper**, **Ink**) remain permanently free.
  - Applying premium brand presets (**Violet Night**, **Ocean Blue**, **Emerald Dark**, **Rose Gold**, **Sunset Orange**, **Midnight Teal**) or Graphic Theme Studio custom palettes on the Free tier prompts the user to either:
    1. **Use 1 Theme Pass** (if balance > 0).
    2. **Watch a 30-Second Rewarded Ad** to earn an instant pass and apply the theme immediately.
    3. **Upgrade to Tally Pro** for permanent, unlimited theme customization.
  - **Profile Screen Theme Passes Banner**: Displays live pass count with a "+1 Pass (Watch Ad)" chip for instant on-demand unlocking.
  - **QA Testing Promo Code**: Entering `THEMEPASS` into the VIP promo code dialog immediately grants 3 Theme Passes for verification.

### 25. 💳 Google Play Billing Service & State Management

- **Official `in_app_purchase` Engine**:
  - Dedicated `InAppPurchaseService` class wrapping Flutter's official in-app purchase platform channels.
  - Configured Android Billing permission `<uses-permission android:name="com.android.vending.BILLING"/>` in `AndroidManifest.xml`.
  - Lazy evaluation of platform instances prevents test crashes and Pager channel exceptions in non-mobile environments.
  - Supports live store queries, order pending state handling, `completePurchase()`, transaction verification, and `restorePurchases()`.
- **Product ID SKU Catalog**:
  - `tally_pro_monthly`: $2.99/mo subscription.
  - `tally_pro_yearly`: $19.99/yr subscription (Best Value, 44% savings).
  - `tally_pro_lifetime`: $39.99 non-consumable one-time purchase.
  - `tally_remove_ads`: $1.99 non-consumable one-time purchase.
  - `tally_coffee_tip`: $2.99 consumable purchase.

### 26. 🔒 Strict Account Theme Isolation & Scoped Monetization

- **Zero Cross-Account Theme Bleed**:
  - Eliminated the device-wide theme carry-over bug where logging into a second account inherited the previous user's chosen theme (even if it was a premium palette).
  - All monetization states (`tally_pro_unlocked_$username`, `tally_ads_removed_$username`, `tally_theme_passes_$username`, `tally_pro_trial_expiry_$username`) are strictly isolated per user account.
  - Device preferences are stored under user-scoped keys (`tally_active_theme_$username`, `tally_primary_color_$username`).
- **Complete Session Cleansing on Logout**:
  - `AppState.clearUserSession()` immediately resets in-memory theme notifiers back to base **Ledger**, wipes all user financial caches, cancels active timers, and invokes `MonetizationService.resetToLoggedOut()`.
- **Automatic Sanitization for Free Accounts**:
  - In `AppState.loadAllUserData()`, if an account is on the Free tier and possesses a premium theme (e.g. *Violet Night*, *Ocean Blue*, *Emerald Dark*, *Rose Gold*, *Sunset Orange*, *Midnight Teal*) or custom Graphic Studio modifications, the app automatically sanitizes and downgrades the session to the default clean **Ledger** palette (`#E4572E` / `#F6F0E1`).
  - Pro accounts and users with valid 1-time theme passes retain their chosen palettes safely across re-logins.

### 27. ⏳ 5-Second Auto-Dismissing Undo Banners

- **Guaranteed Auto-Dismissal**:
  - When deleting transactions, goals, budget caps, accounts, or loan records, the 'Undo' SnackBar banner is now configured with an exact `duration: const Duration(seconds: 5)` and an explicit internal dismissal controller.
  - The banner automatically disappears after exactly 5 seconds without lingering indefinitely or blocking UI actions.
- **Race-Condition & Memory Protection**:
  - Tapping "Undo" immediately cancels the dismissal timer, restores the deleted record at its exact chronological position, persists to SQLite, and reconciles with cloud sync.
  - Calling `AppState.clearUserSession()` cancels all pending SnackBar timers to prevent dangling async leaks.

### 28. ⚡ Pure On-Demand Tab Lifecycle & Zero Background Lag

- **Eliminated Background Page Lag**:
  - Replaced persistent multi-screen stack rendering (`IndexedStack` with pre-warmed tabs) with pure on-demand construction via `_buildActiveScreen(currentIndex)`.
  - Only the currently visible screen is mounted in the element tree. When the user navigates away, inactive tabs are completely unmounted and disposed, instantly freeing GPU render textures, animation tickers, and stream subscriptions.
- **Sub-15ms Instant Screen Mounting**:
  - Tab instantiation in Flutter takes merely ~6–12ms, rendering tabs instantly when selected without any need to keep 5 heavy screens loaded concurrently in the background.

### 29. 🛡️ Case-Insensitive SQLite Collation & Biometric Multi-Account Isolation (v1.7.0)

- **Case-Insensitive SQLite Authentication**:
  - Added `COLLATE NOCASE` across all user table authentication queries (`authenticateUser`, `getUsernameForIdentifier`, `getUserEmail`, `bindEmailToUser`, `getUserByEmail`, `updatePasswordByEmail`, and `registerUser`).
  - Mobile keyboards that auto-capitalize first letters (e.g. `User123` vs `user123`) now authenticate cleanly without rejection.
  - Case-insensitive database indexes (`idx_users_username_nocase`, `idx_users_email_nocase`) ensure sub-millisecond lookups.
  - Google OAuth sign-in automatically persists clean lowercase email addresses and heals legacy records.
- **Biometric Multi-Account Isolation**:
  - `BiometricService.syncUserSession(username)` ensures switching to or registering a new account clears previous biometric credentials unless the active account explicitly enabled them.
  - Automated post-login onboarding prompt on Dashboard invites new and switched accounts to configure screen lock or fingerprint unlock with a single tap.

### 30. 🧠 Smart Financial Intelligence & Personal Wealth Accountant Suite (v1.8.0)

- **Multi-Horizon Analytical Framework**:
  - Seamlessly switch between **Daily**, **Weekly**, **Monthly**, and **Yearly** horizons with animated selection pills.
  - Interactive period stepper (`<` and `>`) allows stepping back through historical weeks, months, or years with a quick "Back to Current" reset action.
  - Dynamically calculates Inflow, Outflow, Net Surplus/Deficit, Savings Rate %, and Daily Burn Velocity with period-over-period delta comparisons (`vs Previous Period`).
- **Executive Accountant's Take & Financial Health Score**:
  - Automated CPA-grade briefing synthesizing current cash flow patterns, identifying primary expense drivers, and delivering concrete, actionable recommendations.
  - **100-Point Financial Health Score** evaluating savings rate, budget discipline, debt burden, and cash flow stability with status badges (*Excellent*, *Strong*, *Moderate*, *Needs Attention*).
- **Future Planning: 50/30/20 Rule Optimizer & Safe-to-Spend**:
  - Compares actual spending against the golden standard: **Needs (~50%)**, **Wants (~30%)**, and **Savings & Debt (~20%)** with visual tri-color distribution bars and advisory commentary.
  - **Safe-to-Spend Run Rate**: Real-time daily and weekly discretionary allowances to ensure positive end-of-period cash reserves.
  - **Wealth Trajectory**: 6-month and 1-year projected savings milestones based on current velocity.
- **Category Spending & Prorated Budgets Matrix**:
  - Prorates monthly budgets accurately across Daily (/30), Weekly (*7/30), Monthly (*1), and Yearly (*12) scopes.
  - Visual progress indicators with dynamic semantic coloring (Theme Primary < 75%, Amber 75–100%, Coral Red > 100% with `OVER` badges).
- **Loans & Debt Liabilities Portfolio**:
  - Integrated tracking of outstanding debt (`payable`) vs receivables (`receivable`) and net liability position.
  - **Debt-to-Income (DTI) Ratio**: Evaluates debt load against inflow with status tiers (*Healthy <36%*, *Moderate 36-43%*, *Strained >43%*).
  - **Debt Payoff Advisor**: Evaluates Snowball vs. Avalanche strategies, highlights upcoming due dates, and projects debt-free milestones.
- **Universal Liquidity & Multi-Horizon Financial Health**:
  - Replaced localized US-specific tax deduction estimates with jurisdiction-agnostic liquidity and savings analytics suitable for global users worldwide.
- **Payment Types & Liquidity Split**:
  - Analyzes spending distribution across accounts (Credit Card, Cash, Bank Transfer, Digital Wallet).
  - Alerts users on credit card reliance to avoid revolving interest traps.
- **High-Converting Pro Locked Experience**:
  - Premium preview showcasing live-like interactive preview cards, CPA badges, and comprehensive feature value checklist.

### 31. 🏦 Savings Vault, Due Dates, Pacing Calculator & Smart Category Budgets (v1.9.0)

- **Smart Unset Category Limit Handling**:
  - Solves the unbudgeted category issue without false alarm: categories without an explicit limit are now categorized as **Uncapped / Flex Allocation** rather than alarming users with red `OVER / $0` warnings.
  - Automatically calculates intelligent baseline suggestions based on spending patterns.
  - Features an inline **`[+ Set Limit]`** button on every uncapped category that opens the budget dialog directly and updates in real-time.
- **Goal Deadlines & Multi-Cadence Pacing Engine**:
  - Set target completion dates with quick one-tap duration chips: **Today (Daily Allowance)**, **1 Week**, **1 Month**, or **Custom Date Picker**.
  - Dynamically computes required savings pace per day or per week: *"Save $32/day to reach by Nov 1"*.
- **Mid-Day & Evening Pacing Push Reminders**:
  - Automatically schedules daily reminders at **1:00 PM** and **7:00 PM** for active goals with due dates.
  - Daily allowance goals receive motivating *"🎯 Today's Goal: Don't forget to stash $X today from your daily allowance!"* check-ins.
  - Multi-day goals receive pacing alerts showing remaining balance and required daily savings rate.
- **Recurring Goal Cycles & History Preservation**:
  - Supports recurring goals with frequencies (**Daily**, **Weekly**, **Monthly**).
  - Auto-detects completed and expired goals and prompts users to start a fresh cycle without deleting past achievements.
  - Completed or failed goals display a clear status badge and strikethrough line to preserve historical timeline records.
- **SQLite Database Preservation & Editable Contribution Entries**:
  - **Soft-Deletion Retention**: Goals with >10% progress or completed status are safely archived (`is_archived = 1`) upon deletion rather than purged, protecting historical data integrity.
  - Every deposit and withdrawal is recorded in an indexed `goal_entries` table.
  - **Collapsible Recent Entries**: Goal cards feature a toggle chevron displaying the 2 most recent deposits directly on the card.
  - **Goal Detail Bottom Sheet**: Tapping a goal card reveals an interactive **Pie/Donut Progress Chart** (Saved vs. Remaining) and the complete ledger of contributions with full inline edit and delete capabilities.
- **Direct Goal Transfer from Transaction Dialog & Hero Vault Chip**:
  - New **"Savings Goal"** category in the Add Transaction modal allows users to select an active goal and deposit directly into it.
  - Goal transfers are excluded from deducting liquid cash balance on the main dashboard.
  - **Dashboard Hero Vault Chip**: Under the total balance, a sleek badge displays total vault stashed savings and recent contributions (`🏦 Savings Vault: $X total stashed · Recent: +$Y towards [Goal]`).
- **Smart Insights Integration**:
  - New **Savings Vault & Goal Momentum** analytics card in the Smart Insights tab tracking stashed amounts across Daily, Weekly, Monthly, and Yearly horizons with motivational CPA commentary.

### 32. 🌐 Multi-Currency, 7-Language Localization, Offline Resilience & Sync Conflict Resolution (v2.0.0)

- **Elimination of Region-Specific Tax Estimations**:
  - Completely stripped regional US tax deduction estimates and UI cards from `insights_engine.dart` and `insights_screen.dart` to maintain an accurate, universal experience across international tax jurisdictions.
- **Global Multi-Currency Engine**:
  - Full support for 10 international currencies: `USD ($)`, `EUR (€)`, `GBP (£)`, `PKR (₨)`, `INR (₹)`, `JPY (¥)`, `AED (د.إ)`, `SAR (﷼)`, `CAD (C$)`, `AUD (A$)`.
  - Available across all dialogs, analytics cards, transaction lists, and profile settings with real-time reactive updates.
- **7-Language Multilingual Engine with Dynamic RTL Flipping**:
  - Seamless in-app localization for:
    1. **English (EN)**
    2. **Español (ES)**
    3. **Français (FR)**
    4. **Deutsch (DE)**
    5. **اردو (UR - Urdu)** *(Full Right-to-Left RTL support)*
    6. **العربية (AR - Arabic)** *(Full Right-to-Left RTL support)*
    7. **हिन्दी (HI - Hindi)**
  - Reactive `Directionality` flipping dynamically shifts layouts between LTR and RTL without requiring an application restart.
- **First-Time Account Onboarding Setup Dialog**:
  - Automatically launches upon creating a new local account or signing in for the first time.
  - Allows immediate selection of preferred Currency and Language.
  - **Notifications Enabled by Default**: Automatically activates smart reminders, debt due date alerts, and goal target pacing check-ins with an opt-out toggle.
- **Real-time Offline Connectivity Monitoring & Ambient Banner**:
  - `ConnectivityService` provides non-blocking, cross-platform DNS socket reachability checks.
  - An ambient, animated amber notification banner appears seamlessly at the top of all navigation tabs when disconnected: *"You are offline. Your changes are saved locally and will sync when reconnected."* Includes a quick-tap Retry button.
- **Offline Google Sign-In Guard**:
  - Intercepts Google authentication attempts when offline, preventing network error popups.
  - Displays a clean dialog explaining that Google requires an active connection and offers a one-tap transition to create/use a local device account that will sync automatically upon reconnection.
- **Cloud Vault vs. Local Storage Sync Conflict Resolution**:
  - Detects diverging states when logging in with internet and data exists in both Google Cloud Firestore and local SQLite.
  - Displays side-by-side **Balance & Record Comparison Cards**:
    - **Google Cloud Vault**: Total balance, transaction count, savings goals count, and last sync timestamp.
    - **On-Device Storage**: Total balance, transaction count, savings goals count, and last saved timestamp.
  - Provides 3 explicit resolution actions:
    1. **Restore Cloud Data**: Replaces local records with cloud vault backup.
    2. **Upload Device Data**: Overwrites cloud vault with local changes.
    3. **Keep Using Offline Only**: Retains local device data without uploading.
  - High-visibility safety notice: *"⚠️ Offline-Only Notice: Data will remain strictly on this device. If you uninstall the app or clear device storage, data cannot be recovered."*
- **Accessibility Font Scaling Safeguard**:
  - Wrapped `MaterialApp.builder` with `MediaQuery` overriding `textScaler` clamped between `0.85` and `1.25`.
  - Prevents button clipping, overflow bars, and layout breakages when high system accessibility font sizes (e.g. 1.5x – 2.0x) are enabled on the operating system.

### 33. 🔐 Saved Accounts Lock Screen Switcher, Tour Concurrency Lock & Multilingual UI Localization (v2.1.0)

- **Dedicated Saved Accounts Manager ([`SavedAccountsScreen`](lib/screens/saved_accounts_screen.dart))**:
  - Accessible directly from the lock/login screen (`[Manage Saved Accounts]` button & pill indicator) and from Profile Settings.
  - Automatically queries all registered accounts on device via [`AppDatabase.getAllSavedAccounts()`](lib/services/database/app_database.dart) combining user credentials, avatar paths, custom brand colors, and authentication options.
  - **One-Tap Biometric Authentication**: For accounts with biometric unlock enabled, tapping the account card or fingerprint icon directly triggers device biometric authentication (Fingerprint, Face ID, PIN) and logs in immediately upon success.
  - **One-Tap Google Authentication**: For accounts registered with Google Sign-In, tapping launches the authentic Google OAuth pipeline seamlessly.
  - **Instant Password Auto-Fill**: For standard accounts, selecting an account populates the username in the login form with focus set on the password field.
  - **Secure Account Removal**: Allows deleting remembered accounts with a safety confirmation dialog without deleting other on-device data.
  - **Clean Fallback**: Includes a "Log In with Another Account" button at the bottom for new account entry.
- **Dynamic Multilingual Localization for All Screens**:
  - Resolved the bug where changing languages left interface labels in English by converting all hardcoded text strings in [`DashboardScreen`](lib/screens/dashboard_screen.dart), [`MainNavScreen`](lib/screens/main_nav_screen.dart), and [`LoginScreen`](lib/screens/login_screen.dart) to reactive [`LanguageService.tr(...)`](lib/services/language_service.dart) calls.
  - Expanded all 7 translation dictionaries (`en`, `es`, `fr`, `de`, `ur`, `ar`, `hi`) covering navigation tabs, balance cards, monthly budgets, recent transactions, saved accounts management, and all login/registration fields.
- **Tour Replay Concurrency Lock & Deduplication**:
  - Eliminated the double tour replay bug where replaying the Home Dashboard tour from Profile Settings triggered the tutorial twice back-to-back.
  - Implemented a static concurrency mutex `_isTourOpen` with `try ... finally` safety in [`FeatureTourDialog.showFeatureTour()`](lib/widgets/feature_tour_dialog.dart), actively discarding duplicate dialog mount requests.
  - Removed duplicate calls in [`ProfileScreen`](lib/screens/profile_screen.dart) when switching tabs, preventing race conditions with `DashboardScreen._checkPostLoginPrompts()`.

### 34. 🎯 Precision Goal Notifications, Live Daily Pacing & Dynamic Remaining Balance (v2.2.0)

- **Accurate Goal Reminders with Dynamic Remaining Balance**:
  - Eliminated stale notifications displaying the initial target amount (`goal_amount`) by rescheduling alarms dynamically whenever deposits, transactions, or deletions occur.
  - Notification copy explicitly highlights the exact remaining balance left:
    `"$currency${remaining.toStringAsFixed(0)} left to reach \"${goal.title}\". Save $currency${dailyNeeded.toStringAsFixed(0)}/day to finish by [Date]!"`
  - Daily goals clearly communicate progress: `"You have $currency${remaining.toStringAsFixed(0)} left to save for \"${goal.title}\" ($currency${goal.saved.toStringAsFixed(0)} of $currency${goal.target.toStringAsFixed(0)} saved)!"`.
  - Automatically cancels pacing reminders once a goal reaches 100% completion.
- **Live Daily Savings Pacing on Goal Cards**:
  - Prominent **Amount Left Badge** (`$currency${goal.remainingToSave.toStringAsFixed(0)} left`) displayed alongside saved and target values.
  - Pacing badge (`Save $X/day · Yd left` or `Save $X today · Due Today`) is displayed for **all active goals**, including goals with transactions and goals created without an explicit due date (intelligently calculating period pacing).
  - Recalculates dynamically in real time: as transactions or deposits are added, the daily required savings rate decreases instantaneously.
- **End-of-Day Expiration Guard**:
  - Protected `SavingsGoal.isExpired` from prematurely failing goals mid-day on their due date: goals remain active until 23:59:59 of their scheduled completion date.

---

## 🏗️ Clean Modular Architecture

```
assets/
└── icons/                          # Official vector & raster brand assets
    ├── tally.svg                   # Master 512x512 Ledger vector
    ├── tally-uwash.svg             # Signature hand-drawn underline
    ├── tally-icon-anim.svg         # Self-animating SMIL icon
    ├── tally-wordmark-anim.svg     # Animated typography & uwash
    └── tally-512.png               # High-res 512px raster icon
lib/
├── main.dart                       # App entrypoint, unified AnimatedBuilder theme listener
├── firebase_options.dart           # Cross-platform Firebase config & credentials
├── models/                         # Domain data models
│   ├── transaction.dart            # Transaction schema & serialization
│   ├── savings_goal.dart           # SavingsGoal schema, deadline & pacing calculations
│   ├── goal_entry.dart             # Goal deposit entry model with SQLite persistence
│   ├── loan.dart                   # Loan model (Receivable/Payable, reminder dates)
│   ├── planned_transaction.dart    # Planned & future-dated transaction model
│   ├── saved_account_info.dart     # Multi-account lock screen identity model
│   └── user_profile.dart           # User profile, custom colors & photo model
├── screens/                        # Application screens
│   ├── splash_screen.dart          # Multi-stage Bezier animated brand startup
│   ├── login_screen.dart           # Hero wordmark & bottom-sliding authentication
│   ├── saved_accounts_screen.dart  # Multi-account lock screen switcher & biometric auth
│   ├── main_nav_screen.dart        # Lazy-loaded tab shell with idle pre-warming
│   ├── dashboard_screen.dart       # Post-login biometric prompt & Home Tour trigger
│   ├── all_transactions_screen.dart# Single-scroll dynamic search & 3-mode visualizer
│   ├── insights_screen.dart        # Spending trends, category breakdown & Pro lock preview
│   ├── goals_screen.dart           # Goal progress & fund allocations
│   ├── accounts_screen.dart        # Accounts & Wallets + Loans & Debts dual-tab screen
│   ├── premium_screen.dart         # Dedicated Tally Pro paywall & Google Pay checkout
│   └── profile_screen.dart         # Features & Settings guide, Theme Studio & tours reset
├── services/                       # State & Persistence
│   ├── insights_engine.dart        # Multi-horizon intelligence, CPA commentary & 50/30/20 engine
│   ├── connectivity_service.dart   # Live cross-platform internet reachability monitor
│   ├── language_service.dart       # 7-Language multilingual engine & RTL manager
│   ├── in_app_purchase_service.dart# Google Play Billing (IAP) service & restore engine
│   ├── monetization_service.dart   # Recalculated pricing, Theme Pass engine & promo codes
│   ├── ad_service.dart             # Google AdMob Banner & Rewarded 30s Video ads
│   ├── google_auth_service.dart    # Google Sign-In & SQLite identity binding
│   ├── cloud_sync_service.dart     # Two-way SQLite & Cloud Firestore conflict resolution
│   ├── biometric_service.dart      # Biometric & screen lock auth & setup modal
│   ├── tour_service.dart           # Tour completion flags & reset persistence
│   ├── notification_service.dart   # Loan push reminders, goal pacing & tally alerts
│   ├── app_icon_service.dart       # Dynamic launcher icon switcher
│   ├── state.dart                  # AppState ValueNotifiers & reactive state
│   └── database/                   # SQLite database engine & security
│       ├── app_database.dart       # SQLite tables, migrations, CRUD & SQL export
│       └── security_helper.dart    # SHA-256 password salting & verification
├── utils/                          # Styling & Design Tokens
│   ├── constants.dart              # Dynamic theme generator, icons & currencies
│   └── password_validator.dart     # Strong password validation rules
└── widgets/                        # Reusable UI & Custom Painters
    ├── offline_banner.dart         # Ambient real-time offline warning notification bar
    ├── new_user_setup_dialog.dart  # First-time currency, language & notifications setup modal
    ├── sync_conflict_dialog.dart   # Cloud vs. Local side-by-side comparison & conflict resolver
    ├── fullscreen_30sec_ad_dialog.dart # Non-skippable 30s countdown rewarded ad player
    ├── ad_banner_widget.dart       # Theme-adaptive native partner banner card
    ├── feature_tour_dialog.dart    # Step-by-step onboarding walkthrough dialog
    ├── tally_brand_painters.dart   # TallyIconPainter, UwashPainter & Wordmark
    ├── custom_painters.dart        # Repaint-bounded Month line, Donut & Bar painters
    ├── interactive_chart_card.dart # Multi-month & tri-mode visualizer card
    ├── planned_transactions_sheet.dart # Staged future commitments bottom sheet
    ├── color_picker_dialog.dart    # Graphic Theme Studio (HSV sliders & hex)
    ├── transaction_tile.dart       # Dismissible transaction list item
    └── transaction_dialog.dart     # Auto-fill empty title & Income->Salary switcher
```

---

## ⚡ Mobile Performance & Stability Optimizations

- **Zero-Lag Tab Switching**: Uses `IndexedStack` to maintain screen states and scroll offsets offstage, eliminating frame drops when navigating between tabs.
- **GPU Repaint Isolation**: Charts are wrapped with `RepaintBoundary` and employ smart equality checks in `shouldRepaint` to avoid redundant CPU/GPU canvas repainting during scroll.
- **Native Typography Fallback**: Automatically adopts platform-native fonts (Roboto on Android, San Francisco on iOS) to eliminate font-fallback lookups during keyboard input while retaining Segoe UI on Windows.
- **Optimized Mobile Text Inputs**: Soft keyboards on login and modal forms disable unnecessary IME dictionary suggestions and autocorrect, preventing keypress stutter and rendering lag.
- **Resilient Error Guards & Fixed-Height Actions**: Authentication and dialogs feature crash-proof try/catch handlers and fixed-dimension button layouts that prevent UI jumping during loading states.
- **Memory-Safe Dialogs**: Controller allocations are decoupled from dialog rebuild lifecycles and safely disposed to prevent memory leaks and keyboard glitches on Android/iOS virtual keyboards.
- **Precomputed Data Aggregations**: Chart coordinate normalization and cumulative balances are calculated ahead of rendering rather than on every frame.

---

## 🛠️ Getting Started: Prerequisites & Local Setup

Follow these steps to clone and run the project locally on your machine.

### 1. Prerequisites

- **Flutter SDK**: 3.24.0 or higher (`Channel stable`)
- **Dart SDK**: 3.5.0 or higher
- **Java Development Kit (JDK)**: **Java 17 or Java 21 LTS** (⚠️ *Do NOT use Java 25+, as Gradle 8.14 is incompatible with Java 25*).
- **Android Studio** (for Android emulator / device deployment) or **Visual Studio** (for Windows desktop deployment).

### 2. Clone the Repository

```bash
git clone https://github.com/AREEB-AZHAR/flutter_calculator_new.git
cd flutter_calculator_new
```

### 3. Ensure Compatible JDK Configuration

If you have Android Studio installed with bundled JBR 25, configure Flutter globally to point to your compatible Java 17/21 installation:

```bash
flutter config --jdk-dir "C:\Program Files\Java\jdk-21.0.11"
```

### 4. Fetch Dependencies

```bash
flutter pub get
```

### 5. Verify Toolchain

Ensure all checks pass cleanly:

```bash
flutter doctor -v
flutter analyze
flutter test
```

### 6. Firebase Authentication Setup (Google Sign-In)

To authenticate with your **actual Google Account** across Android and Windows desktop:

1. Go to the [Firebase Console](https://console.firebase.google.com/) and click **Add Project** (e.g. `tally-finance`).
2. Navigate to **Build > Authentication** and enable the **Google** sign-in provider.
3. In **Project Settings > General**:
   - Copy your **Project ID** and **Web API Key**.
   - Under **Your apps**, click **Add app > Android**:
     - **Package Name**: `com.areeb.balance_tracker`
     - **Debug SHA-1**: `B7:71:9D:F2:CA:FE:82:46:4A:B9:91:40:59:C1:72:0B:8E:96:BD:CB`
     - **Debug SHA-256**: `82:E4:2C:AE:78:94:99:F4:F9:7D:3A:8B:16:D9:CB:F9:71:5D:F5:0A:A7:D4:77:E8:FF:1E:67:6C:41:21:EA:99`
     - Download `google-services.json` and place it in `android/app/`.
4. Launch Tally, tap **Sign in with Google**, and enter your **Project ID** & **Web API Key** (or they will auto-load). Your authentic Google Account is now bound to your ledger!

---

## 🚀 Running the Application

### On Mobile (Android Device / Emulator)

```bash
# List available devices
flutter devices

# Run on your connected Android device
flutter run -d <device-id>
```

### On Windows Desktop

```bash
flutter run -d windows
```

### On Chrome / Web

```bash
flutter run -d chrome
```

### On iOS (iPhone Simulator / Physical Device)

```bash
# Install CocoaPods dependencies (macOS)
cd ios && pod install && cd ..

# Run on simulator or attached device
flutter run -d ios
```

---

## 📦 Building Releases

### Android APK

```bash
flutter build apk --release
```

The output APK will be generated at:

- `build/app/outputs/flutter-apk/tally.apk`
- `build/app/outputs/flutter-apk/tally-release.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA / Bundle

```bash
# Build iOS release bundle (requires macOS & Xcode)
flutter build ipa --release
```

### Windows Executable

```bash
flutter build windows --release
```

The output executable will be generated at `build/windows/x64/runner/Release/tally.exe`.

---

## 📝 Recent Changelog

- **v2.2.0 (Current)**:
  - **Precision Goal Reminders & Dynamic Remaining Balance**:
    - Overhauled [`NotificationService.scheduleGoalReminders`](lib/services/notification_service.dart) to calculate the live remaining balance (`remainingToSave`) rather than retaining stale target amounts.
    - Added reactive rescheduling across all goal mutations: creating goals, adding deposits, deleting transactions, and switching currencies immediately update notification alarms.
    - Completed goals automatically cancel pacing reminders to prevent unwanted alerts.
  - **Live Daily Savings Pacing & Amount Left Badge**:
    - Enhanced [`GoalsScreen`](lib/screens/goals_screen.dart) goal cards and detail sheet with a prominent high-contrast **Amount Left** badge (`$X left`).
    - Extended the pacing badge (`Save $X/day · Yd left` or `Save $X today · Due Today`) to **all active goals**, including goals with transactions and goals without explicit calendar dates.
  - **End-of-Day Expiration Guard**:
    - Updated [`SavingsGoal.isExpired`](lib/models/savings_goal.dart) to only expire goals past 23:59:59 on their due date, eliminating mid-day premature goal failure.
  - **Automated Verification Suite**:
    - Created comprehensive unit and widget tests in [`test/goal_pacing_and_notifications_test.dart`](test/goal_pacing_and_notifications_test.dart).
    - All tests passing with 0 analyzer issues.

- **v2.1.0**:
  - **Lock Screen Saved Accounts Manager & Fast Switcher**:
    - Built [`SavedAccountsScreen`](lib/screens/saved_accounts_screen.dart) and [`SavedAccountInfo`](lib/models/saved_account_info.dart) model.
    - Added [`AppDatabase.getAllSavedAccounts()`](lib/services/database/app_database.dart) and `deleteSavedAccount()`.
    - Integrated quick-access badge button and banner pill into [`LoginScreen`](lib/screens/login_screen.dart) and a settings tile into [`ProfileScreen`](lib/screens/profile_screen.dart).
    - Supports 1-tap Biometric unlock, 1-tap Google sign-in, password auto-selection, and safe account removal.
  - **Comprehensive Multilingual UI Localization Across 7 Languages**:
    - Expanded all 7 dictionary maps in [`LanguageService`](lib/services/language_service.dart) (`en`, `es`, `fr`, `de`, `ur`, `ar`, `hi`).
    - Replaced hardcoded UI strings with `LanguageService.tr(...)` across [`MainNavScreen`](lib/screens/main_nav_screen.dart), [`DashboardScreen`](lib/screens/dashboard_screen.dart), and [`LoginScreen`](lib/screens/login_screen.dart).
  - **Feature Tour Deduplication & Concurrency Mutex**:
    - Added static concurrency guard `_isTourOpen` in [`FeatureTourDialog`](lib/widgets/feature_tour_dialog.dart).
    - Removed redundant tour triggers in [`ProfileScreen`](lib/screens/profile_screen.dart) during tab redirection to prevent back-to-back duplicate modals.
  - **Automated Verification Suite**:
    - Created comprehensive test suite in [`test/language_tour_saved_accounts_test.dart`](test/language_tour_saved_accounts_test.dart) covering translations, tour concurrency, and saved account rendering.
    - All tests passing with 0 analyzer issues.

- **v1.9.3**:
  - **100,000 Transactions Stress & Scalability Benchmark**:
    - Conducted empirical stress benchmarks on 100,000 recorded transactions in [`test/benchmark_100k_transactions_test.dart`](test/benchmark_100k_transactions_test.dart).
    - **Atomic Single-Record Persistence**: Eliminated the legacy wipe-and-reinsert pattern in [`AppDatabase`](lib/services/database/app_database.dart). Adding a new transaction or deleting a transaction now uses atomic `insertTransaction` and `deleteSingleTransaction` operations taking only **12 ms** (down from 20+ seconds when rewriting 100k rows).
    - **Compound Database Index**: Added index `idx_transactions_username_date` on `transactions(username, date DESC)`, accelerating query retrieval and startup hydration.
    - **In-Memory Ledger Benchmarks**:
      - 100k transactions cumulative balance calculation (`.fold`): **3 ms**.
      - 100k transactions real-time search & filter (`.where`): **25 ms** across 66,666 matches.
      - 100k transactions SQLite deserialization into models: **2,035 ms**.
  - **On-Demand Tab Lifecycle, Destruction & Instant Rehydration**:
    - Optimized [`MainNavScreen`](lib/screens/main_nav_screen.dart) with on-demand widget rebuilding: off-screen tabs are actively destroyed and discarded from the element tree when switching tabs, freeing memory, GPU textures, and ticker resources.
    - Tab state is preserved in high-speed in-memory `AppState` ValueNotifiers and rehydrated instantaneously upon navigation with 0ms delay.
    - Guarded [`DashboardScreen`](lib/screens/dashboard_screen.dart)'s 800ms intro animation with `DashboardScreen.hasAnimatedIntro` so switching between tabs doesn't restart heavy intro animations.
  - **Scrubbed Local Filesystem Paths**:
    - Completely audited and sanitized [`README.md`](README.md), removing all machine-specific absolute file paths (`file:///c:/Users/areeb/...`) in favor of clean, portable repository-relative paths.

- **v1.9.2**:
  - **Butter-Smooth Fintech Logout & Biometric Lifecycle Architecture**:
    - **Decoupled Explicit Logout from App Lock**:
      - Modeled after top-tier financial and banking applications (such as Revolut, Monzo, and Chase) to strictly differentiate between **Explicit Account Sign-Out** and **App Lock / Quick Resume**.
      - Added an `isExplicitLogout` guard in [`BiometricService`](lib/services/biometric_service.dart). When a user taps **Log Out**, the app respects their intent and suppresses the 400ms automatic biometric sensor popup on [`LoginScreen`](lib/screens/login_screen.dart), eliminating the frustrating loop of being ambushed to re-enter the account they just abandoned.
      - Retains the dedicated, stylish `[ Unlock with Screen Lock ]` button on the login screen, allowing intentional one-tap biometric access without non-consensual auto-prompts.
      - Cold-start and app-launch quick unlock remain fully active for convenient session resumption.
    - **Zero-Stutter, 60/120 FPS Logout Navigation**:
      - Centralized session termination into [`AppState.logout(BuildContext context)`](lib/services/state.dart), executing a root-level `pushAndRemoveUntil` transition with a buttery-smooth 200ms `FadeTransition`.
      - Unmounts `MainNavScreen`, `ProfileScreen`, and all dashboard analytics in 1 frame (0ms UI latency), completely resolving the 3-4 second lag and frame stutter previously experienced on logout.
      - Offloaded heavy platform-channel operations ([`NotificationService.cancelAllReminders()`](lib/services/notification_service.dart) and [`GoogleAuthService.signOut()`](lib/services/google_auth_service.dart)) to non-blocking asynchronous background futures (`unawaited`), freeing the main rendering thread.
      - Eliminated accidental tab-switching to Dashboard (tab 0) during logout, preventing chart recalculations and heavy widget lifecycles from mounting mid-transition.
      - Removed the competing `if (AppState.currentUser == null)` post-frame navigation callback in [`MainNavScreen.build()`](lib/screens/main_nav_screen.dart) that caused double-navigation race conditions.
    - **Removed Intrusive Post-Login Biometric Modal**:
      - Removed the recurring `showBiometricSetupPrompt` modal dialog from [`DashboardScreen`](lib/screens/dashboard_screen.dart). Users are no longer interrupted upon login; biometric enrollment is managed securely in **Profile > Security > Screen Lock / Biometrics**.
    - **Comprehensive Test Suite & Zero Linter Warnings**:
      - Added `test/logout_biometric_smoothness_test.dart` verifying explicit logout state machines, session nullification, and user-scoped biometric configurations.
      - Ran full test suite and `flutter analyze` with 0 errors and 0 warnings.

- **v1.9.1**:
  - **Flutter Web Engine & Cross-Platform Layout Hardening**:
    - **Subpixel Floating-Point RenderFlex Overflow Fix**:
      - Resolved `A RenderFlex overflowed by 0.00000255 pixels on the bottom` during `SplashScreen` to `LoginScreen` Hero wordmark flight.
      - Wrapped `TallyWordmarkWidget`'s Column in `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center)`, eliminating yellow-and-black striped layout overflow warnings across all browser zoom levels and mobile viewports.
    - **Firebase Google Sign-In Web Popup Flow**:
      - Fixed `UnimplementedError: signInWithProvider() is not implemented` when clicking "Sign in with Google" on Web.
      - Implemented conditional `FirebaseAuth.instance.signInWithPopup(googleProvider)` for web clients, launching the official Google OAuth browser popup window and linking seamlessly to SQLite/Firestore ledgers.
    - **Web-Safe Notification & Biometric Service Guards**:
      - Guarded `NotificationService`'s `init()`, `scheduleAllDailyReminders()`, `cancelAllReminders()`, `scheduleLoanReminder()`, and `showInstantAlert()` with `kIsWeb` guards and try-catch wrappers, eliminating unsupported `zonedSchedule()` web exceptions.
      - Guarded `BiometricService` with `kIsWeb` platform checks, gracefully bypassing missing `local_auth` platform channels on web without throwing `MissingPluginException`.
    - **Web Text Editing Focus Detachment Protection**:
      - Updated `LoginScreen` `SingleChildScrollView` to use `keyboardDismissBehavior: kIsWeb ? ScrollViewKeyboardDismissBehavior.manual : ScrollViewKeyboardDismissBehavior.onDrag`, eliminating the Flutter Web HTML/CanvasKit engine assertion `domElement != null`.
    - **Cross-Platform Test Suite**:
      - Added `test/web_compatibility_test.dart` verifying tight boundary layout scaling, notification exception safety, and biometric graceful fallbacks.
      - All 61 automated unit, widget, and frame timing tests passing with 0 analyzer warnings.

- **v1.9.1**:
  - **Comprehensive Cross-User State Isolation & Entitlement Scoping**:
    - **Theme & Palette Isolation**: Resolved cross-user theme carry-over where logging into a secondary account on the same device retained the previous user's theme (e.g. premium palettes). Active themes and custom colors are now strictly user-scoped in `SharedPreferences` (`tally_active_theme_<user>`, `tally_primary_color_<user>`).
    - **Free Tier Theme Sanitization**: In [`AppState.loadAllUserData()`](lib/services/state.dart), accounts on the free tier that had legacy premium themes or studio modifications are automatically sanitized to `Ledger` defaults (`#E4572E` primary, `#F6F0E1` secondary), while Pro users retain their unlocked themes.
    - **Clean Account Registration**: Updated [`AppDatabase.registerUser()`](lib/services/database/app_database.dart) and [`AppDatabase.authenticateOrRegisterGoogleUser()`](lib/services/database/app_database.dart) to strictly initialize new user profiles with clean `Ledger` defaults rather than copying active global preferences from prior sessions.
    - **User-Scoped Biometric & Screen Lock Enrollment**: Scoped biometric unlock states to `tally_biometric_enabled_<user>` in [`BiometricService`](lib/services/biometric_service.dart). Fixed a critical defect where password or Google sign-in previously auto-enrolled whatever user logged in if the prior user had biometrics enabled. Toggling biometrics for User B no longer affects User A.
    - **Independent Onboarding Tours**: Scoped walkthrough flags (`tally_tour_home_completed` and `tally_tour_accounts_completed`) per user in [`TourService`](lib/services/tour_service.dart), ensuring every new user on a shared device receives the full onboarding experience.
    - **Isolated Notification Preferences & Scheduled Alerts**: Reminders in [`NotificationService`](lib/services/notification_service.dart) are scoped per user (`tally_reminders_enabled_<user>`). On user logout, all active scheduled reminders (daily check-ins, loans, planned transactions) are cancelled. On login, only the active user's notifications are scheduled.
    - **Google & Firebase Auth Disconnection on Logout**: Added `GoogleAuthService.signOut()` to [`AppState.clearUserSession()`](lib/services/state.dart). Added email matching guards in [`CloudSyncService`](lib/services/cloud_sync_service.dart) ensuring local accounts never sync data into a prior user's Firestore vault.
    - **Full Account Migration (Loans & Planned Transactions)**: Extended [`AppDatabase.migrateAndMergeUserData()`](lib/services/database/app_database.dart) and [`AppDatabase.deleteLocalUser()`](lib/services/database/app_database.dart) to migrate and purge `loans` and `planned_transactions`, preventing orphaned records.
  - **Undo Banner 5-Second Auto-Dismissal Timer**:
    - Added an automatic 5-second countdown timer across all delete operations (`deleteTransactionWithUndo`, `deleteGoalWithUndo`, budget deletion, account deletion, and loan deletion).
    - Tapping "Undo" immediately cancels the dismissal timer and restores the deleted record seamlessly.
  - **High-Performance On-Demand Page Lifecycle (<100ms)**:
    - Replaced eager `IndexedStack` in [`MainNavScreen`](lib/screens/main_nav_screen.dart) with on-demand screen building (`_buildActiveScreen`).
    - Inactive tabs are discarded and unmounted immediately upon navigation, freeing GPU textures, tickers, and streams to eliminate background memory lag while instantiating new pages in under 25ms.
  - **Automated Verification Suite**:
    - Created comprehensive test suite in [`test/account_theme_isolation_test.dart`](test/account_theme_isolation_test.dart) verifying theme isolation, free tier sanitization, 5-second undo timer auto-dismissal, on-demand navigation lifecycle, tour isolation, biometric scoping, notification preference isolation, and loan/plan account migration.
    - All 71 automated tests passing cleanly with 0 analyzer issues.

- **v1.9.0**:
  - **Recalculated Pro Pricing & Fintech Unit Economics**:
    - Recomputed Pro pricing matrix to eliminate inversion anomaly (where Lifetime was previously cheaper than 1 Year) and establish standard subscription economics:
      - **Monthly Plan**: **$2.99 / month** — affordable entry point for budgeting power features.
      - **Annual Plan**: **$19.99 / year** ($1.67 / mo) — grants **44% savings** over monthly billing with "Best Value" highlight.
      - **Lifetime Access**: **$39.99 one-time** — 2.0x annual price; pay once and own Tally Pro forever.
      - **Remove Ads Only**: **$1.99 one-time** — standalone microtransaction for users wanting an ad-free interface.
      - **Buy Me a Coffee**: **$2.99 one-time** — community support tip + permanent ad removal + 7-day Pro trial.
  - **Official Google Play Billing Integration (`in_app_purchase`)**:
    - Wired official Flutter `in_app_purchase: ^3.3.1` plugin with `com.android.vending.BILLING` permission in `AndroidManifest.xml`.
    - Implemented `InAppPurchaseService` (`lib/services/in_app_purchase_service.dart`) managing store connections, product inquiries (`tally_pro_monthly`, `tally_pro_yearly`, `tally_pro_lifetime`, `tally_remove_ads`, `tally_coffee_tip`), purchase event streams, `completePurchase()`, and `restorePurchases()`.
    - Integrated defensive lazy evaluation of `InAppPurchase.instance` preventing unmocked Pigeon platform channel exceptions on Windows desktop and during unit tests.
    - Updated `PremiumScreen` with real-time pending states, dynamic store product prices, and a dedicated **"Restore Purchases"** action.
  - **Non-Skippable 30-Second Rewarded Ad & 1-Time Theme Unlock Passes**:
    - Integrated Google Mobile Ads official rewarded video test unit IDs (`ca-app-pub-3940256099942544/5224354917` Android, `ca-app-pub-3940256099942544/1712485313` iOS) via `AdService.showRewardedThemeAd`.
    - Created authentic cross-platform `Fullscreen30SecAdDialog` (`lib/widgets/fullscreen_30sec_ad_dialog.dart`) with 30-second countdown timer (`30s` down to `0s`), animated progress indicator, non-skippable `PopScope` exit-prevention modal, and interactive reward claim celebration.
    - Built **Theme Pass Inventory System**: watching a full 30s ad grants **+1 Theme Pass** stored persistently in `AppState.themePassesNotifier`.
    - Extended brand presets to 9 options: 3 base free (`Ledger`, `Paper`, `Ink`) and 6 premium presets (`Violet Night`, `Ocean Blue`, `Emerald Dark`, `Rose Gold`, `Sunset Orange`, `Midnight Teal`).
    - Gated premium presets and Graphic Theme Studio custom sliders on the Free tier behind 1-time Theme Pass consumption, with instant 1-tap option to watch a 30s ad or upgrade to Pro.
    - Added secret QA promo code `THEMEPASS` granting 3 passes for instant testing.
  - **Comprehensive QA Test Suite**:
    - Added `test/pro_pricing_iap_rewarded_ads_test.dart` verifying pricing constants, Theme Pass granting/consumption, promo code redemption, and 30s ad dialog widget interactions.
    - All 58 automated unit and widget tests passing cleanly with 0 analyzer issues.

- **v1.8.4**:
  - **Zero-Glitch Dynamic Palette Engine & Theme Alignment**:
    - Replaced 4 nested `ValueListenableBuilder`s in `main.dart` and `profile_screen.dart` with a single unified `AnimatedBuilder(animation: Listenable.merge([themeNameNotifier, customPrimaryColorNotifier, customSecondaryColorNotifier, customTextColorNotifier]))`.
    - Eliminated cascading 4-frame rebuild glitches and intermediate color flashes when changing themes.
    - Configured `themeAnimationDuration: const Duration(milliseconds: 150)` and `Curves.easeInOut` for smooth, polished color transitions.
    - Adjusted semantic colors (`positiveColor`, `negativeColor`, `warningColor`, `planAccent`) across `InteractiveChartCard`, `PlannedTransactionsSheet`, `TransactionDialog`, and `AccountsScreen` for high-contrast legibility in both light (`Paper`) and dark/carbon (`Ledger`, `Ink`) themes.
    - Repainted charts immediately on theme changes by verifying secondary, text, and empty colors in `YearlyLineChartPainter.shouldRepaint`.
  - **Transparent Multi-Tier Pricing & Developer Coffee Gift**:
    - **Monthly Plan**: $4.99/mo.
    - **Annual Plan**: $49.90/yr ($4.99 × 10, granting 2 full months free) with "Best Value" highlight badge.
    - **Lifetime Access**: $47.88 one-time ($3.99 × 12, ultimate permanent value).
    - **"Buy Me a Coffee"**: $1.99 one-time community support tier removing ads forever and granting a 7-Day Tally Pro trial pass as a special thank-you gift.
    - Integrated native simulated Google Pay / Apple Pay bottom sheet checkout with instant receipt generation and persistent state synchronization.
  - **Accounts Receivable & Payable (Loans & Debts) Ledger**:
    - Dedicated "Loans & Debts" segment tab on `AccountsScreen`.
    - Distinct tracking of **Receivables** (Money Lent Out) and **Payables** (Money Borrowed).
    - Real-time summary metrics: Total Receivable, Total Payable, and Net Balance position.
    - Push notifications: Automatically scheduled local notifications reminding the user on due/reminder dates (e.g. *"Reminder: Did you receive $X from Person?"* or *"Payment Due: $X to Person is scheduled for today."*).
    - One-tap loan settlement updating records in SQLite.
  - **Automated Recurring & Future Planned Transactions**:
    - Automated recurring engine evaluating daily/weekly/monthly recurring rules on app launch and user login, posting matured instances into SQLite with duplicate protection.
    - Dedicated "Planned & Future Sheet" (`PlannedTransactionsSheet`) allowing staging, inspection, and early "Post Now" execution of upcoming financial commitments.
  - **Single-Scroll Dynamic Search & Tri-Mode Interactive Chart Analytics**:
    - Converted `AllTransactionsScreen` to a unified, conflict-free `CustomScrollView`.
    - Real-time search query filtering recalculating transaction counts, income/expense totals, and charts dynamically as user types.
    - Tri-mode visualizer supporting Segmented Donut, Daily Line Flow, and Bar Charts with Year and Month scope toggles.
  - **Two-Way Deletion Reconciliation**:
    - Full bidirectional reconciliation protocol in `CloudSyncService.sync`: any cloud documents whose IDs are missing from local SQLite storage are safely purged from Firestore, guaranteeing local deletions are 100% authoritative and permanent across all devices.
  - **Comprehensive QA Test Suite**:
    - Added `test/loans_recurring_analytics_test.dart` and `test/theme_alignment_switching_test.dart`.
    - All 49 automated unit, widget, and frame timing tests passing with 0 errors and 0 analyzer warnings.

- **v1.8.3**:
  - **Google Account Profile Photo Synchronization**:
    - Fixed critical bug where uploaded custom profile photos were not syncing to the cloud when connected to Google, or were inadvertently replaced by Google's default silhouette.
    - Implemented `ImageHelper` (`lib/utils/image_helper.dart`) to provide robust, dual-source image resolution for both local filesystem paths (`FileImage`) and remote cloud URLs (`NetworkImage`), with seamless fallback to high-resolution brand avatar assets.
    - Added automated base64 encoding and cloud synchronization in `CloudSyncService.syncProfileToCloud` and `CloudSyncService.sync`, ensuring custom avatars are safely stored in Firestore and restored across all devices.
    - Protected user-uploaded photos in `AppDatabase.authenticateOrRegisterGoogleUser` so connecting to Google never overwrites custom profile pictures.
  - **Account Deletion Persistence & Zombie Account Fix**:
    - Resolved account resurrection bug where accounts deleted on the Accounts screen would reappear upon the next login or cloud sync.
    - Diagnosed and eliminated the flawed cloud-length-greater-than-local heuristic in `CloudSyncService.sync`.
    - Made local deletions authoritative: implemented `CloudSyncService.syncAccountsToCloud` and hooked `AppState.saveAccounts` to immediately synchronize active accounts and delete stale account documents from Firestore.
  - **Real-Time Transaction & Goal Cloud Deletions**:
    - Fixed transaction and goal resurrection during cloud sync: previously, deleting a transaction locally in SQLite left orphaned documents in Firestore that were restored during subsequent syncs.
    - Added `deleteTransactionFromCloud`, `deleteGoalFromCloud`, and `syncGoalsToCloud` to `CloudSyncService`.
    - Hooked `AppState.deleteTransactionWithUndo` directly to cloud deletion routines with instant re-sync if the user taps Undo.
    - Implemented full deletion reconciliation in two-way cloud sync: any cloud documents whose IDs no longer exist in the local SQLite ledger are safely purged from Firestore.
  - **Local Account Deletion & Cleanup on Google Migration**:
    - Implemented automatic cleanup of the local account upon Google sign-in/account binding (`AppDatabase.deleteLocalUser`).
    - When a user chooses "Migrate & Merge Data" or "Use Google Account", all local records (users, profiles, transactions, accounts, budgets, goals) belonging to the temporary local account are deleted, preventing orphaned duplicate accounts on device.
  - **Dedicated Tally Pro & Ad-Free Screen with Google Pay**:
    - Created a dedicated, state-of-the-art monetization hub (`PremiumScreen` in `lib/screens/premium_screen.dart`), accessible directly from a prominent VIP Membership card on the Profile page.
    - Completely removed cluttered inline monetization tiles from settings.
    - Features an authentic Google Pay bottom sheet modal flow with merchant details, itemized breakdown, simulated biometric authorization, and instant activation.
    - Offers transparent pricing tiers: **Tally Pro Lifetime Access** ($4.99) and **Remove Ads Only** ($1.99).
    - Includes VIP promo code redemption (`PROVIP`, `NOADS`) and an instant **"Reset VIP Subscription"** button for developer & QA testing.
  - **Frame Rate Optimization & Stutter Elimination**:
    - Resolved UI sluggishness and compositor frame drops during scrolling:
      - Wrapped vector custom painters (`InteractiveChartCard`), `AdBannerWidget`, and heavy ambient background radial gradients in `RepaintBoundary` to isolate GPU texture composition layers.
      - Replaced un-bounded `ListView.builder(shrinkWrap: true)` on Dashboard recent transactions with an unrolled `Column` of isolated `TransactionTile` widgets, eliminating nested scrolling passes and compositor stalls.
  - **Tamper-Proof Firebase & Google Cloud Security**:
    - Created hardened `firestore.rules` enforcing strict per-user UID isolation: `allow read, write: if request.auth != null && request.auth.uid == userId;`.
    - Prevents any unauthorized tampering, inspection, or manipulation of financial records by anyone other than the authenticated user and developer console.
  - **iOS Platform Deployment Readiness**:
    - Configured `ios/Runner/Info.plist` with `CFBundleDisplayName: "Tally"`.
    - Added user-facing privacy usage descriptions for `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSFaceIDUsageDescription`.
    - Configured Google Mobile Ads SDK for iOS (`GADApplicationIdentifier: ca-app-pub-3940256099942544~1458002511` and SKAdNetwork items).
  - **Comprehensive QA Test Suite**:
    - Added `test/cloud_sync_premium_image_test.dart` verifying ImageHelper URL/file classification, provider resolution, and complete `PremiumScreen` widget interactions.
    - All 38 automated unit, widget, and frame smoothness benchmark tests passing with 100% success.

- **v1.8.2**:
  - **Google Account Binding & Data Migration / Conflict Resolution**:
    - Fixed critical bug where linking/binding a Google account from an existing local session treated the Google account as brand new, replacing local ledger views with empty state.
    - Added dual-layer conflict detection checking both Google Cloud Firestore (`CloudSyncService.hasCloudData`) and SQLite (`AppDatabase.hasUserData`).
    - If existing cloud data is detected, an interactive dialog allows the user to either **"Migrate & Merge Data"** (merging local transactions, accounts, budgets, goals, and profile preferences into the Google account and syncing to cloud) or **"Use Google Account Data As-Is"**.
    - If no existing cloud data is found, seamlessly migrates all local ledger data directly to the Google account and immediately syncs to Cloud Firestore.
  - **Bound Recovery Email Architecture & Forgot Password Reset Flow**:
    - Transitioned registration and authentication from username-only to requiring bound recovery email addresses.
    - Updated database schema with a non-destructive migration adding `email` column to `users` table in `lib/services/database/app_database.dart`.
    - Added full **"Forgot Password?"** dialog on `LoginScreen` with bound email lookup, real Firebase password reset email dispatching, and in-app secure password reset.
    - Added recovery email status badge and **"Bind Recovery Email"** interactive dialog in Profile Settings for existing local accounts.
    - Authentication supports logging in seamlessly with either the canonical username or the bound recovery email.
  - **Strong Password Security System**:
    - Built comprehensive password validation engine (`PasswordValidator` in `lib/utils/password_validator.dart`) enforcing strict criteria:
      1. At least 10 characters long
      2. At least 1 uppercase letter (A-Z)
      3. At least 1 lowercase letter (a-z)
      4. At least 1 special character (`!@#$%^&*...`)
      5. At least 3 numbers (`0-9`)
    - Integrated real-time live security requirement checklist in registration and password reset dialogs with animated visual checkmarks and strength indicator.
  - **VIP Subscription Reset Capability for Testing**:
    - Added a dedicated **"Reset VIP Subscription (Test Mode)"** button directly inside the Monetization card on the Profile screen, allowing testers to immediately revert back to the Free tier after entering VIP mode.
    - Extended promo code redemption engine (`MonetizationService.redeemPromoCode`) to support `RESETVIP`, `RESET`, `RESETPRO`, `FREE`, and `FREEVIP` codes.
  - **Authentic Google Mobile Ads (AdMob) Integration**:
    - Integrated `google_mobile_ads: ^9.1.0` and configured AdMob Application ID meta-data in `android/app/src/main/AndroidManifest.xml`.
    - Created `AdService` (`lib/services/ad_service.dart`) with safe initialization and standard Google AdMob test banner ad unit IDs (`ca-app-pub-3940256099942544/6300978111`).
    - Updated `AdBannerWidget` to dynamically render real Google `AdWidget(ad: _bannerAd)` on supported mobile devices with a "Remove Ads" action, while providing a graceful sponsored fallback on desktop (Windows) and web.
- **v1.8.5**:
  - **Fixed Password Reset: Cloud Function OTP Email Delivery**:
    - **Root Cause Fix**: Resolved critical bug where Firebase's `sendPasswordResetEmail()` only updated the Firebase Auth password, while login validation checks against locally hashed SQLite credentials — causing password resets to silently fail at login.
    - **Firebase Cloud Function (`sendOtpEmail`)**: Created a new Cloud Function (`functions/index.js`) using `nodemailer` to deliver a beautifully formatted HTML email containing the 6-digit OTP verification code directly to the user's inbox.
    - **Removed Firebase Auth Reset Dependency**: Eliminated `FirebaseAuth.instance.sendPasswordResetEmail()`, `verifyPasswordResetCode()`, and `confirmPasswordReset()` from the password reset flow. The entire reset pipeline now stays within the app: OTP emailed → user enters code → local SQLite password hash updated.
    - **Cloud Functions Package**: Added `cloud_functions: ^6.5.0` to `pubspec.yaml` and replaced the `firebase_auth` import in `login_screen.dart` with `cloud_functions`.
    - **Resend Code Fix**: Updated the "Resend Code" handler to call the Cloud Function with the newly generated OTP instead of sending a Firebase reset link.
- **v1.8.1**:
  - **Theme-Adaptive Deletion Warning Confirmation Dialog**:
    - Created `delete_confirmation_dialog.dart` featuring a modern modal with a danger icon container, highlighted item detail preview (e.g. `Groceries • -$45` or `Japan Vacation • Target: $3,500`), undo reminder note, Cancel action, and high-contrast red Delete confirmation button.
    - Integrated with `Dismissible` in `transaction_tile.dart`: swiping a transaction presents the warning dialog. Tapping Cancel snaps the tile back smoothly with zero deletion.
  - **Universal Undo Option for Transactions Across ALL Screens**:
    - Centralized `AppState.deleteTransactionWithUndo(context, tx)` across every view where transactions can be deleted:
      - **DashboardScreen** (Main Screen)
      - **AllTransactionsScreen**
      - **AccountsScreen**
      - **TransactionDialog** (added direct Delete action inside edit modal for existing transactions)
    - Displays a SnackBar with `"[Title]" deleted` and high-contrast amber **Undo** button. Tapping Undo restores the transaction to its chronological position and updates SQLite persistence reactively.
  - **Goal Deletion Warning Dialog & Universal Undo**:
    - Gated goal deletion on `goals_screen.dart` with the confirmation warning dialog.
    - Implemented `AppState.deleteGoalWithUndo(context, goal)` providing instant restoration via an Undo SnackBar.
  - **Budget & Account Deletion Safety**:
    - Added deletion confirmation warning and Undo SnackBar when removing a budget cap on `dashboard_screen.dart` and when removing an account on `accounts_screen.dart`.
  - **Windows C++ Compiler & Deprecation Fixes**:
    - Added `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` in `windows/CMakeLists.txt` for `local_auth_windows`.
    - Cleaned stale plugin references and removed unused imports in test suites.
  - **Firebase Authentication Engine for Real Google Sign-In (Android & Windows)**:
    - Integrated `firebase_core: ^4.15.0` and `firebase_auth: ^6.7.0` in `google_auth_service.dart` for authentic Google account authentication.
    - Completely eliminated the mock dialog and dummy account (`areeb.finance@gmail.com`). Every sign-in now binds the user's authentic Google Account credentials to SQLite.
    - Architected `DefaultFirebaseOptions` (`lib/firebase_options.dart`) with runtime persistence via `SharedPreferences` and conditional Gradle plugin application in `android/app/build.gradle.kts`.
    - Added an interactive Firebase Setup Modal in Tally showing pre-extracted SHA-1 and package name with 1-tap clipboard copy buttons and instant project configuration.
  - **Cloud Firestore Encrypted User Vault & Two-Way Sync**:
    - Integrated `cloud_firestore: ^6.10.0` with `CloudSyncService` (`lib/services/cloud_sync_service.dart`) for secure, per-user data synchronization.
    - Synchronizes profiles, accounts, budgets, goals, and transactions under private paths `/users/{uid}/...` protected by Firebase security rules.
    - Added reactive sync state management (`isSyncingNotifier`, `lastSyncTimeNotifier`) with live status indicators ("CONNECTED", "SYNCING") and a manual "Sync Now" trigger in `ProfileScreen`.
    - Implemented `windows/compat/atlbase.h` fallback shim and `APPLY_STANDARD_SETTINGS` compiler definitions to guarantee clean cross-platform C++ compilation on Windows.
- **v1.8.0**:
  - **Tally Pro Freemium Monetization & Power Feature Gating**:
    - Architected `MonetizationService` tracking `isProUnlockedNotifier`, `isAdsRemovedNotifier`, `isPro`, and `isAdFree` with persistent local storage.
    - **Smart Insights Gate & Preview Paywall**: Wrapped `insights_screen.dart` with a Pro lock. Free users see an attractive frosted preview lock screen displaying daily velocity indicators, savings rate forecast mockups, feature checklists, an "Unlock Tally Pro — \$4.99" CTA button, and "Redeem Promo Code" action. Pro users enjoy instant access to full analytical reports.
    - **Theme Studio Gate**: Gated custom RGB/HSV sliders, text tone adjustments, and custom color wheels behind Pro with lock badges and paywall prompts; curated brand presets (Ledger, Paper, Ink) remain accessible to all users.
    - **Launcher App Icon Gate**: Gated dynamic Android launcher app icon switching behind Pro.
  - **Separate "Remove Ads" Purchase (\$1.99)**:
    - Added a dedicated separate "Remove Ads" option in the Profile Settings bottom sheet, giving users the freedom to banish all banner ads permanently without paying for the full Pro analytical bundle.
  - **VIP Promo Code Unlock Modal**:
    - Created an interactive redemption modal (`MonetizationService.showPromoCodeDialog`) accepting codes `PROVIP` / `FINTECH2026` (unlocks full Tally Pro) and `NOADS` (unlocks ad-free tier), with an instant "Reset to Free Tier" button for testing.
  - **Native Contextual Partner Ad Banners**:
    - Implemented `ad_banner_widget.dart` featuring high-trust fintech partner card designs with an "Ad" badge, financial benefit copies (e.g. YieldMax 5.2% APY Savings, Cloud Multi-Currency Vault, Expense Categorization Engine), and a "Hide" shortcut that opens the paywall.
    - Embedded banner ads between Balance Card / Chart and Recent Transactions on `dashboard_screen.dart`, and on `accounts_screen.dart` and `all_transactions_screen.dart`.
    - Banners automatically render `SizedBox.shrink()` (0 pixels) when Pro is unlocked or ads are removed.
  - **Google Account Authentication & Secure Cloud Data Binding**:
    - Integrated `google_sign_in: ^7.2.0` with `GoogleAuthService` supporting native 1-tap Google Sign-In on mobile/web and an authentic Google Account Picker dialog fallback for Windows desktop and emulators.
    - Extended `app_database.dart` with `authenticateOrRegisterGoogleUser()` to bind all SQLite accounts, transactions, budgets, goals, and profiles directly to verified Google email accounts.
    - Added an authentic Google Account Status badge (`[G] Bound to Google: user@email.com`) to the Profile header with 1-tap cloud binding for existing users.
  - **2026 Industry Best Practices & Competitive Benchmarks**:
    - Synthesized comprehensive competitive research across leading personal finance apps (**Monarch Money**, **Copilot**, **YNAB**, **Splitwise**, **Empower**, and **NerdWallet**) in `FUTURE_MONETIZATION_PLAN.md`.
    - Documented architectural blueprints for Value-Based Gating ("Tracking" vs "Planning"), Native Financial Partner Banners vs Programmatic Networks, Decoupled Ad-Free passes, Local-First SQLite Cloud Vaults, and Progressive Disclosure Onboarding.
- **v1.7.3**:
  - **Button Text & FAB Icon Contrast Fix (Ink & Paper Themes)**:
    - **Luminance-Adaptive Foregrounds**: Dynamically computes contrast-compliant foreground colors (`btnBg.computeLuminance() > 0.5 ? Color(0xFF152A22) : Colors.white`) across all `ElevatedButton` widgets and `FloatingActionButton` controls.
    - **Savings Goals Screen Overhaul**: Eliminated invisible white-on-white text in `GoalsScreen`'s "Add Funds" button and `+` icon on the Floating Action Button. When goals are completed (`progress >= 1.0`), the `Colors.greenAccent` background adapts to dark ink text (`#152A22`) for guaranteed legibility.
    - **Dashboard FAB Contrast**: Updated `DashboardScreen` Floating Action Button with luminance-aware icon foreground color.
    - **Theme Collisions & Legacy Profile Protection**: Updated `buildDynamicTheme` in `constants.dart` to protect against primary/secondary colors colliding with `preset.surface` or washing out to pure white/cream in Paper and Ink themes, auto-healing legacy profile data.
    - **Global Theme Defaults**: Configured `floatingActionButtonTheme` and updated `elevatedButtonTheme` with `onPrimary` contrast calculation.
- **v1.7.0**:
  - **Dynamic App Launcher Icon Switching**:
    - Generated custom-crafted, high-resolution launcher icons for all three brand styles (**Ledger**, **Paper**, and **Ink**) across all Android mipmap densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
    - Configured native `<activity-alias>` entries in `AndroidManifest.xml` targeting `.MainActivity` (`MainActivityLedger`, `MainActivityPaper`, `MainActivityInk`).
    - Implemented a native Kotlin `MethodChannel` (`com.areeb.tally/app_icon`) in `MainActivity.kt` and Dart service `AppIconService` allowing instant runtime launcher icon switching via `setComponentEnabledSetting(..., DONT_KILL_APP)`.
  - **Global Persistent Theme Across App Restarts & Exit**:
    - Added `AppState.initGlobalTheme()` which restores the user's selected theme and custom color palette from `SharedPreferences` in `main.dart` *before* `runApp()`.
    - Eliminated theme reset on app exit and cold restart: Tally immediately boots into the user's saved theme.
  - **Full Startup Theming (Splash & Login Screens)**:
    - Updated `SplashScreen` to dynamically render with the active theme's background color, animated icon colors (e.g. Ink's carbon black, cream strokes, and amber slash), and wordmark styling.
    - Updated `LoginScreen` to dynamically render with the user's saved theme (e.g. if Ink is chosen, login form card, input fields, borders, and buttons match Ink's dark carbon palette and cream typography).
- **v1.7.3**:
  - **Category Name Fallback for Transaction Titles**:
    - When adding transactions without manually typing a title, Tally automatically uses the selected category name as the default title.
    - Updated [transaction_dialog.dart] to show dynamic placeholder hints (`Default: <Category>`) and validate amount independently.
  - **Custom Transaction Date Selection & Chronological Ledger Sorting**:
    - Added an interactive transaction date picker in the unified transaction dialog.
    - Users can now select and change the exact date of any transaction (past, present, or future) with formatted date indicators (`formatDateWithYear`).
    - Automatically maintains strict descending chronological sorting across the entire ledger.
  - **Mobile Screen Lock & Biometric Unlock (Face ID, Fingerprint, Device PIN)**:
    - Integrated native device authentication using [BiometricService] powered by `local_auth`.
    - Updated `MainActivity.kt` to extend `FlutterFragmentActivity` and enabled `android.permission.USE_BIOMETRIC`.
    - Added a toggle switch in Settings/Profile under Account Security with confirmation authentication.
    - Added one-tap **"Unlock with Screen Lock"** button and smooth auto-prompting on [login_screen.dart].
  - **Live Reactive Currency Synchronization (Zero App Relaunch Required)**:
    - Resolved bug where switching currency symbols from the homepage or settings failed to update active screens without relaunching the app.
    - Wrapped all viewports and widgets [DashboardScreen], [AccountsScreen], [GoalsScreen], [InsightsScreen], [AllTransactionsScreen], [InteractiveChartCard], [TransactionTile] with `ValueListenableBuilder<String>`.
    - Added unified `AppState.setCurrency()` that instantly persists to `SharedPreferences` and the SQLite user profile, while immediately re-rendering all financial totals and transaction lists live.
  - **Future Monetization Strategy Blueprint**:
    - Architected and documented [FUTURE_MONETIZATION_PLAN.md] covering Tally Pro freemium gates, privacy-preserving native ads, tip jars, and RevenueCat integration.
- **v1.8.2**:
  - **Google Account Binding & Smart Data Migration**:
    - Resolved account binding conflict where linking a Google account to an existing local account previously created a blank new account.
    - Added automated cloud/local conflict detection via `AppDatabase.hasUserData()` and `CloudSyncService.hasCloudData()`.
    - If existing cloud data is detected, an interactive dialog allows users to either **"Migrate & Merge"** local transactions, accounts, budgets, and goals into the Google account or **"Use Cloud Data"**.
    - If no existing data is connected to the Google account, local data is automatically migrated into the Google account seamlessly.
  - **Bound Recovery Email & Forgotten Password Reset**:
    - Extended SQLite `users` table schema with an `email` column via non-destructive database migration.
    - Updated registration and login to support authentication by either **Username** or **Recovery Email**.
    - Added an interactive **"Forgot Password?"** recovery flow on `LoginScreen` allowing users with a bound recovery email to securely verify their email and reset their password.
    - Added a recovery email badge and one-tap **"Bind Recovery Email"** action in `ProfileScreen`.
  - **Strong Password Security Policy**:
    - Created `PasswordValidator` enforcing fintech-grade credentials: **10+ characters**, at least **1 uppercase letter**, at least **1 lowercase letter**, at least **1 special character**, and at least **3 numbers**.
    - Integrated real-time dynamic requirement checklist with visual checkmarks and color-coded status badges in both registration and password reset dialogs.
  - **VIP Subscription Testing Reset Mode**:
    - Added instant developer/QA testing reset codes to `MonetizationService`: `RESETVIP`, `RESET`, `RESETPRO`, `FREE`, and `FREEVIP`.
    - Added a dedicated **"Reset VIP Subscription (Test Mode)"** tile in `ProfileScreen` with immediate visual confirmation snackbar.
  - **Google Mobile Ads (AdMob) Integration**:
    - Integrated official `google_mobile_ads: ^9.1.0` SDK into `pubspec.yaml` and configured Android Manifest with official AdMob application metadata.
    - Created `AdService` managing lifecycle initialization and test banner unit IDs (`ca-app-pub-3940256099942544/6300978111`).
    - Updated `AdBannerWidget` to load authentic native `BannerAd` instances on Android & iOS while seamlessly falling back to contextual financial partner cards on desktop and web.
  - **Android Gradle 8.14 & AGP 8.11.1 Build Fix**:
    - Fixed Android release build failure caused by `generateReleaseLintVitalReportModel` attempting to hash missing `module.xml`.
    - Disabled `lintVital` tasks in `tasks.configureEach` in `android/app/build.gradle.kts`.
    - Successfully compiled and verified clean release APK generation (`tally.apk` and `tally-release.apk` in `build/app/outputs/flutter-apk/`).
  - **Windows Desktop Build & MSVC C++20 Fix**:
    - Fixed Windows MSVC compilation error `C2440: '<function-style-cast>': cannot convert from 'CW2A' to 'std::string'` in `flutter_local_notifications_windows`.
    - Implemented null-safe `(LPCSTR)CW2A(args, CP_UTF8)` string conversion.
    - Integrated automated CMake hotfix patch in `windows/CMakeLists.txt` guaranteeing reproducible, flawless Windows compilation across all clean builds.
    - Successfully compiled and verified clean Windows release executable (`build/windows/x64/runner/Release/balance_tracker.exe`).
- **v1.7.2**:
  - **Fluid 60fps/120fps Login & Animation Smoothness**:
    - **Eliminated Post-Login Frame Drops**: Removed aggressive post-login background timer loop that previously fired repeated root `setState()` rebuilds every 300ms across 1.5s immediately after authentication.
    - **Isolated GPU Layer Rasterization**: Wrapped animated custom painters (`TallyIconPainter` on Splash, `TallyUwashPainter` on wordmark, and the sliding Total Balance card with background watermark) in `RepaintBoundary` to prevent re-rasterization on every tick.
    - **Optimized 250ms Cross-Fade Route Transition**: Implemented `PageRouteBuilder` with `FadeTransition(Curves.easeOutCubic)` for near-instant, jank-free transition from login to the dashboard.
    - **Automated Smoothness Benchmark Suite**: Added `test/smoothness_benchmark_test.dart` verifying frame budgets across all transitions:
      - *Login Route Transition*: **5.07 ms** avg build (under 8.3ms 120fps budget; peak 10.47 ms under 16.6ms 60fps budget).
      - *Dashboard Balance Card Slide*: **5.48 ms** avg build (peak 10.48 ms).
      - *Splash Screen Multi-Stage Bezier Animation*: **4.01 ms** avg build.
      - *Tab Switching & Chart Toggle*: **15 - 20 ms** seamless on-demand switching.
  - **Decoupled In-App Theming from Launcher Icon Switching**:
    - Selecting brand presets (Ledger, Paper, Ink) in Settings immediately updates the app's palette with zero app closure or interruption.
  - **Launcher App Icon Confirmation Warning**:
    - Added dedicated **Launcher App Icon** cards and icon action buttons with an informative confirmation warning dialog.
    - Transparently informs users that the Android OS requires a quick app restart to refresh the launcher icon alias, avoiding unexpected app closures.
  - **Account Login Theme & Custom Accent Retention**:
    - Executed non-destructive SQLite migrations adding `text_color` and `theme` columns to the `profiles` table.
    - Fixed custom accent and text tones reverting to theme native defaults upon account login by persisting active customizations directly to SQLite.
    - Ensured new account registrations and uninitialized profiles inherit currently selected theme palettes and custom colors.
  - **App Version Alignment & Settings Footer**:
    - Updated `pubspec.yaml` to `version: 1.7.2+8`, ensuring Android App Info and system settings accurately reflect version `1.7.2` (Build 8).
    - Integrated a sleek version and security architecture footer (`Tally v1.7.2 (Build 8) • Local Encrypted Vault`) in the settings bottom sheet.
- **v1.7.1**:
  - **High-Contrast Button Text & Action Contrast**:
    - Resolved button text and floating action button contrast in Paper and Ink themes.
    - Ensured primary action buttons, FABs, and tab indicators have crisp, readable labels across all light and dark palettes.
- **v1.7.0**:
  - **Dynamic Launcher Icon Aliases**:
    - Added Android activity aliases for Ledger, Paper, and Ink launcher icons.
    - Added dynamic method channel `com.areeb.tally/app_icon` in `MainActivity.kt` with `PackageManager.setComponentEnabledSetting`.
  - **Persistent Theming on Cold Start**:
    - Saved active theme and custom palette settings globally in `SharedPreferences` to dynamically theme the splash and login screens prior to authentication.
- **v1.7.0**:
  - **Dynamic Theme Splash Screen According to User Settings**:
    - **Session Theme Persistence**: Updated [`initGlobalTheme()`](lib/services/state.dart) to reliably restore the active user's configured theme preset, custom studio primary color, secondary color, and text color on app restarts without requiring re-login.
    - **Clean Logout Reset**: Explicit user logout ([`clearUserSession()`](lib/services/state.dart)) resets persistent preferences back to standard **Ledger** brand defaults (`0xFFE4572E`, `0xFFF6F0E1`, `null`), ensuring privacy and preventing theme leakages.
    - **New User Ledger Standardization**: All new user registrations in [`AppDatabase.registerUser()`](lib/services/database/app_database.dart) and Google logins default to the **Ledger** theme, eliminating conflicts on shared devices.
    - **Dynamic Icon Canvas in Splash**: [`SplashScreen`](lib/screens/splash_screen.dart) renders with dynamic preset background tones, responsive stroke contrast, and personalized slash accent colors.
  - **Secure OTP-Based Password Reset via Cloud Function**:
    - **3-Step Verification Flow**: Implemented a secure password reset dialog in [`LoginScreen`](lib/screens/login_screen.dart).
    - **Step 0 — Email Dispatch**: Validates registered email existence, generates an encrypted 6-digit OTP code valid for 10 minutes, and sends it via Firebase Cloud Function (`sendOtpEmail`).
    - **Step 1 — Code Verification**: All password inputs remain strictly locked and hidden until the user enters the correct 6-digit verification code from their email. Includes options to resend codes or change email.
    - **Step 2 — Set New Strong Password**: Once ownership is verified, unlocks password inputs with live `PasswordValidator` criteria checking, and updates the SQLite ledger password hash.
  - **60 / 120 FPS High Refresh-Rate Stutter-Free Scrolling Engine**:
    - **Diagnosed 20 FPS Bottlenecks**: Identified that default desktop/web discrete stepped scroll physics, absence of multi-pointer drag devices, and `SingleChildScrollView` wrapping `ListView(shrinkWrap: true)` destroyed Flutter's lazy list virtualization and forced off-screen widget rebuilds and pixel repaints on every frame.
    - **Momentum Physics & Multi-Device Drag**: Integrated [`AppScrollBehavior`](lib/main.dart) enabling `BouncingScrollPhysics` with support for touch, mouse, trackpad, and stylus dragging across all platforms.
    - **SliverList Virtualization**: Refactored [`AllTransactionsScreen`](lib/screens/all_transactions_screen.dart) to a virtualized `CustomScrollView` with `SliverToBoxAdapter` and `SliverList.builder(cacheExtent: 500)`, allowing buttery-smooth continuous scrolling with zero frame drops.
    - **RepaintBoundary Paint Isolation**: Isolated ambient radial gradients and complex cards in [`DashboardScreen`](lib/screens/dashboard_screen.dart) and [`AccountsScreen`](lib/screens/accounts_screen.dart) inside `RepaintBoundary` widgets to prevent full-screen canvas invalidation during scroll passes.
- **v1.7.0**:
  - **Account Authentication & Case-Insensitive Collation Overhaul**:
    - **SQLite `COLLATE NOCASE` Integration**: Updated SQLite `users` table schema, lookup queries (`authenticateUser`, `getUsernameForIdentifier`, `getUserEmail`, `getUserByEmail`, `updatePasswordByEmail`), and indexes (`idx_users_username_nocase`, `idx_users_email_nocase`) to use case-insensitive collation. Resolves mobile keyboard auto-capitalization where users registered as `User123` were locked out when logging in with `user123`.
    - **Case-Insensitive Duplicate Prevention**: Added case-insensitive duplicate username and email checks during registration to prevent duplicate accounts with differing capitalization.
    - **Google OAuth Email Persistence**: Fixed missing `email` column value insertion during `authenticateOrRegisterGoogleUser` and added auto-healing for existing legacy Google accounts.
  - **Biometric Multi-Account Isolation & Onboarding Prompt**:
    - **Biometric Session Synchronization (`syncUserSession`)**: Implemented dynamic session sync across password login, Google OAuth, biometric unlock, and registration. If the logged-in user does not have biometrics enabled, active biometric credentials from previous accounts are securely cleared, preventing previous accounts from being offered on logout.
    - **New & Switched Account Biometric Prompt**: Integrated post-login `_checkPostLoginPrompts()` on the Dashboard to detect when a newly registered or switched account supports biometrics and has not yet configured it, prompting them with `showBiometricSetupPrompt` and one-tap biometric setup.
    - **LoginScreen Credential Isolation**: Corrected `_checkBiometricAvailability()` to only display biometric unlock buttons for the active user who enabled biometrics, while prefilling username fields with the last logged-in account.
    - **Password Requirement Checklist Overflow Fix**: Wrapped requirement label text in `Expanded` within `_buildPasswordRequirements` to eliminate the 40–87px `RenderFlex` layout overflow error on narrow mobile screens during account creation.
    - **100% Automated Test Coverage**: Added [`test/account_auth_biometric_test.dart`](test/account_auth_biometric_test.dart) verifying case variations, Google email persistence, credential isolation, and widget flows.
- **v1.6.1**:
  - **Total Balance Card Theme Match & Brand Identity**:
    - Replaced hardcoded violet-to-blue gradient with a theme-matching surface gradient (`theme.colorScheme.surface` with `primary.withValues(alpha: 0.15)`).
    - Removed random credit card numbers (`**** **** **** 4812`) and contactless icon.
    - Integrated official Tally logo badge in the card header and large watermark Tally logo (`TallyIconPainter`) in the card background.
    - Added 'Tally Encrypted Vault' indicator and 'ACTIVE' status pill.
  - **Dynamic Theme-Responsive Pie & Donut Charts**:
    - Updated `DonutChartPainter` and `PieChartPainter` to use dynamically generated theme palettes (`getThemeChartPalette(theme)`) across Home, Accounts, and All Transactions screens.
    - Fixed center text in Donut chart and legend text to use `theme.colorScheme.onSurface` and `subtextColor` so they are 100% readable across all themes.
  - **User-Configurable Text Tone in Theme Studio**:
    - Added a third "Text Tone" tab in `ColorPickerDialog` allowing users to customize text/font color via interactive HSV sliders or Hex input.
    - Integrated text color into `UserProfile`, `AppState.customTextColorNotifier`, and SQLite database persistence.
    - Added live text preview in Theme Studio.
- **v1.5.1**:
  - **Tally Branding Across All Platforms**:
    - **Android App Label**: Updated `android:label="Tally"` in `AndroidManifest.xml` so the installed app displays as **Tally** on device launchers and home screens instead of `balance_tracker`.
    - **Automatic Tally APK Generation**: Configured Gradle (`android/app/build.gradle.kts`) with an automated `copyTallyApk` post-build task so `flutter build apk` produces `tally.apk` and `tally-release.apk` in `build/app/outputs/flutter-apk/`.
    - **Web & Desktop Identity**: Renamed web manifest name/short_name to **Tally** with brand theme colors (`#17493B`), and updated Windows runner window title, executable name (`tally.exe`), and file metadata.
    - **Main App Class**: Renamed `BalanceTrackerApp` to `TallyApp`.
- **v1.5.0**:
  - **Theme Contrast & Icon Matching Overhaul**:
    - **Ink Theme**: Carbon `#191915` icon background with amber `#E8A13C` slash font color and `#E4572E` across-slash accents.
    - **Ledger Theme**: Forest green `#17493B` icon background with `#F6F0E1` mark typography and `#E4572E` slash accents.
    - **Paper Theme**: Vintage cream `#F6F0E1` icon background with `#17493B` forest green typography and `#E4572E` slash accents.
    - **Background-Collision Protection**: `buildDynamicTheme` now detects if `primaryColor` or `secondaryColor` matches `preset.background` (e.g. from legacy user profile saves) and safely falls back to high-contrast mark/slash pairings.
    - **Comprehensive Text Readability**: Replaced over 200 hardcoded `Colors.white`, `Colors.white70`, `Colors.white54`, `0xFF0B0E14`, and `0xFF151A22` references across all screens, cards, tiles, charts, and dialogs with dynamic `Theme.of(context).colorScheme.onSurface`, `surface`, and `scaffoldBackgroundColor`.
    - **Auto-Healing Migration**: `AppState.loadAllUserData` automatically migrates legacy profiles that had low-contrast or identical primary-to-background color settings.
- **v1.4.0**:
  - **Official Ledger Brand Identity**: Integrated official vector assets (`tally.svg`, `tally-uwash.svg`, `tally-icon-anim.svg`, `tally-wordmark-anim.svg`) and high-res launcher icons.
  - **Native 60fps Multi-Stage Animated Startup**:
    - *Stage 1*: Mathematical Bezier stroke drawing of the 4 vertical marks (`#F6F0E1`) and diagonal slash (`#E4572E`) on `#17493B` forest green.
    - *Stage 2*: Smooth icon shrink (130px → 80px) and upward glide, typing "TALLY" in Fraunces/Serif italic with the signature uwash sweeping underneath. Responsively centered across all screens.
    - *Stage 3*: Continuous `Hero` wordmark glide to `LoginScreen` with the login card and input fields flying up from the bottom.
  - **Default White Paper Theme**: Defaulted to crisp `#FBF9F5` white/cream background with `#152A22` ink typography, `#17493B` primary buttons, and `#E4572E` slash orange accents.
  - **Brand Palettes in Settings**: Added **Ledger**, **Paper**, and **Ink** brand style selectors to App & Account Settings.
  - **3-Hour Expense Tally Reminders & Secret Dev Easter Egg**: Added scheduled reminders with quiet hours and 10-toggle easter egg.
- **v1.3.0**:
  - **Flowing Colors Splash Screen**: Added a sweeping animated gradient (violet, ocean cyan, emerald, amber) washing through **"TALLY"** with glowing ambient pulse, preventing black-screen cold starts.
  - **Zero-Lag Tab Architecture & Idle Pre-Warming**: Eliminated the login 5-frame hitch by lazy-loading Tab 0 (Home) upon login and staging background pre-warming for tabs 1..4 across idle frames, preventing any tab-switch stutter.
  - **"Overall" Consolidated View (Accounts)**: Added unified "Overall" card to view aggregated balances, net spending, and consolidated transactions across all accounts/wallets.
  - **Bidirectional Currency Sync**: Fully synchronized currency updates between Dashboard AppBar and Profile Settings with SQLite persistence.
  - **Debug-Mode Fix**: Added `WidgetsFlutterBinding.ensureInitialized()` and desktop SQLite FFI initialization guards to prevent debugging mode attachment hangs.
- **v1.2.0**:
  - **Graphic Theme Studio**: Added fine-grained graphic color controls with interactive HSV sliders, Hex code input, curated presets, and live theme updates.
  - **Profile Photo & Text Customization**: Added photo upload capability via image picker and custom display name / bio editing.
  - **Secure SQLite Database Engine**: Built robust on-device SQLite database (`finance_vault.db`) with SHA-256 password hashing, strict user data isolation, legacy migration, and `.sql` script export.
  - **Firebase Cloud Sync Ready**: Designed an offline-first hybrid architecture ready for Firebase Firestore and Auth multi-device synchronization.
  - **Multi-Month Interactive Analytics Charts**: Added month navigation (`<` and `>`), Line Flow vs. Donut Breakdown toggles, and Spend vs. Income vs. Net filters on both Dashboard and Accounts screens.
  - **Executive Spending Behavior Summary**: Redesigned Profile page with dynamic spending persona badges, financial vitals, needs-vs-wants breakdown, and top spending categories leaderboard.
  - **Home Avatar Profile Redirection**: Tapping the user avatar or greeting on the Home screen instantly navigates to the Profile tab.
- **v1.1.1**:
  - Profile currency picker bugfix, login crash protection, inline loading spinner, and keyboard latency optimization.
- **v1.0.0**: Initial release with authentication, transactions, and basic dashboard.
