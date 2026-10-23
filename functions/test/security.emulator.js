"use strict";
const { test, before, beforeEach, after } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { initializeApp, deleteApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, setDoc, getDoc } = require("firebase/firestore");
const { createPurchaseService, createRecoveryService, hash } = require("../security");
const projectId = "demo-tally-security";
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || "")) throw new Error("Tests require a local Firestore emulator; production access is prohibited.");
let env, app, db, clock, proofs, purchases, recovery, sent;
const request = (data, uid = "alice") => ({ data, app: { appId: "test-app" }, auth: uid ? { uid } : null, rawRequest: { ip: "127.0.0.1" } });
const product = (id, uid = "alice", state = "PURCHASED") => ({ purchaseStateContext: { purchaseState: state },
  obfuscatedExternalAccountId: hash(uid), productLineItem: [{ productId: id, productOfferDetails: { refundableQuantity: 1 } }] });
const verify = (productId, token, uid) => purchases.verify(request({ productId, token, source: "google_play" }, uid));
before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  env = await initializeTestEnvironment({ projectId, firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") } });
  app = initializeApp({ projectId }, "security-tests");
  db = getFirestore(app);
});
beforeEach(async () => {
  await env.clearFirestore();
  clock = Date.parse("2026-10-23T12:00:00Z");
  proofs = new Map(); sent = [];
  purchases = createPurchaseService({ db, now: () => clock, play: {
    get: async (_, token) => { const value = proofs.get(token); if (value instanceof Error) throw value; if (!value) throw new Error("unavailable"); return structuredClone(value); },
    consume: async (_, token) => { proofs.get(token).productLineItem[0].productOfferDetails.consumptionState = "CONSUMPTION_STATE_CONSUMED"; },
  } });
  recovery = createRecoveryService({ db, now: () => clock, secret: () => "test-only-recovery-secret-at-least-32-characters", randomCode: () => "123456",
    sendEmail: async (email, code) => { sent.push({ email, code }); } });
});
after(async () => { await env?.cleanup(); await db?.terminate(); if (app) await deleteApp(app); });

