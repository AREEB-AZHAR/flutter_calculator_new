# ADR — Firebase password authentication and local vault preservation

**Status:** Implemented; final validation recorded below.

**Date:** 26 October 2026

**Decision:** Owner requested Firebase Authentication for email/password accounts,
with existing accounts and financial data preserved. No APK build or push.

## Context and options

Tally historically authenticated password users against salted SQLite hashes,
while Google users authenticated through Firebase. Resetting a Firebase password
could not change that separate local credential. The earlier custom recovery-code
service attempted to bridge this split and required deployed Functions and mail
secrets. Those deployment prerequisites were not completed.

| Option | Operational requirements | Account authority | Decision |
| --- | --- | --- | --- |
| Existing local passwords plus custom recovery | Recovery backend, mail delivery, abuse controls | Local SQLite | Superseded for migrated accounts |
| Self-hosted recovery on a PC/VPS | HTTPS endpoint, storage, secrets, uptime and mail delivery | Local SQLite | Not adopted |
| Firebase email/password authentication | Enabled Email/Password provider and Firebase templates | Firebase Auth | Adopted |

Firebase Auth owns credentials and issues identity tokens. Firestore continues
to store financial data under `/users/{uid}` and its existing rules. No passwords
or password hashes are uploaded to Firestore. SQLite remains a local financial
cache; this migration does not add database encryption.

