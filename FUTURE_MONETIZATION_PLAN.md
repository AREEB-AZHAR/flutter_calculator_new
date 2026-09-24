# Tally — Future Monetization Roadmap & Strategy Plan

> **Status:** Draft / Planned  
> **Context:** Architectural and strategic monetization blueprint for Tally (Offline-First Personal Finance & Expense Tracker).

---

## 1. Core Philosophy & Design Principles

Tally's users choose the app for its **privacy, offline-first reliability, and bespoke tactile design** (Paper, Ink, Ledger themes).
Any monetization implemented in Tally must uphold these three pillars:
1. **Zero Degradation of Aesthetics**: No low-quality, flashing, or un-themed banner ads.
2. **Strict Privacy**: No tracking SDKs that leak financial habits, transactions, or account balances.
3. **Generous Core Experience**: Essential manual expense tracking, basic accounts, and default themes remain free forever. Power tools, automation, and luxury customization fund continuous development.

---

## 2. Monetization Models

### Model 1: "Tally Pro" Freemium (Primary Model ⭐)

Offer an in-app upgrade to **Tally Pro** via monthly/annual subscription or lifetime purchase.

#### Gated Pro Features:
- **Tax & Financial Reports Export**:
  - One-tap formatted PDF financial statements (categorized spending, balance progression).
  - Clean CSV / Excel spreadsheet exports for custom accounting.
- **Advanced Forecasts & Analytics**:
  - 30-day predictive balance forecast based on spending velocity.
  - Category budget caps with automated alert thresholds.
- **Unlimited Buckets & Custom Accounts**:
  - Free tier: Up to 3 accounts and 3 financial goals.
  - Pro tier: Unlimited bank accounts, cash envelopes, investment tracking, and custom goals.
- **Exclusive VIP Themes & Dynamic Launcher Icons**:
  - Bespoke VIP themes (e.g., *Obsidian Gold*, *Emerald Vault*, *Monochrome Slate*).
  - Exclusive VIP launcher icons with metallic foil styling.
- **Encrypted Cloud Backup & Multi-Device Sync**:
  - Optional encrypted backup to Google Drive / iCloud or Supabase without compromising offline-first operation.
- **Recurring Transactions & Subscriptions Tracker**:
  - Automated scheduling for monthly bills (rent, streaming, utilities) with reminder notifications.

#### Pricing Structure:
- **Monthly Subscription**: `$1.99 / month`
- **Annual Subscription (7-day free trial)**: `$14.99 / year` (~$1.25/mo)
- **Lifetime License ("Buy Once, Own Forever")**: `$29.99` (highly attractive to indie productivity app enthusiasts).

---

### Model 2: Theme-Matched Native Ads + "Remove Ads" Pass (Secondary / Alternative)

If an ad-supported tier is deployed alongside free usage:
- **Native Custom Cards**: Use Google AdMob Native Ads styled with Tally’s exact typography, corner radius, and theme colors (Ink/Paper/Ledger) so they blend harmoniously into transaction or insights feeds.
- **Rewarded Access**: Allow users to watch a single 15-second sponsor video to unlock a PDF export or exclusive theme for 48 hours.
- **Ad-Removal Microtransaction**: A single `$2.99` one-time purchase to permanently remove all ad impressions.

---

### Model 3: In-App "Tip Jar" / Backer Program (Lightweight / Zero Risk)

- Integrated into the Settings / Profile screen.
- Tiers:
  - ☕ Buy Developer a Coffee (`$1.99`)
  - 🍕 Buy Lunch (`$4.99`)
  - 👑 Founding Backer (`$9.99`) — unlocks an exclusive gold backer badge on the Profile screen.

---

### Model 4: Curated Financial Affiliate Partnerships (High-Yield CPA)

- A dedicated "Financial Perks" section featuring vetted, high-value partner offers:
  - High-Yield Savings Accounts (HYSAs) with competitive APYs.
  - Cash-back credit cards and zero-fee international transfer accounts.
- Typical CPA payout: `$25 – $120+` per qualified account registration.

---

## 3. Technical Architecture & Implementation Stack

### Recommended Stack:
1. **RevenueCat (`purchases_flutter`)**:
   - Industry-standard in-app purchases and subscription management.
   - Handles receipt verification, restore purchases, dynamic paywalls, and cross-platform entitlements across Android and iOS.
2. **`in_app_purchase` (Flutter Official)**:
   - Alternative for pure one-time non-consumable purchases (Lifetime pass or Tip Jar) without third-party server requirements.
3. **Paywall UI Architecture**:
   - Modern modal bottom-sheet or full-screen paywall inspired by Apple Design Award winners (e.g., Copilot Money, Bear, Things 3).
   - Dynamic theme integration: paywall colors immediately adapt to the active app theme.