test("rules deny entitlement/receipt forgery without disrupting any other owner data", async () => {
  const alice = env.authenticatedContext("alice").firestore();
  const bob = env.authenticatedContext("bob").firestore();
  for (const collection of ["transactions", "goals", "vault", "profiles", "accounts", "budgets", "custom-existing-data"]) {
    await assertSucceeds(setDoc(doc(alice, `users/alice/${collection}/sample`), { sample: true }));
    await assertFails(getDoc(doc(bob, `users/alice/${collection}/sample`)));
  }
  for (const collection of ["monetization", "purchases"]) {
    await assertFails(setDoc(doc(alice, `users/alice/${collection}/entitlements`), { pro_unlocked: true, schema: 2 }));
    await assertFails(setDoc(doc(alice, `users/alice/${collection}/entry/nested/bypass`), { pro_unlocked: true }));
  }
  for (const collection of ["private_purchase_tokens", "private_recovery_challenges", "private_recovery_active", "private_rate_limits"]) {
    await assertFails(setDoc(doc(alice, `${collection}/secret`), { uid: "alice" }));
    await assertFails(getDoc(doc(alice, `${collection}/secret`)));
  }
});
test("paid verification requires App Check, authentication, supported source/product and store proof", async () => {
  await assert.rejects(purchases.verify({ data: {} }), { code: "failed-precondition" });
  await assert.rejects(purchases.verify(request({}, null)), { code: "unauthenticated" });
  await assert.rejects(purchases.verify(request({ source: "app_store" })), { code: "invalid-argument" });
  await assert.rejects(verify("unknown", "forged"), { code: "invalid-argument" });
  await assert.rejects(verify("tally_pro_lifetime", "forged"), { code: "unavailable" });
  assert.equal((await db.collection("private_purchase_tokens").get()).size, 0);
});
test("token ownership and store account binding prevent cross-account replay", async () => {
  proofs.set("lifetime", product("tally_pro_lifetime"));
  const result = await verify("tally_pro_lifetime", "lifetime");
  assert.equal(result.entitlements.pro_unlocked, true);
  await assert.rejects(verify("tally_pro_lifetime", "lifetime", "bob"), { code: "permission-denied" });
  proofs.set("unbound", { ...product("tally_pro_lifetime"), obfuscatedExternalAccountId: undefined });
  await assert.rejects(verify("tally_pro_lifetime", "unbound"), { code: "permission-denied" });
  proofs.set("wrong-product", product("tally_remove_ads"));
  await assert.rejects(verify("tally_pro_lifetime", "wrong-product"), { code: "permission-denied" });
  assert.equal((await db.collection("private_purchase_tokens").get()).size, 1);
});
test("concurrent replay grants coffee once and refresh handles consumption, refund and outages", async () => {
  proofs.set("coffee", product("tally_coffee_tip"));
  await Promise.all([verify("tally_coffee_tip", "coffee"), verify("tally_coffee_tip", "coffee")]);
  const initial = (await db.collection("private_purchase_tokens").doc(hash("coffee")).get()).data().firstVerifiedAtMs;
  clock += 86400000;
  const refreshed = await purchases.refresh(request({}));
  assert.equal(Date.parse(refreshed.trial_expiry), initial + 7 * 86400000);
  assert.equal((await db.collection("private_purchase_tokens").get()).size, 1);
  proofs.get("coffee").purchaseStateContext.purchaseState = "CANCELLED";
  const revoked = await purchases.refresh(request({}));
  assert.equal(revoked.ads_removed, false);
  assert.equal(revoked.trial_expiry, null);
  proofs.set("coffee", new Error("Google outage"));
  await assert.rejects(purchases.refresh(request({})), { code: "unavailable" });
});
test("coffee consumption failure retains ownership for retry and missing receipts revoke access", async () => {
  const proof = product("tally_coffee_tip");
  let failConsumption = true;
  let missing = false;
  purchases = createPurchaseService({ db, now: () => clock, play: {
    get: async () => {
      if (missing) throw Object.assign(new Error("gone"), { response: { status: 404 } });
      return proof;
    },
    consume: async () => {
      if (failConsumption) throw new Error("transient consumption error");
      proof.productLineItem[0].productOfferDetails.consumptionState = "CONSUMPTION_STATE_CONSUMED";
    },
  } });
  await assert.rejects(verify("tally_coffee_tip", "retry-coffee"), { code: "unavailable" });
  const ref = db.collection("private_purchase_tokens").doc(hash("retry-coffee"));
  const original = (await ref.get()).data();
  assert.equal(original.uid, "alice");
  failConsumption = false;
  clock += 60000;
  assert.equal((await verify("tally_coffee_tip", "retry-coffee")).active, true);
  assert.equal((await ref.get()).data().firstVerifiedAtMs, original.firstVerifiedAtMs);
  missing = true;
  const lease = await purchases.refresh(request({}));
  assert.equal(lease.ads_removed, false);
  assert.equal(lease.trial_expiry, null);
});

