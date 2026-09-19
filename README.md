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

### 1. 🔐 User Authentication & Profile
- **Scoped User Data**: Local account creation and multi-user login backed by persistent storage.
- **Custom Profile Theming**: Dynamic theme switching (Violet Night, Emerald Green, Ocean Blue, Sunset Glow, Neon Cyberpunk) and custom avatar colors.

### 2. 📊 Real-Time Dashboard
- **Total Balance & Net Worth**: Live calculation of income, expenses, and total liquidity.
- **Current Month Flow Chart**: Custom bezier line chart tracking daily balance progress throughout the month.
- **Monthly Budget Bars**: Progress tracking with visual threshold indicators (red warning above 90% allocation).
- **Recent Activity**: Quick access to recent transactions with instant tap-to-edit and swipe-to-delete.

### 3. 💳 Comprehensive Transaction Management
- Categorize by Food & Dining, Salary, Rent, Healthcare, Entertainment, Utilities, and more.
- Tag transactions to specific accounts: **Main**, **Cash**, **Credit Card**, or **Digital Wallet**.
- Recurrence flags (None, Daily, Weekly, Monthly).
- Multi-currency support (USD, EUR, GBP, PKR, INR, JPY, CNY, AED, SAR, CAD, AUD, etc.).
- Swipe-to-delete with one-tap Undo SnackBar.

### 4. 📈 Smart Insights & Spending Trends
- Daily average expenditure.
- Savings rate percentage.
- Month-over-month trend comparisons (with intelligent calendar-year rollback).
- Top monthly expense detector.
- Category spending percentage distribution.

### 5. 🎯 Savings Goals Tracker
- Create specific savings targets with target dollar amounts.
- Circular progress rings with completion celebrations (`🎉 Goal Reached!`).
- Add funds incrementally with instant progress updates.

### 6. 👛 Multi-Account & Wallet Management
- Independent wallet balance calculations and total spending tracking per account.
- Filter transactions specifically for a selected wallet.

---

## 🏗️ Clean Modular Architecture

```
lib/
├── main.dart                       # App entrypoint & dynamic theme listening
├── models/                         # Domain data models
│   ├── transaction.dart            # Transaction schema & serialization
│   └── savings_goal.dart           # SavingsGoal schema & progress logic
├── screens/                        # Application screens
│   ├── login_screen.dart           # Authentication & sign-in
│   ├── main_nav_screen.dart        # IndexedStack zero-lag tab shell
│   ├── dashboard_screen.dart       # Home overview, balance & budgets
│   ├── all_transactions_screen.dart# Search, filter, and pie chart analytics
│   ├── insights_screen.dart        # Spending trends & category breakdown
│   ├── goals_screen.dart           # Goal progress & fund allocations
│   ├── accounts_screen.dart        # Multi-wallet & card balances
│   └── profile_screen.dart         # Multi-theme selector & user avatar
├── services/                       # State & Persistence
│   └── state.dart                  # AppState ValueNotifiers & SharedPreferences I/O
├── utils/                          # Styling & Design Tokens
│   └── constants.dart              # Theme definitions, icons & currencies
└── widgets/                        # Reusable UI & Custom Painters
    ├── custom_painters.dart        # Repaint-bounded Month & Pie chart painters
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
- **v1.1.1 (Current)**:
  - **Profile Tab Bugfix**: Fixed assertion crash in `ProfileScreen` currency picker by replacing restrictive dropdown with full `SimpleDialog` supporting all currencies (including PKR `₨`, INR `₹`, etc.).
  - **Avatar Empty Guard**: Added safety fallback for empty/whitespace usernames in profile avatar generation.
  - **Login Crash Protection**: Wrapped authentication and JSON storage deserialization in robust `try / catch` blocks to eliminate crash on invalid credentials or corrupt storage.
  - **Loading Indicator Stabilization**: Replaced jittery button swap with fixed-geometry `ElevatedButton` maintaining consistent 55px height and inline centered progress spinner.
  - **Android Keyboard Lag Elimination**: Removed hardcoded Windows font (`Segoe UI`) on mobile devices to prevent native font-fallback lookups during keystrokes; disabled heavy IME suggestions on credential fields; added automatic keyboard dismissal on submission.
  - **Currency State Persistence**: Integrated currency selection with user-scoped persistence across app sessions and transactions modal.
- **v1.1.0**:
  - Synchronized complete modular architecture (`models`, `screens`, `services`, `utils`, `widgets`).
  - Added **Multi-Theme Engine** with 5 custom color palettes and avatar personalizations.
  - Implemented **Accounts & Wallets Screen** for multi-account balance tracking.
  - Resolved mobile performance lag via `IndexedStack` and `RepaintBoundary`.
  - Fixed `TextEditingController` memory leaks and Android keyboard cursor jumps.
  - Fixed January rollback bug in month-over-month insight calculations.
  - Fixed Gradle 8.14 compatibility by enforcing Java 21 LTS runtime.
- **v1.0.0**: Initial release with authentication, transactions, and basic dashboard.
