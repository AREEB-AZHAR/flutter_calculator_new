"use strict";
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { decodePlayPurchase, entitlementLease, hash } = require("../security");
const { createGooglePlayClient } = require("../google_play_client");
const now = Date.parse("2026-10-23T12:00:00Z");
for (const state of ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED", "SUBSCRIPTION_STATE_ON_HOLD", "SUBSCRIPTION_STATE_PAUSED", "SUBSCRIPTION_STATE_EXPIRED", "SUBSCRIPTION_STATE_PENDING"]) {
  test(`subscription state ${state} is evaluated with store expiry`, () => {
    const proof = { subscriptionState: state, lineItems: [{ productId: "tally_pro_monthly", expiryTime: new Date(now + 60000).toISOString() }], externalAccountIdentifiers: { obfuscatedExternalAccountId: hash("alice") } };
    assert.equal(decodePlayPurchase("tally_pro_monthly", proof, now).active,
      ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"].includes(state));
    proof.lineItems[0].expiryTime = new Date(now - 1).toISOString();
    assert.equal(decodePlayPurchase("tally_pro_monthly", proof, now).active, false);
  });
}
test("product mismatch, pending and refunded products cannot grant access", () => {
  const proof = { productLineItem: [{ productId: "tally_pro_lifetime", productOfferDetails: { refundableQuantity: 1 } }], purchaseStateContext: { purchaseState: "PENDING" } };
  assert.equal(decodePlayPurchase("tally_pro_lifetime", proof, now).active, false);
  proof.purchaseStateContext.purchaseState = "PURCHASED";
  assert.equal(decodePlayPurchase("tally_pro_lifetime", proof, now).active, true);
  proof.productLineItem[0].productOfferDetails.refundableQuantity = 0;
  assert.equal(decodePlayPurchase("tally_pro_lifetime", proof, now).active, false);
  assert.throws(() => decodePlayPurchase("tally_remove_ads", proof, now));
  assert.throws(() => decodePlayPurchase("unknown", proof, now));
});
test("leases never outlive subscription/trial expiry or refresh stale receipts", () => {
  const subscription = { productId: "tally_pro_monthly", active: true, expiryMs: now + 2000, checkedAtMs: now };
  const lease = entitlementLease("alice", [subscription], now);
  assert.equal(lease.pro_unlocked, true);
  assert.equal(lease.leaseExpiresAtMs, now + 2000);
  const old = { productId: "tally_pro_lifetime", active: true, checkedAtMs: now - 16 * 60000 };
  assert.equal(entitlementLease("alice", [old], now).pro_unlocked, false);
  const coffee = { productId: "tally_coffee_tip", active: true, firstVerifiedAtMs: now - 7 * 86400000 + 1000, checkedAtMs: now };
  assert.equal(entitlementLease("alice", [coffee], now).leaseExpiresAtMs, now + 1000);
  assert.equal(entitlementLease("alice", [{ ...coffee, firstVerifiedAtMs: now - 8 * 86400000 }], now).trial_expiry, null);
});
test("Publisher adapter fixes the package, uses V2 reads and encodes tokens", async () => {
  const requests = [];
  const play = createGooglePlayClient({ getClient: async () => ({ request: async (request) => { requests.push(request); return { data: { proof: true } }; } }) });
  await play.get("tally_pro_monthly", "token/with?reserved");
  await play.get("tally_remove_ads", "one-time");
  await play.consume("tally_coffee_tip", "coffee");
  assert.match(requests[0].url, /applications\/com\.areeb\.balance_tracker\/purchases\/subscriptionsv2\/tokens\/token%2Fwith%3Freserved$/);
  assert.match(requests[1].url, /purchases\/productsv2\/tokens\/one-time$/);
  assert.equal(requests[2].method, "POST");
  assert.match(requests[2].url, /products\/tally_coffee_tip\/tokens\/coffee:consume$/);
});
