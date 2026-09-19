# 💰 Balance Tracker & Personal Finance Manager

A modern, high-performance personal finance management app built with **Flutter** & **Material 3**. Designed with fluid micro-interactions, dark glassmorphism styling, multi-theme customization, and zero-lag mobile rendering.

---

## 📱 Visual Showcase & Screenshots

> [!TIP]
> **Screenshots Placeholder**: Capture and place your high-resolution screenshots in `assets/screenshots/` (e.g. `dashboard.png`, `insights.png`, `goals.png`, `theme_selector.png`).

| Home & Dashboard | Analytics & Insights | Savings Goals | Accounts & Theming |
| :---: | :---: | :---: | :---: |
| *(Add Dashboard Screenshot)* | *(Add Insights Screenshot)* | *(Add Goals Screenshot)* | *(Add Profile/Theme Screenshot)* |

---

## ✨ Features & Capabilities

### 1. 🎨 Graphic Theme Studio & Custom Identity
- **Fine-Grained Graphic Color Control**: Fine-tune primary and secondary accent colors with interactive Hue, Saturation, and Lightness (HSV) sliders or direct Hex input (`#8B5CF6`).
- **Curated Theme Palettes**: Quick-select from designer palettes (Violet Neon, Ocean Cyan, Emerald Matrix, Solar Amber, Rose Velvet, Cyberpunk Teal).
- **Custom Profile Photo Uploads**: Upload profile pictures from the device gallery with automatic fallback to stylized initial avatars.
- **Personal Bio & Display Name**: Edit custom profile text, displayed across the app header and profile dashboard.

### 2. 🛡️ Secure SQLite Database Vault & Cloud Architecture
- **On-Device Encrypted SQL Ledger**: All user accounts, transactions, budgets, goals, and customized profiles are securely stored in an on-device SQLite database (`finance_vault.db`).
- **Cryptographic Password Protection**: User passwords are protected using SHA-256 cryptographic hashing with unique random salts.
- **Strict User Isolation**: Foreign-key scoped queries guarantee that no account can ever access another user's financial records.
- **Full `.sql` Script Export**: One-tap generation and export of your complete SQL database dump for backups or offline inspection.
- **Firebase Ready (Hybrid Architecture)**: Abstracted database repository ready for instant multi-device cloud synchronization with Firebase Firestore & Firebase Auth.

### 3. 📈 Interactive Multi-Month Analytics Charts
- **Multi-Month Navigation**: Browse previous and future months seamlessly with `<` and `>` arrow selectors.
- **Chart Style Toggle**: Switch instantly between a **Smooth Line Flow** (daily balance and cumulative progression) and a **Segmented Donut Breakdown** (category distribution).
- **Metric Filter Selectors**: Toggle focus between **Spend (Expenses)**, **Income (Received)**, and **All (Net)**.
- **Dual-Screen Availability**: Embedded on both the **Home Dashboard** and the **Accounts & Wallets** screen (where it automatically filters by the active wallet/account).

### 4. 🧠 Executive Spending Behavior Summary
- **Dynamic Spending Persona**: Real-time behavioral badges based on cumulative savings velocity:
  - 🌟 *Master Wealth Builder* (Savings rate ≥ 40%)
  - 💎 *Balanced Strategist* (Savings rate 20% – 40%)
  - ⚡ *Active Cashflower* (Savings rate 5% – 20%)
  - 🔥 *Lifestyle Maximizer* (High expenditure burn rate)
- **Financial Vital Signs**: Track Lifetime Inflow, Lifetime Outflow, Accumulated Retained Wealth, and the **Needs vs Wants** essential allocation ratio.
- **Top Spending Drivers Leaderboard**: Interactive progress indicators displaying your top 4 expense categories by volume and percentage.
- **Peak Outflow Detector**: Real-time callout identifying the single largest expense recorded.

### 5. ⚙️ Dedicated Profile Settings Modal
- Access theme customizers, image uploaders, display name editors, currency switchers, password managers, and SQL data export from a central modal sheet.
- **One-Tap Home Redirection**: Tapping the user avatar in the Home page AppBar instantly navigates directly to the Profile tab.

---

## 🏗️ Clean Modular Architecture

```
lib/
├── main.dart                       # App entrypoint & dynamic theme listening
├── models/                         # Domain data models
│   ├── transaction.dart            # Transaction schema & serialization
│   ├── savings_goal.dart           # SavingsGoal schema & progress logic
│   └── user_profile.dart           # User profile, custom colors & photo model
├── screens/                        # Application screens
│   ├── login_screen.dart           # SQLite authentication & sign-in
│   ├── main_nav_screen.dart        # IndexedStack zero-lag tab shell
│   ├── dashboard_screen.dart       # Interactive multi-month chart & quick stats
│   ├── all_transactions_screen.dart# Search, filter, and pie chart analytics
│   ├── insights_screen.dart        # Spending trends & category breakdown
│   ├── goals_screen.dart           # Goal progress & fund allocations
│   ├── accounts_screen.dart        # Multi-wallet cards & account analytics
│   └── profile_screen.dart         # Financial behavior summary & settings popup
├── services/                       # State & Persistence
│   ├── state.dart                  # AppState ValueNotifiers & reactive state
│   └── database/                   # SQLite database engine & security
│       ├── app_database.dart       # SQLite tables, migrations, CRUD & SQL export
│       └── security_helper.dart    # SHA-256 password salting & verification
├── utils/                          # Styling & Design Tokens
│   └── constants.dart              # Dynamic theme generator, icons & currencies
└── widgets/                        # Reusable UI & Custom Painters
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
The output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

### Windows Executable
```bash
flutter build windows --release
```
The output executable will be generated at `build/windows/x64/runner/Release/balance_tracker.exe`.

---

## 📝 Recent Changelog
- **v1.2.0 (Current)**:
  - **Graphic Theme Studio**: Added fine-grained graphic color controls with interactive HSV sliders, Hex code input, curated presets, and live theme updates.
  - **Profile Photo & Text Customization**: Added photo upload capability via image picker and custom display name / bio editing.
  - **Secure SQLite Database Engine**: Built robust on-device SQLite database (`finance_vault.db`) with SHA-256 password hashing, strict user data isolation, legacy migration, and `.sql` script export.
  - **Firebase Cloud Sync Ready**: Designed an offline-first hybrid architecture ready for Firebase Firestore and Auth multi-device synchronization.
  - **Multi-Month Interactive Analytics Charts**: Added month navigation (`<` and `>`), Line Flow vs. Donut Breakdown toggles, and Spend vs. Income vs. Net filters on both Dashboard and Accounts screens.
  - **Executive Spending Behavior Summary**: Redesigned Profile page with dynamic spending persona badges, financial vitals, needs-vs-wants breakdown, and top spending categories leaderboard.
  - **Home Avatar Profile Redirection**: Tapping the user avatar or greeting on the Home screen instantly navigates to the Profile tab.
- **v1.1.1**:
  - Profile currency picker bugfix, login crash protection, inline loading spinner, and keyboard latency optimization.
- **v1.1.0**:
  - Synchronized complete modular architecture (`models`, `screens`, `services`, `utils`, `widgets`), added Accounts & Wallets screen, and implemented mobile performance optimizations.
- **v1.0.0**: Initial release with authentication, transactions, and basic dashboard.
