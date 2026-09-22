# 💰 Tally — Smart Personal Finance & Expense Tracker

> *"Just tally it up!"* — A blazing-fast, modern personal finance manager built with **Flutter** & **Material 3**. Designed with fluid micro-interactions, dark glassmorphism styling, graphic theme customization, offline-first encrypted SQLite storage, and stutter-free 60/120fps mobile rendering.

---

## 📱 Visual Showcase & Screenshots

> [!TIP]
> **Screenshots Placeholder**: Capture and place your high-resolution screenshots in `assets/screenshots/` (e.g. `splash.png`, `dashboard.png`, `insights.png`, `accounts_overall.png`, `theme_studio.png`, `reminders_settings.png`).

| Flowing Splash | Home & Dashboard | Consolidated Accounts | Theme Studio & Identity | Reminders & Easter Egg |
| :---: | :---: | :---: | :---: | :---: |
| *(Add Splash Screenshot)* | *(Add Dashboard Screenshot)* | *(Add Accounts Overall)* | *(Add Profile/Theme Screenshot)* | *(Add Reminders Screenshot)* |

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
├── main.dart                       # App entrypoint & dynamic theme listening
├── models/                         # Domain data models
│   ├── transaction.dart            # Transaction schema & serialization
│   ├── savings_goal.dart           # SavingsGoal schema & progress logic
│   └── user_profile.dart           # User profile, custom colors & photo model
├── screens/                        # Application screens
│   ├── splash_screen.dart          # Multi-stage Bezier animated brand startup
│   ├── login_screen.dart           # Hero wordmark & bottom-sliding authentication
│   ├── main_nav_screen.dart        # Lazy-loaded tab shell with idle pre-warming
│   ├── dashboard_screen.dart       # Interactive multi-month chart & quick stats
│   ├── all_transactions_screen.dart# Search, filter, and pie chart analytics
│   ├── insights_screen.dart        # Spending trends & category breakdown
│   ├── goals_screen.dart           # Goal progress & fund allocations
│   ├── accounts_screen.dart        # Multi-wallet & "Overall" consolidated view
│   └── profile_screen.dart         # Financial behavior summary & settings popup
├── services/                       # State & Persistence
│   ├── notification_service.dart   # 3-hour scheduled reminders & easter egg
│   ├── state.dart                  # AppState ValueNotifiers & reactive state
│   └── database/                   # SQLite database engine & security
│       ├── app_database.dart       # SQLite tables, migrations, CRUD & SQL export
│       └── security_helper.dart    # SHA-256 password salting & verification
├── utils/                          # Styling & Design Tokens
│   └── constants.dart              # Dynamic theme generator, icons & currencies
└── widgets/                        # Reusable UI & Custom Painters
    ├── tally_brand_painters.dart   # TallyIconPainter, UwashPainter & Wordmark
    ├── custom_painters.dart        # Repaint-bounded Month line & Donut painters
    ├── interactive_chart_card.dart # Multi-month navigator & line/donut card
    ├── color_picker_dialog.dart    # Graphic Theme Studio (HSV sliders & hex)
    ├── transaction_tile.dart       # Dismissible transaction list item
    └── transaction_dialog.dart     # Memory-safe modal for add/edit transactions
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

### Windows Executable
```bash
flutter build windows --release
```
The output executable will be generated at `build/windows/x64/runner/Release/tally.exe`.

---

## 📝 Recent Changelog
- **v1.7.1 (Current)**:
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
    - Implemented a native Kotlin `MethodChannel` (`com.areeb.tally/app_icon`) in `MainActivity.kt` and Dart service [AppIconService](file:///c:/Users/areeb/Desktop/folders/flutter_calculator_new/lib/services/app_icon_service.dart) allowing instant runtime launcher icon switching via `setComponentEnabledSetting(..., DONT_KILL_APP)`.
  - **Global Persistent Theme Across App Restarts & Exit**:
    - Added `AppState.initGlobalTheme()` which restores the user's selected theme and custom color palette from `SharedPreferences` in `main.dart` *before* `runApp()`.
    - Eliminated theme reset on app exit and cold restart: Tally immediately boots into the user's saved theme.
  - **Full Startup Theming (Splash & Login Screens)**:
    - Updated `SplashScreen` to dynamically render with the active theme's background color, animated icon colors (e.g. Ink's carbon black, cream strokes, and amber slash), and wordmark styling.
    - Updated `LoginScreen` to dynamically render with the user's saved theme (e.g. if Ink is chosen, login form card, input fields, borders, and buttons match Ink's dark carbon palette and cream typography).
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
