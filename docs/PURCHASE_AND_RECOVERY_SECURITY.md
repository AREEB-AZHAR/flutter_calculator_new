# Google Play purchases and local password recovery

Source update: **1.8.18+28**, 23 October 2026. No APK was built for this update. These changes are tested locally; they have **not been deployed or validated with a real Play transaction or email delivery**. Live configuration could not be inspected with the available Firebase CLI session.

## Plan and decisions

1. Remove every release-mode sandbox, local paid-cache and universal promo unlock.
2. Verify Google Play tokens on a trusted backend before delivery and store completion. Bind purchases to Firebase users, reject replay, and recheck expiry/refunds.
3. Generate and verify recovery codes on the server; update only the matching local vault after successful verification.
4. Exercise client flows, real SQLite, Firestore transactions and access rules, then document activation and commit the source.

Recommendations follow Google's [billing security guidance](https://developer.android.com/google/play/billing/security), [product V2 API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2) and [subscription V2 API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2), plus Firebase's [Flutter App Check](https://firebase.google.com/docs/app-check/flutter/default-providers) and [callable enforcement](https://firebase.google.com/docs/app-check/cloud-functions) documentation. Google Play is the only supported purchase store. Keep store credentials on the server and use application default credentials rather than distributing service-account keys.

## Behavior and architecture

- `lib/services/purchase_backend.dart` coordinates verify → deliver → complete. Release builds ignore sandbox preferences, direct unlock helpers, old HMAC-signed paid preferences and promo codes. Starting checkout alone never grants access.
- Firebase and Android App Check initialize before the billing listener. Release Android uses Play Integrity; debug builds use the debug provider. Other platforms cannot purchase and require their own App Check integration before using protected recovery callables.
- `functions/google_play_client.js` calls Android Publisher using the runtime service account. Package is fixed to `com.areeb.balance_tracker`; only the five product IDs below are accepted.
- Tokens must carry the SHA-256 Firebase UID set as the obfuscated account ID at checkout. A token can belong to only one UID/product. Unbound historical receipts require a separately reviewed, trusted ownership migration; possession of an old token alone is insufficient.
- `functions/security.js` keeps tokens in backend-only `private_purchase_tokens`, transactions ownership/grants, supersedes linked subscription tokens, and rechecks existing receipts on refresh. Pending, refunded, expired and held purchases grant no access. Cancellation retains subscription access through the verified expiry. A Play outage cannot mint a new lease.
- Coffee is recorded before server-side consumption; consumption must succeed before the client completes the purchase. Retries retain the original seven-day trial start. Consumed coffee remains restorable through its server ownership record.
- Paid access uses an in-memory lease lasting **at most 15 minutes**, bounded by verified subscription/trial expiry and receipt freshness. Lease expiry clears access and attempts refresh. Restart requires online verification; failure clears paid access. Refunds/revocations are detected on refresh; no real-time developer notification handler is included, so an existing lease can remain valid until its expiry. The core local ledger remains available offline. This conservative offline policy should be reviewed against customer expectations before release.
- Firestore owner access to existing app data is preserved. Clients may read their entitlement document but cannot write `monetization` or `purchases` descendants. All `private_*` collections are inaccessible to clients. Admin SDK access is controlled through IAM.
- Recovery changes the **local vault password on this device**, never the Google account password. Codes are server-generated, HMAC-protected, expire after 10 minutes, allow five wrong attempts and are consumed transactionally once. Resending invalidates the prior delivered challenge. Delivery failure never displays a sent-code success.
- Recovery limits: one send/minute and five/hour per email, 30/hour per IP; verification 60/minute per IP. Purchase verification is limited to 30/minute per UID; refresh to 10/minute. Max instances are bounded. Configure operational monitoring and retention for expired challenge/rate-limit documents; these records do not automatically delete themselves.
- No password is sent to Firebase recovery callables. SQLite updates compare username, email and original hash to prevent overwriting a changed account. Existing salted SHA-256 password storage and unencrypted SQLite remain separate audit work (F6); this update does not upgrade the password KDF or encrypt the database.

## Configure production, step by step

Do not paste passwords or service-account keys into chat or commit them. Use a development Firebase project and test users first.

1. Install Flutter **3.41.3 / Dart 3.11.1**, Git, Node **22**, Firebase CLI and JDK **21** for the Firestore emulator. Follow the README for Android SDK/JDK paths. Clone the repository, run `flutter doctor -v`, `flutter pub get`, then `cd functions` and `npm ci`. Return to the repository root.
2. Sign into Firebase CLI with the project owner's account: `firebase login`. Confirm the target with `firebase projects:list`. The tracked default project is `tally-b3652`; replace it with your development project when testing. Never point emulator tests at production.
3. In Firebase Console → App Check, register the Android app with **Play Integrity** and its actual signing certificate SHA-256. For Play-installed builds use the Play App Signing certificate, not merely the upload/debug certificate. Follow the linked Firebase instructions for the Play project linkage. Register development debug tokens only in the development project's debug provider. The callables enforce App Check immediately after deployment.
4. Enable **Google Play Android Developer API** in the Google Cloud project used for billing access. In Cloud Functions/Cloud Run, identify the actual runtime service account for the deployed functions. In Google Play Console → Users and permissions, grant that service account the necessary app-scoped purchase/subscription access to `com.areeb.balance_tracker` (including order/subscription management for consumption). Confirm permissions using a license tester; do not assume the default runtime identity already has access. The server uses ADC; no JSON key file is required in this repository.
5. In Play Console configure `tally_pro_monthly` and `tally_pro_yearly` as subscriptions; `tally_pro_lifetime` and `tally_remove_ads` as nonconsumable one-time products; `tally_coffee_tip` as a consumable one-time product. Activate the appropriate base plans/products and add license testers. Test through an eligible Play testing track with the correct package and release signing.
6. Configure a Gmail sender with two-step verification and an app password. Run these interactive commands from the repository root, replacing the project if appropriate:

   ```powershell
   firebase functions:secrets:set EMAIL_USER --project tally-b3652
   firebase functions:secrets:set EMAIL_PASS --project tally-b3652
   firebase functions:secrets:set RECOVERY_CODE_SECRET --project tally-b3652
   ```

   Enter the sender email, Gmail app password and a separate random secret of at least 32 characters. Generate the latter locally using a password manager or `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"`; paste it into the secret prompt, then clear your clipboard. Changing it invalidates pending challenges. Grant secret access to the actual function runtime identity when prompted.
7. Review `firebase.json` and `firestore.rules`, back up existing deployed rules and deploy after configuration is complete:

   ```powershell
   firebase deploy --only functions,firestore:rules --project tally-b3652
   ```

   This deploys `verifyGooglePlayPurchase`, `refreshPurchaseEntitlements`, `beginLocalPasswordRecovery`, `verifyLocalPasswordRecovery`, and the retired `sendOtpEmail` endpoint, which now rejects requests. Node 22 is declared in `functions/package.json`. Existing older clients using the old mail endpoint must upgrade. Source push alone does not deploy any of this.
8. Check deployed runtime identity, secrets, App Check metrics and function logs without logging tokens, codes or passwords. Test a real delivered recovery email, wrong/expired/reused code, resend and successful local login with the new password. Verify the previous password fails and another local account is unchanged.
9. Test Play purchase and restore for each product, app restart, account switching, pending payment, refund/revocation, subscription renewal/cancellation/expiry and network loss. Confirm the token's obfuscated account binding and server-only entitlement document. Include a consumed coffee restore and interrupted-consumption retry. Confirm release store-unavailable and old sandbox preferences never unlock access. Do not ship until these live checks pass.

## Validation results — 24 October 2026

- Full Flutter suite: **222 passed**, zero failures.
- Static analysis: **no issues**.
- Node **22.23.4** server unit tests: **10 passed**.
- Firestore emulator tests: **10 passed**, including ownership/rules, replay, consumption retry, refunds and recovery concurrency/rate limits.
- npm audit: **zero vulnerabilities**, including development dependencies.
- Live Play, SMTP, deployed rules and device attestation remain unverified. No APK was built.

## Reproduce local validation without building an APK

From the root:

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded
cd functions
npm ci
npm test
npm audit
cd ..
firebase emulators:exec --only firestore --project demo-tally-security --config firebase.emulator.json "node --test functions/test/*.emulator.js"
```

Use Node 22 for these commands; the host installation may differ. The emulator tests refuse a non-local emulator host, clear only the demo database, and test real Firestore transactions/rules with controlled Play/email adapters. They do not prove production App Check attestation, Play API permissions or SMTP delivery. Client tests exercise strict lease parsing, session changes, delivery/completion ordering, release-policy gates, SQLite persistence and recovery UI failures. Platform attestation still requires a device integration check.

Evidence: [Flutter suite](audit-evidence/payment-flutter-full-tests.txt), [analysis](audit-evidence/payment-analyze.txt), [server unit tests](audit-evidence/payment-server-unit-tests.txt), [Firestore emulator tests](audit-evidence/payment-emulator-tests.txt), [npm audit](audit-evidence/payment-npm-audit.json), [live configuration inspection failure](audit-evidence/payment-firebase-config-check.txt).

For rollback, restore reviewed rules/backend source and redeploy with the same explicit project. Do not restore client-writable entitlements or the client-code email relay. Keep old verified token ownership records when rolling back to avoid replay and lost restore history. Existing debug signing and release-hardening findings still need attention before store distribution.
