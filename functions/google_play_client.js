"use strict";
const { PACKAGE, SUBSCRIPTIONS } = require("./security");
function createGooglePlayClient(auth) {
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases`;
  return {
    async get(productId, token) {
      const client = await auth.getClient();
      const resource = SUBSCRIPTIONS.has(productId) ? "subscriptionsv2" : "productsv2";
      return (await client.request({ url: `${base}/${resource}/tokens/${encodeURIComponent(token)}`, timeout: 15000 })).data;
    },
    async consume(productId, token) {
      const client = await auth.getClient();
      await client.request({ method: "POST", timeout: 15000,
        url: `${base}/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}:consume` });
    },
  };
}
module.exports = { createGooglePlayClient };