References: [password sign-in](https://firebase.google.com/docs/auth/flutter/password-auth),
[password changes and reset emails](https://firebase.google.com/docs/auth/flutter/manage-users),
[provider linking](https://firebase.google.com/docs/auth/flutter/account-linking).

## Migration plan and implemented behavior

1. **Preserve vault keys.** The additive local `firebase_identities` table maps
   the existing username to one unique Firebase UID, email and provider.
   Ledger tables are neither renamed nor merged. SQLite installs this table and
   a user-deletion cleanup trigger idempotently without a version bump.
2. **Migrate on successful sign-in.** There is no bulk password-hash import.
   Existing local hashes remain only for accounts that have not completed
   migration. Users enter their existing username or bound email online.
3. **Prove ownership.** For an existing Firebase account, Firebase must accept
   its credentials and the old local password must independently authorize
   attaching an unbound local vault. If those passwords differ, Tally asks for
   the previous local password. A local password never updates an existing
   Firebase password or creates a second account over it.
4. **Bootstrap a missing Firebase account.** Only after verifying the legacy
   password may Tally try Firebase account creation. `email-already-in-use`
   stops creation and instructs the user to sign in/reset the existing account.
   A password rejected as too short can be replaced with a stronger Firebase
   password after the local proof. An email-less account can supply an email.
5. **Verify email ownership.** Newly created accounts receive Firebase email
   verification. Sign-in and cloud sync require verified email. For legacy
   migration, no local credential is removed before verification. New
   registrations save their chosen local username with a pending UID binding
   so verification and later sign-in do not lose that name.
6. **Commit locally in one transaction.** The identity binding and replacement
   of the old local hash with the noncredential marker `FIREBASE_AUTH_ONLY`
   happen together. The salt becomes empty. Captured hashes, current Firebase
   UID/email and uniqueness constraints reject credential changes, account
   switches, conflicting bindings and deleted vaults during migration.
7. **Use UID identity throughout.** Cloud sync and purchase-session identity
   checks now match the saved UID, rather than assuming local username equals
   Firebase email. Purchase verification, paid grants, rules and server payloads
   are unchanged. Saved-account provider labels use the binding when available.
8. **Keep local unlocking separate.** Enrolled biometrics can unlock cached
   financial data offline. Fresh email/password sign-in, verification, resets
   and password changes require Firebase connectivity. There is no fallback to
   the stale local password for a migrated account. Async logout is serialized
   ahead of the next authentication request.

## Existing Google accounts and linking

Google sign-in returns the canonical local username, which all login and saved
account callers now use. A UID already bound to a vault always returns that
vault. An unbound password vault requires the old local password, an already
authenticated local session, or its enrolled biometric unlock. Historical Google
vaults retain compatibility only when their email-named local row also matches
the previously saved Google sign-in email; this is a legacy device-history
rule, not a general "matching email means Google" rule.

Settings links Google credentials to the current Firebase user using Firebase's
provider-linking API. It does not migrate/delete the current ledger or silently
merge two different Firebase accounts. A credential already owned by another
Firebase UID must be handled by signing into that account; Tally preserves both
local vaults. If a legacy Google vault has lost its device history and has no
local unlock proof, it is not silently attached by email alone.

## Password recovery and change

"Forgot password" resolves a saved username to its email, or accepts an email
directly on a new device, then calls Firebase `sendPasswordResetEmail`.
The dialog gives a generic result for unknown remote accounts and never asks for
an email code or replacement password. Firebase's hosted page verifies the link
and sets the new password. Return to Tally and sign in with the new credential.
This does not change the user's Google account password.

Settings → Change Password reauthenticates the matching Firebase user with the
current Firebase password, validates the replacement, then calls `updatePassword`.
No new password hash is stored locally. A Google-only account can use Firebase
reset/setup as supported by its configured provider; the app does not ask Google
to change its password.

An unmigrated local-only password **cannot be recovered by resetting Firebase**.
Its local data remains intact; the user still needs the previous local credential
or an already enrolled local unlock path to authorize attachment. Reset emails do
not restore unsynced records from another device. The UI explains these limits.

The old `PasswordRecoveryService` and its security fixtures remain for legacy
regression coverage; no current app recovery UI invokes it. Existing server
recovery endpoints are not deployed, changed or removed by this task. A later
cleanup can retire them after older clients are no longer supported.

## Firebase console setup and owner confirmation

The owner confirmed Email/Password is already enabled in `tally-b3652`.
Use Authentication → Templates → Password reset and Email address verification.
Keep `%LINK%` and the default Firebase-hosted action URL; the supplied screenshot
shows `https://tally-b3652.firebaseapp.com/__/auth/action`. A custom domain,
personal sending mailbox, SMTP password and recovery Function are not required
for these standard Firebase Auth emails. Firebase quotas still apply.

On 26 October, one owner-approved live `PASSWORD_RESET` request returned
**HTTP 200**, and the owner confirmed **the email arrived**. The address is omitted
from the public evidence. The agent did not open the link or change a password.
See [live email evidence](audit-evidence/firebase-auth-live-reset.json).

## Verification and remaining checks

Use the existing Flutter/Dart/JDK setup from README. No dependency changes.

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

`test/firebase_account_migration_test.dart` exercises legacy/current credential
proofs, verified-email gating, weak-password upgrades, registration, restart
persistence, failed migration rollback, all financial tables/outbox preservation,
ambiguous identifiers, changed UID/session, offline failures, Firebase recovery,
password changes, Google attachment and canonical AppState identity. Native
SQLite is real; Firebase is a controlled test backend. Existing registration,
biometric switching and Google-provider tests were updated for the new behavior.
The full suite retains existing ledger, recurring, purchase and recovery safety
checks.

Raw evidence: [analysis](audit-evidence/firebase-auth-analysis.txt),
[full suite](audit-evidence/firebase-auth-full-tests.txt),
[live email](audit-evidence/firebase-auth-live-reset.json).

Final result: **306 tests passed**, including **24 new migration/recovery tests**;
`flutter analyze --no-pub` reports **No issues found**. A previous test that
assumed an email-shaped username proved Google authentication was updated to
reject that assumption. A test-run overlap hit a Windows SQLite DLL copy error;
the final full suite was run sequentially and passed.

Actual phone registration/sign-in, browser link completion, expired/used Firebase
links, native Google provider linking and offline/reconnect behavior on the new
app build remain device checks. No APK was built or installed. The hosted reset
email was verified separately from client runtime behavior.

## Rollback guidance

Back up the app database before testing account migration on a device. Do not
remove `firebase_identities` or restore local-password login as a rollback:
migrated users intentionally have no reusable local password hash. Keep the
Firebase sign-in path available and roll forward with a fix. Unmigrated accounts
retain their original local credentials; financial tables remain unchanged.
