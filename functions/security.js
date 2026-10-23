"use strict";
const crypto = require("node:crypto");
const { HttpsError } = require("firebase-functions/v2/https");
const PACKAGE = "com.areeb.balance_tracker";
const PRODUCTS = new Set(["tally_pro_monthly", "tally_pro_yearly", "tally_pro_lifetime", "tally_remove_ads", "tally_coffee_tip"]);
const SUBSCRIPTIONS = new Set(["tally_pro_monthly", "tally_pro_yearly"]);
const hash = (value) => crypto.createHash("sha256").update(value).digest("hex");
const fail = (code, message) => { throw new HttpsError(code, message); };
function requireApp(request) {
  if (!request.app?.appId) fail("failed-precondition", "App verification is required.");
}
function requireUser(request) {
  requireApp(request);
  if (!request.auth?.uid) fail("unauthenticated", "Sign in with Google before purchasing.");
  return request.auth.uid;
}
function normalizedEmail(value) {
  if (typeof value !== "string" || value.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())) fail("invalid-argument", "Enter a valid email address.");
  return value.trim().toLowerCase();
}
async function rateLimit(db, entries, now) {
  await db.runTransaction(async (tx) => {
    const refs = entries.map((e) => db.collection("private_rate_limits").doc(hash(e.key)));
    const docs = await Promise.all(refs.map((ref) => tx.get(ref)));
    const values = docs.map((doc, i) => {
      const old = doc.data();
      const value = old && now < old.untilMs ? old : { count: 0, untilMs: now + entries[i].windowMs };
      if (value.count >= entries[i].limit) fail("resource-exhausted", "Too many attempts. Please try again later.");
      return { count: value.count + 1, untilMs: value.untilMs };
    });
    refs.forEach((ref, i) => tx.set(ref, values[i]));
  });
}
function decodePlayPurchase(productId, data, now) {
  if (!PRODUCTS.has(productId)) fail("invalid-argument", "Unknown product.");
  if (SUBSCRIPTIONS.has(productId)) {
    const lines = (data.lineItems || []).filter((line) => line.productId === productId);
    if (!lines.length) fail("permission-denied", "The receipt does not match this product.");
    const expiryMs = Math.max(...lines.map((line) => Date.parse(line.expiryTime) || 0));
    return { active: ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"].includes(data.subscriptionState) && expiryMs > now,
      expiryMs, accountId: data.externalAccountIdentifiers?.obfuscatedExternalAccountId,
      linkedToken: data.linkedPurchaseToken || null, consumed: false };
  }
  const line = (data.productLineItem || []).find((item) => item.productId === productId);
  if (!line) fail("permission-denied", "The receipt does not match this product.");
  const offer = line.productOfferDetails || {};
  return { active: data.purchaseStateContext?.purchaseState === "PURCHASED" && (offer.refundableQuantity ?? 1) > 0,
    expiryMs: null, accountId: data.obfuscatedExternalAccountId, linkedToken: null,
    consumed: offer.consumptionState === "CONSUMPTION_STATE_CONSUMED" };
}
function entitlementLease(uid, receipts, now) {
  const active = receipts.filter((r) => r.active && r.checkedAtMs > now - 15 * 60000);
  const lifetime = active.some((r) => r.productId === "tally_pro_lifetime");
  const subscriptionUntil = Math.max(0, ...active.filter((r) => SUBSCRIPTIONS.has(r.productId)).map((r) => r.expiryMs || 0));
  const trialUntil = Math.max(0, ...active.filter((r) => r.productId === "tally_coffee_tip").map((r) => r.firstVerifiedAtMs + 7 * 86400000));
  const expiries = [now + 15 * 60000, ...active.map((r) => r.checkedAtMs + 15 * 60000)];
  if (!lifetime && subscriptionUntil > now) expiries.push(subscriptionUntil);
  if (trialUntil > now) expiries.push(trialUntil);
  return { schema: 2, uid, issuedAtMs: now, leaseExpiresAtMs: Math.min(...expiries),
    pro_unlocked: lifetime || subscriptionUntil > now,
    ads_removed: active.some((r) => ["tally_remove_ads", "tally_coffee_tip"].includes(r.productId)),
    trial_expiry: trialUntil > now ? new Date(trialUntil).toISOString() : null };
}
function createPurchaseService({ db, play, now = Date.now }) {
  async function verifyToken(uid, productId, token) {
    if (!PRODUCTS.has(productId) || typeof token !== "string" || !token.length || token.length > 8192) fail("invalid-argument", "A supported product and purchase token are required.");
    const started = now();
    const ref = db.collection("private_purchase_tokens").doc(hash(token));
    const previous = (await ref.get()).data();
    if (previous && previous.uid !== uid) fail("permission-denied", "This purchase belongs to another account.");
    let record;
    try { record = decodePlayPurchase(productId, await play.get(productId, token), started); }
    catch (error) {
      if (previous && [404, 410].includes(error.response?.status)) record = { active: false, expiryMs: null, accountId: hash(uid), linkedToken: null, consumed: false };
      else if (error instanceof HttpsError) throw error;
      else fail("unavailable", "Google Play verification is unavailable. No access has been granted.");
    }
    if (record.accountId !== hash(uid) && !(previous?.uid === uid && !record.accountId)) fail("permission-denied", "Purchase account binding is missing or mismatched. Contact support for legacy purchases.");
    if (record.consumed && !previous) fail("permission-denied", "This consumed purchase has no verified ownership record.");
    const result = await db.runTransaction(async (tx) => {
      const current = (await tx.get(ref)).data();
      if (current && (current.uid !== uid || current.productId !== productId)) fail("permission-denied", "Purchase ownership mismatch.");
      const linkedRef = record.linkedToken ? db.collection("private_purchase_tokens").doc(hash(record.linkedToken)) : null;
      const linked = linkedRef ? (await tx.get(linkedRef)).data() : null;
      if (linked && linked.uid !== uid) fail("permission-denied", "Linked purchase belongs to another account.");
      const all = await tx.get(db.collection("private_purchase_tokens").where("uid", "==", uid));
      const value = current && current.checkedAtMs > started ? current : { uid, productId, token,
        active: record.active && !current?.supersededBy, supersededBy: current?.supersededBy ?? null, expiryMs: record.expiryMs, firstVerifiedAtMs: current?.firstVerifiedAtMs ?? (record.active ? started : null), checkedAtMs: started };
      const receipts = all.docs.filter((doc) => doc.id !== ref.id && doc.id !== linkedRef?.id).map((doc) => doc.data());
      receipts.push(value);
      const lease = entitlementLease(uid, receipts, now());
      tx.set(ref, value);
      if (linked) tx.update(linkedRef, { active: false, supersededBy: ref.id });
      tx.set(db.collection("users").doc(uid).collection("monetization").doc("entitlements"), lease);
      return { verified: true, active: value.active, productId, tokenHash: hash(token), entitlements: lease };
    });
    if (productId === "tally_coffee_tip" && result.active && !record.consumed) {
      try { await play.consume(productId, token); }
      catch (_) { fail("unavailable", "Purchase recorded; consumption will be retried before completion."); }
    }
    return result;
  }
  return {
    async verify(request) {
      const uid = requireUser(request);
      if (request.data?.source !== "google_play") fail("invalid-argument", "Only Google Play purchases are supported.");
      await rateLimit(db, [{ key: `purchase:${uid}`, limit: 30, windowMs: 60000 }], now());
      return verifyToken(uid, request.data.productId, request.data.token);
    },
    async refresh(request) {
      const uid = requireUser(request);
      await rateLimit(db, [{ key: `refresh:${uid}`, limit: 10, windowMs: 60000 }], now());
      const receipts = await db.collection("private_purchase_tokens").where("uid", "==", uid).get();
      for (const doc of receipts.docs) { const r = doc.data(); await verifyToken(uid, r.productId, r.token); }
      return db.runTransaction(async (tx) => {
        const current = await tx.get(db.collection("private_purchase_tokens").where("uid", "==", uid));
        const lease = entitlementLease(uid, current.docs.map((doc) => doc.data()), now());
        tx.set(db.collection("users").doc(uid).collection("monetization").doc("entitlements"), lease);
        return lease;
      });
    },
  };
}
function createRecoveryService({ db, sendEmail, secret, now = Date.now, randomCode = () => crypto.randomInt(0, 1000000).toString().padStart(6, "0") }) {
  const digest = (id, email, code) => crypto.createHmac("sha256", secret()).update(`${id}:${email}:${code}`).digest("hex");
  return {
    async begin(request) {
      requireApp(request);
      if (Object.hasOwn(request.data || {}, "otp")) fail("invalid-argument", "Codes are generated by the server.");
      const email = normalizedEmail(request.data?.email);
      const time = now();
      const ip = request.rawRequest?.ip;
      if (!ip) fail("failed-precondition", "Request identity is unavailable.");
      await rateLimit(db, [
        { key: `recovery-minute:${email}`, limit: 1, windowMs: 60000 },
        { key: `recovery-hour:${email}`, limit: 5, windowMs: 3600000 },
        { key: `recovery-ip:${ip}`, limit: 30, windowMs: 3600000 },
      ], time);
      const key = secret();
      if (typeof key !== "string" || key.length < 32) fail("failed-precondition", "Recovery email is not configured.");
      const id = crypto.randomUUID();
      const code = randomCode();
      const ref = db.collection("private_recovery_challenges").doc(id);
      await ref.set({ email, codeHash: digest(id, email, code), expiresAtMs: time + 600000, attempts: 0, state: "sending", appId: request.app.appId });
      try {
        await sendEmail(email, code);
        await db.runTransaction(async (tx) => {
          tx.update(ref, { state: "ready" });
          tx.set(db.collection("private_recovery_active").doc(hash(email)), { challengeId: id });
        });
      }
      catch (_) { await ref.update({ state: "failed" }); fail("unavailable", "Could not send the recovery email. Please try again later."); }
      return { challengeId: id, expiresAtMs: time + 600000 };
    },
    async verify(request) {
      requireApp(request);
      const { challengeId, code } = request.data || {};
      if (typeof challengeId !== "string" || !/^[a-f0-9-]{36}$/.test(challengeId) || typeof code !== "string" || !/^\d{6}$/.test(code)) fail("invalid-argument", "Enter the six-digit code from your email.");
      const ip = request.rawRequest?.ip;
      if (!ip) fail("failed-precondition", "Request identity is unavailable.");
      await rateLimit(db, [{ key: `verify-recovery:${ip}`, limit: 60, windowMs: 60000 }], now());
      const ref = db.collection("private_recovery_challenges").doc(challengeId);
      const result = await db.runTransaction(async (tx) => {
        const value = (await tx.get(ref)).data();
        if (!value || value.state !== "ready" || value.appId !== request.app.appId || value.expiresAtMs <= now() || value.attempts >= 5) return null;
        const active = (await tx.get(db.collection("private_recovery_active").doc(hash(value.email)))).data();
        if (active?.challengeId !== challengeId) return null;
        const expected = Buffer.from(value.codeHash, "hex");
        const supplied = Buffer.from(digest(challengeId, value.email, code), "hex");
        const matches = expected.length === supplied.length && crypto.timingSafeEqual(expected, supplied);
        // Commit wrong attempts; throwing inside this transaction would undo them.
        tx.update(ref, { attempts: value.attempts + 1, state: matches ? "used" : "ready" });
        return matches ? value.email : null;
      });
      if (!result) fail("permission-denied", "Invalid, expired or already-used recovery code.");
      return { verified: true, email: result, challengeId };
    },
  };
}
module.exports = { PACKAGE, PRODUCTS, SUBSCRIPTIONS, hash, decodePlayPurchase, entitlementLease, createPurchaseService, createRecoveryService };
