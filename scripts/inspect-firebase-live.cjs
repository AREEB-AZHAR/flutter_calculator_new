// Read-only deployment inspection. Never reads secret payloads or prints credentials.
const path = require('node:path');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
const project = 'tally-b3652';
const number = '494819662703';
const app = '1:494819662703:android:1eed08eedd66202a07e69a';
async function main() {
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Sign in with firebase login first.');
  const credential = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const inspect = async (label, url, select) => {
    try {
      const response = await fetch(url, { headers: { Authorization: `Bearer ${credential.access_token}` }, signal: AbortSignal.timeout(30000) });
      const data = await response.json();
      return { label, status: response.status, ...(response.ok ? { result: select(data) } : { error: data.error?.message, details: data.error?.details?.map(d => ({ reason: d.reason, service: d.metadata?.service })) }) };
    } catch (error) { return { label, error: error.name }; }
  };
  const checks = [
    inspect('functions', `https://cloudfunctions.googleapis.com/v2/projects/${project}/locations/-/functions`, d => (d.functions || []).map(f => ({ name: f.name, state: f.state, runtime: f.buildConfig?.runtime, serviceAccount: f.serviceConfig?.serviceAccountEmail, uri: f.serviceConfig?.uri, secrets: f.serviceConfig?.secretEnvironmentVariables?.map(s => s.secret) }))),
    inspect('billing', `https://cloudbilling.googleapis.com/v1/projects/${project}/billingInfo`, d => ({ billingEnabled: d.billingEnabled })),
    inspect('enabledServices', `https://serviceusage.googleapis.com/v1/projects/${number}/services?filter=state:ENABLED&pageSize=200`, d => d.services?.map(s => s.config?.name)),
    inspect('playIntegrity', `https://firebaseappcheck.googleapis.com/v1/projects/${number}/apps/${app}/playIntegrityConfig`, d => d),
    ...['EMAIL_USER', 'EMAIL_PASS', 'RECOVERY_CODE_SECRET'].map(name => inspect(name, `https://secretmanager.googleapis.com/v1/projects/${project}/secrets/${name}/versions`, d => d.versions?.map(v => ({ name: v.name, state: v.state })))),
  ];
  console.log(JSON.stringify({ project, checks: await Promise.all(checks) }, null, 2));
}
main().catch(() => { console.error('Inspection failed. Check Firebase login and network access; credentials were not printed.'); process.exitCode = 1; });
