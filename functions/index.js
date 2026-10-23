"use strict";
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { GoogleAuth } = require("google-auth-library");
const nodemailer = require("nodemailer");
const { createPurchaseService, createRecoveryService } = require("./security");
const { createGooglePlayClient } = require("./google_play_client");
initializeApp();
const db = getFirestore();
const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/androidpublisher"] });
const emailUser = defineSecret("EMAIL_USER");
const emailPass = defineSecret("EMAIL_PASS");
const recoverySecret = defineSecret("RECOVERY_CODE_SECRET");
const options = { enforceAppCheck: true, maxInstances: 10, timeoutSeconds: 60 };
const purchases = createPurchaseService({ db, play: createGooglePlayClient(auth) });
const recovery = createRecoveryService({ db, secret: () => recoverySecret.value(),
  async sendEmail(email, code) {
    const transporter = nodemailer.createTransport({ service: "gmail", auth: { user: emailUser.value(), pass: emailPass.value() }, connectionTimeout: 10000, socketTimeout: 15000 });
    await transporter.sendMail({ from: `Tally <${emailUser.value()}>`, to: email,
      subject: "Your Tally local vault recovery code",
      text: `Your Tally local vault recovery code is ${code}. It expires in 10 minutes and can be used once. This does not change your Google account password. If you did not request this, ignore this email.` });
  },
});
exports.verifyGooglePlayPurchase = onCall(options, (request) => purchases.verify(request));
exports.refreshPurchaseEntitlements = onCall(options, (request) => purchases.refresh(request));
const recoveryOptions = { ...options, secrets: [emailUser, emailPass, recoverySecret] };
exports.beginLocalPasswordRecovery = onCall(recoveryOptions, (request) => recovery.begin(request));
exports.verifyLocalPasswordRecovery = onCall(recoveryOptions, (request) => recovery.verify(request));
exports.sendOtpEmail = onCall(options, () => { throw new HttpsError("failed-precondition", "Update Tally to use local password recovery."); });
