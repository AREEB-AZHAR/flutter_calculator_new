// Enable only the API services required for Tally verification. No IAM grants or keys.
const path = require('node:path');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
async function main() {
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Login required');
  const credential = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  for (const service of ['androidpublisher.googleapis.com', 'firebaseappcheck.googleapis.com', 'playintegrity.googleapis.com']) {
    const response = await fetch(`https://serviceusage.googleapis.com/v1/projects/494819662703/services/${service}:enable`, {
      method: 'POST', headers: { Authorization: `Bearer ${credential.access_token}`, 'Content-Type': 'application/json' },
      body: '{}', signal: AbortSignal.timeout(30000),
    });
    const data = await response.json();
    console.log(JSON.stringify({ service, status: response.status, operation: data.name, done: data.done, error: data.error?.message }));
    if (!response.ok) process.exitCode = 1;
  }
}
main().catch(() => { console.error('API enablement failed; credentials were not printed.'); process.exitCode = 1; });
