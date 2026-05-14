# Balance Tracker App Documentation

## 📱 App Overview
Balance Tracker is a premium, locally-stored personal finance application built with Flutter. It helps users manage their income, expenses, accounts, budgets, savings goals, and spending insights in a sleek dark-themed interface with bottom navigation.

## ✨ Current Features
1. **User Authentication**
   - Create accounts and login securely.
   - Data is scoped to the logged-in user.
   - **User Logout**: Securely log out and return to the login screen.
2. **Dashboard Overview**
   - Total Balance/Net Worth calculation.
   - Monthly Flow Chart showing balance fluctuations.
   - Monthly Budgets Progress with visual limit warnings (red at >90%).
   - **Animated UI**: Smooth slide-in animation for the Balance Card.
   - **Data Reset**: Ability to clear all transactions and reset data from the dashboard.
   - **Budget Editor**: Tapping the pencil icon allows you to set limits for specific categories.
3. **Transaction Management**
   - Add Income/Expense transactions.
   - Categorization with corresponding icons (Food, Salary, Housing, etc.).
   - Multiple Accounts support (Main, Cash, Credit Card, Digital Wallet).
   - Recurrence flagging (None, Daily, Weekly, Monthly).
   - Swipe to Delete with an Undo Snackbar.
   - Tap to Edit existing transactions.
4. **All Transactions & Analytics**
   - Income vs Expense Pie Chart.
   - Filtering by Income/Expense.
   - Full-text search across titles and categories.
5. **Smart Insights (Tier 2)**
   - Daily average spending.
   - Savings rate percentage.
   - Month-over-month spending comparison.
   - Biggest expense of the month.
   - Category breakdown with percentage bars.
6. **Goals & Savings Tracker (Tier 2)**
   - Create named savings goals with target amounts.
   - Visual circular progress ring per goal.
   - Add funds to goals incrementally.
   - Delete goals. Celebrate when goal is reached.
   - Persisted per user via SharedPreferences.
7. **Bottom Navigation Bar**
   - Home (Dashboard), Insights, Goals, and Accounts tabs.
   - Material 3 NavigationBar with indicator.
8. **Accounts & Wallets (Tier 2)**
   - View balances and total spent for each account (Main, Cash, Credit Card, Digital Wallet).
   - Filter transactions by selecting the respective account card.


## ⚙️ Architecture & Core Functions

Currently, the application is structured within a single `main.dart` file.

### Data Models & State
* **`class Transaction`**: Holds `id`, `title`, `amount`, `date`, `isIncome`, `category`, `account`, and `recurrence`. Includes `toJson`/`fromJson`.
* **`class SavingsGoal`**: Holds `id`, `title`, `target`, `saved`, `icon`, `color`. Includes a computed `progress` getter and `toJson`/`fromJson`.
* **`transactionsNotifier`**: Global state for all transactions.
* **`budgetsNotifier`**: Global state for budget limits per category.
* **`goalsNotifier`**: Global state for savings goals.
* **`saveTransactions()` / `loadTransactions()`**: Persist transactions via SharedPreferences.
* **`saveGoals()` / `loadGoals()`**: Persist savings goals via SharedPreferences.

### Screens & Widgets
* **`LoginScreen`**: Login/registration. Loads transactions and goals on login.
* **`MainNavScreen`**: Bottom navigation shell wrapping Home, Insights, Goals, and Accounts tabs.
* **`AccountsScreen`**: View account balances, spent amounts, and filtered transactions per wallet.
* **`DashboardScreen`**: Balance card, budget progress bars, month chart, recent transactions list.
* **`InsightsScreen`**: Smart analytics with daily average, savings rate, spending trends, top expense, and category breakdown.
* **`GoalsScreen`**: Create, fund, and track savings goals with circular progress rings.
* **`AllTransactionsScreen`**: Full transaction list with pie chart, search, and filtering.
* **`showTransactionDialog()`**: Global add/edit transaction modal.
* **`TransactionTile`**: Reusable widget with swipe-to-delete and tap-to-edit.

## 🚀 Future Plans (Roadmap)

### Phase 3: Cloud & Sync
- **Backend Migration**: Move from `SharedPreferences` to **Firebase** or **Supabase** for cross-device cloud sync.
- **Secure Authentication**: Replace plaintext login with Firebase Auth (Google/Apple sign-in) and biometric locks.
- **Architecture Refactor**: Split `main.dart` into clean architecture folders (Models, Views, Controllers, Services).

### Phase 4: Premium Features
- **Receipt Scanning**: Integrate OCR to automatically read and categorize receipts.
- **Bank Linking**: Use Plaid API to automatically pull live transactions.
- **Multi-currency**: Handle different currencies with live conversion rates.
- **Export & Reports**: CSV/PDF export of transaction data.
