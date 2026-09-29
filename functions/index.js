const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const nodemailer = require("nodemailer");

// Define secrets for email credentials (set via `firebase functions:secrets:set`)
const emailUser = defineSecret("EMAIL_USER");
const emailPass = defineSecret("EMAIL_PASS");

/**
 * Cloud Function: sendOtpEmail
 *
 * Sends a 6-digit OTP verification code to the user's email for password reset.
 * Called from the Flutter app instead of Firebase's default sendPasswordResetEmail,
 * because the app uses local SQLite password hashes (not Firebase Auth) for login.
 *
 * Usage from Flutter:
 *   final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
 *   await callable.call({ 'email': 'user@example.com', 'otp': '847291' });
 */
exports.sendOtpEmail = onCall(
  {
    secrets: [emailUser, emailPass],
    // Rate limiting: max 10 calls per minute per user
    enforceAppCheck: false,
  },
  async (request) => {
    const { email, otp } = request.data;

    // Validate inputs
    if (!email || typeof email !== "string" || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }
    if (!otp || typeof otp !== "string" || otp.length !== 6) {
      throw new HttpsError("invalid-argument", "A valid 6-digit OTP is required.");
    }

    // Create transporter using Gmail (or any SMTP provider)
    // For Gmail: use an App Password, not your real password
    // Generate one at: https://myaccount.google.com/apppasswords
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: emailUser.value(),
        pass: emailPass.value(),
      },
    });

    const mailOptions = {
      from: `"Tally - Balance Tracker" <${emailUser.value()}>`,
      to: email,
      subject: "Your Password Reset Code",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f4f4f7; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f7; padding: 40px 20px;">
            <tr>
              <td align="center">
                <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 480px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08);">
                  <!-- Header -->
                  <tr>
                    <td style="background: linear-gradient(135deg, #6C63FF 0%, #4834d4 100%); padding: 32px 24px; text-align: center;">
                      <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px;">
                        🔐 Password Reset
                      </h1>
                    </td>
                  </tr>
                  <!-- Body -->
                  <tr>
                    <td style="padding: 32px 24px;">
                      <p style="color: #51545E; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
                        You requested a password reset for your <strong>Tally</strong> account. Use the verification code below to continue:
                      </p>
                      <!-- OTP Code Box -->
                      <div style="background-color: #f8f7ff; border: 2px dashed #6C63FF; border-radius: 12px; padding: 20px; text-align: center; margin: 0 0 24px;">
                        <span style="font-size: 36px; font-weight: 800; letter-spacing: 10px; color: #6C63FF; font-family: 'Courier New', monospace;">
                          ${otp}
                        </span>
                      </div>
                      <p style="color: #51545E; font-size: 14px; line-height: 1.6; margin: 0 0 8px;">
                        ⏱️ This code expires in <strong>10 minutes</strong>.
                      </p>
                      <p style="color: #85878E; font-size: 13px; line-height: 1.6; margin: 0;">
                        If you didn't request this reset, you can safely ignore this email. Your account remains secure.
                      </p>
                    </td>
                  </tr>
                  <!-- Footer -->
                  <tr>
                    <td style="background-color: #f9f9fb; padding: 20px 24px; text-align: center; border-top: 1px solid #eaeaec;">
                      <p style="color: #A8AAAF; font-size: 12px; margin: 0;">
                        Tally - Balance Tracker &bull; Sent automatically
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      return { success: true };
    } catch (error) {
      console.error("Error sending OTP email:", error);
      throw new HttpsError("internal", "Failed to send verification email. Please try again.");
    }
  }
);