test("subscription renewal, expiry, revocation and linked-token replacement reconcile", async () => {
  const sub = (id, expiry, linked) => ({ subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", externalAccountIdentifiers: { obfuscatedExternalAccountId: hash("alice") },
    lineItems: [{ productId: id, expiryTime: new Date(expiry).toISOString() }], ...(linked ? { linkedPurchaseToken: linked } : {}) });
  proofs.set("monthly", sub("tally_pro_monthly", clock + 10000));
  assert.equal((await verify("tally_pro_monthly", "monthly")).entitlements.pro_unlocked, true);
  proofs.set("yearly", sub("tally_pro_yearly", clock + 60000, "monthly"));
  await verify("tally_pro_yearly", "yearly");
  proofs.get("yearly").subscriptionState = "SUBSCRIPTION_STATE_ON_HOLD";
  assert.equal((await purchases.refresh(request({}))).pro_unlocked, false, "superseded monthly must not reactivate");
  proofs.get("yearly").subscriptionState = "SUBSCRIPTION_STATE_ACTIVE";
  proofs.get("yearly").lineItems[0].expiryTime = new Date(clock + 120000).toISOString();
  assert.equal((await purchases.refresh(request({}))).pro_unlocked, true);
  clock += 120001;
  assert.equal((await purchases.refresh(request({}))).pro_unlocked, false);
});
test("server-generated recovery code is hashed, expires, and is consumed once under concurrency", async () => {
  const begun = await recovery.begin(request({ email: " Alice@Example.Test " }, null));
  assert.deepEqual(sent, [{ email: "alice@example.test", code: "123456" }]);
  assert.equal(begun.code, undefined);
  const stored = (await db.collection("private_recovery_challenges").doc(begun.challengeId).get()).data();
  assert.equal(stored.code, undefined);
  assert.notEqual(stored.codeHash, "123456");
  const outcomes = await Promise.allSettled([recovery.verify(request({ challengeId: begun.challengeId, code: "123456" }, null)), recovery.verify(request({ challengeId: begun.challengeId, code: "123456" }, null))]);
  assert.equal(outcomes.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal(outcomes.find((r) => r.status === "fulfilled").value.email, "alice@example.test");
});
test("wrong recovery attempts commit and lock after five; expiration is server-enforced", async () => {
  const begun = await recovery.begin(request({ email: "alice@example.test" }, null));
  for (let i = 0; i < 5; i++) await assert.rejects(recovery.verify(request({ challengeId: begun.challengeId, code: "999999" }, null)), { code: "permission-denied" });
  assert.equal((await db.collection("private_recovery_challenges").doc(begun.challengeId).get()).data().attempts, 5);
  await assert.rejects(recovery.verify(request({ challengeId: begun.challengeId, code: "123456" }, null)), { code: "permission-denied" });
  clock += 60001;
  const next = await recovery.begin(request({ email: "alice@example.test" }, null));
  clock += 600001;
  await assert.rejects(recovery.verify(request({ challengeId: next.challengeId, code: "123456" }, null)), { code: "permission-denied" });
});
test("resend invalidates the previous challenge and rate limits cannot be bypassed by parallel calls", async () => {
  const first = await recovery.begin(request({ email: "alice@example.test" }, null));
  const attempts = await Promise.allSettled(Array.from({ length: 3 }, () => recovery.begin(request({ email: "alice@example.test" }, null))));
  assert(attempts.every((r) => r.status === "rejected"));
  clock += 60001;
  const second = await recovery.begin(request({ email: "alice@example.test" }, null));
  await assert.rejects(recovery.verify(request({ challengeId: first.challengeId, code: "123456" }, null)), { code: "permission-denied" });
  assert.equal((await recovery.verify(request({ challengeId: second.challengeId, code: "123456" }, null))).verified, true);
});
test("missing App Check/client-selected OTP/mail failure cannot report successful delivery", async () => {
  await assert.rejects(recovery.begin({ data: { email: "alice@example.test" } }), { code: "failed-precondition" });
  await assert.rejects(recovery.begin(request({ email: "alice@example.test", otp: "111111" }, null)), { code: "invalid-argument" });
  const broken = createRecoveryService({ db, secret: () => "test-secret-longer-than-32-characters", now: () => clock, sendEmail: async () => { throw new Error("SMTP unavailable"); } });
  await assert.rejects(broken.begin(request({ email: "alice@example.test" }, null)), { code: "unavailable" });
  const challenges = await db.collection("private_recovery_challenges").get();
  assert.equal(challenges.docs[0].data().state, "failed");
});
