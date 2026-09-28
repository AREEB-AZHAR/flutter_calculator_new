# 💰 Tally — Smart Personal Finance & Expense Tracker

> *"Just tally it up!"* — A blazing-fast, modern personal finance manager built with **Flutter** & **Material 3**. Designed with fluid micro-interactions, dark glassmorphism styling, graphic theme customization, offline-first encrypted SQLite storage, and stutter-free 60/120fps mobile rendering.

---

## 📱 Visual Showcase & Screenshots

> [!TIP]
> **Screenshots Placeholder**: Capture and place your high-resolution screenshots in `assets/screenshots/` (e.g. `splash.png`, `dashboard.png`, `home_tour.png`, `accounts_tour.png`, `biometric_prompt.png`, `settings_guide.png`, `pro_paywall.png`, `google_auth.png`, `rewarded_ad.png`, `theme_passes.png`).
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

| Flowing Splash | Home & Ad Banner | Insights Pro Lock | 30s Rewarded Ad | Play Store Billing & Tiers |
| :---: | :---: | :---: | :---: | :---: |
| *(Add Splash Screenshot)* | *(Add Dashboard Banner Screenshot)* | *(Add Pro Paywall Screenshot)* | *(Add Rewarded Ad Screenshot)* | *(Add Premium Billing Screenshot)* |

---

## ✨ Features & Capabilities

### 1. 🌈 Flowing Colors Brand Splash & Cold-Boot Polish

- **Dynamic Gradient Sweep**: Fluid linear gradient shader washing vibrant colors (electric violet, ocean cyan, emerald green, solar amber) through the text **"TALLY"**.
- **Zero Black-Screen Startup**: Immediate rendering prevents the default blank/black frame cold-boot hitch on mobile devices.
- **Glowing Ambient Pulse**: Breathing micro-animations and smooth cross-fade transition into the login or dashboard shell.

### 2. ⚡ Zero-Lag Lazy-Loaded Tab Architecture

- **Instant Login Rendering**: Only the active Home dashboard (Tab 0) is built upon authentication, completely eliminating the 5-frame hitch caused by mounting all 5 analytical screens simultaneously.
- **Smart Idle Pre-Warming**: Sequentially warms up subsequent tabs (Insights, Goals, Accounts, Profile) in the background during idle frame windows (350ms staggered intervals), ensuring zero tab-switch stutter without loading all screens upfront.
- **Debug-Safe Binding**: Integrated `WidgetsFlutterBinding.ensureInitialized()` and SQLite FFI guards to guarantee instant loading in both Debug and Release build modes.

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
│   ├── savings_goal.dart           # SavingsGoal schema & progress logic
│   ├── loan.dart                   # Loan model (Receivable/Payable, reminder dates)
│   ├── planned_transaction.dart    # Planned & future-dated transaction model
│   └── user_profile.dart           # User profile, custom colors & photo model
├── screens/                        # Application screens
│   ├── splash_screen.dart          # Multi-stage Bezier animated brand startup
│   ├── login_screen.dart           # Hero wordmark & bottom-sliding authentication
│   ├── main_nav_screen.dart        # Lazy-loaded tab shell with idle pre-warming
│   ├── dashboard_screen.dart       # Post-login biometric prompt & Home Tour trigger
│   ├── all_transactions_screen.dart# Single-scroll dynamic search & 3-mode visualizer
│   ├── insights_screen.dart        # Spending trends, category breakdown & Pro lock preview
│   ├── goals_screen.dart           # Goal progress & fund allocations
│   ├── accounts_screen.dart        # Accounts & Wallets + Loans & Debts dual-tab screen
│   ├── premium_screen.dart         # Dedicated Tally Pro paywall & Google Pay checkout
│   └── profile_screen.dart         # Features & Settings guide, Theme Studio & tours reset
├── services/                       # State & Persistence
│   ├── in_app_purchase_service.dart# Google Play Billing (IAP) service & restore engine
│   ├── monetization_service.dart   # Recalculated pricing, Theme Pass engine & promo codes
│   ├── ad_service.dart             # Google AdMob Banner & Rewarded 30s Video ads
│   ├── google_auth_service.dart    # Google Sign-In & SQLite identity binding
│   ├── cloud_sync_service.dart     # Two-way SQLite & Cloud Firestore deletion sync
│   ├── biometric_service.dart      # Biometric & screen lock auth & setup modal
│   ├── tour_service.dart           # Tour completion flags & reset persistence
│   ├── notification_service.dart   # Loan push reminders & scheduled tally alerts
│   ├── app_icon_service.dart       # Dynamic launcher icon switcher
│   ├── state.dart                  # AppState ValueNotifiers & reactive state
│   └── database/                   # SQLite database engine & security
│       ├── app_database.dart       # SQLite tables, migrations, CRUD & SQL export
│       └── security_helper.dart    # SHA-256 password salting & verification
├── utils/                          # Styling & Design Tokens
│   ├── constants.dart              # Dynamic theme generator, icons & currencies
│   └── password_validator.dart     # Strong password validation rules
└── widgets/                        # Reusable UI & Custom Painters
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

- **v1.9.0 (Current)**:
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
