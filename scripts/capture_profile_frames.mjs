// Collect a measurement-only entry point's FrameTimings. No VM URI is persisted.
// Usage: node scripts/capture_profile_frames.mjs <package> <route> <output.json> <expectedHz>
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {writeFile} from 'node:fs/promises';
import {summarizeFrames} from './frame_capture_stats.mjs';

const exec = promisify(execFile);
const adb = process.env.ANDROID_ADB || 'C:/Users/areeb/AppData/Local/Android/Sdk/platform-tools/adb.exe';
const [pkg, route, output, expected] = process.argv.slice(2);
if (!pkg || !route || !output || !expected) throw new Error('Expected package, route, output and effective Hz');
if (!/^[a-zA-Z0-9_.]+$/.test(pkg)) throw new Error('Invalid package identifier');
const shell = async (...args) => (await exec(adb, ['shell', ...args], {maxBuffer: 8 * 1024 * 1024})).stdout;
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
let ws;
let forwarded;
let rpc;

async function metadata() {
  const packageInfo = await shell('dumpsys', 'package', pkg);
  const display = await shell('dumpsys', 'display');
  const panel = display.match(/DisplayDeviceInfo\{"Built-in Screen"[^\n]*renderFrameRate ([\d.]+)/);
  const layers = (await shell('dumpsys', 'SurfaceFlinger', '--list')).split(/\r?\n/);
  const surface = layers.find(s => s.includes(pkg) && s.includes('(BLAST)'))?.match(/SurfaceView\[[a-zA-Z0-9_./]+\]\(BLAST\)#\d+/)?.[0];
  let period = null;
  // adb shell invokes a remote shell even with local execFile arguments. The
  // allowlisted surface contains parentheses, so quote it for that remote shell.
  if (surface) period = Number((await shell('dumpsys', 'SurfaceFlinger', '--latency', `'${surface}'`)).split(/\r?\n/)[0]);
  const battery = await shell('dumpsys', 'battery');
  const thermal = await shell('dumpsys', 'thermalservice');
  return {utc: new Date().toISOString(), deviceModel: (await shell('getprop', 'ro.product.model')).trim(),
    androidVersion: (await shell('getprop', 'ro.build.version.release')).trim(),
    package: pkg, versionName: packageInfo.match(/versionName=(\S+)/)?.[1],
    versionCode: Number(packageInfo.match(/versionCode=(\d+)/)?.[1]),
    debuggable: /flags=\[[^\]\n]*\bDEBUGGABLE\b/.test(packageInfo),
    panelRenderHz: panel ? Number(panel[1]) : null,
    surfacePeriodNs: Number.isFinite(period) && period > 0 ? period : null,
    surfacePeriodHz: period > 0 ? 1e9 / period : null,
    batteryTemperatureC: Number(battery.match(/temperature:\s*(\d+)/)?.[1]) / 10,
    thermalStatus: Number(thermal.match(/Thermal Status:\s*(\d+)/i)?.[1])};
}

async function gestures() {
  if (route === 'transaction_dialog' || route === 'promo_dialog') {
    await shell('input', 'tap', ...(route === 'transaction_dialog' ? ['960', '1935'] : ['360', '1550']));
    await pause(700);
    if (route === 'transaction_dialog') await shell('input', 'tap', '430', '550');
    await pause(1500);
    // Cancel through the dialog barrier. Two blind Back presses can exit the
    // Activity if the IME was not shown, invalidating later repetitions.
    await shell('input', 'tap', '20', '500');
    await pause(800);
    return;
  }
  // Fixed 1080x2400-device protocol: four slow drags, then two flings.
  for (const [y1, y2, ms, settle] of [
    [1800, 720, 600, 350], [720, 1800, 600, 350],
    [1800, 720, 600, 350], [720, 1800, 600, 350],
    [1800, 720, 100, 1200], [720, 1800, 100, 1800],
  ]) {
    await shell('input', 'swipe', '540', String(y1), '540', String(y2), String(ms));
    await pause(settle);
  }
}

try {
  const pid = (await shell('pidof', pkg)).trim().split(' ')[0];
  if (!pid) throw new Error('Target app is not running');
  const logs = (await exec(adb, ['logcat', '-d', '-v', 'brief', '--pid', pid, '-s', 'flutter'], {maxBuffer: 8 * 1024 * 1024})).stdout;
  const matches = [...logs.matchAll(/The Dart VM service is listening on (http:\/\/127\.0\.0\.1:\d+\/[^\s]+)/g)];
  if (!matches.length) throw new Error('No profile VM service announced for target process');
  const deviceUri = new URL(matches.at(-1)[1]);
  forwarded = (await exec(adb, ['forward', 'tcp:0', `tcp:${deviceUri.port}`])).stdout.trim();
  const uri = `ws://127.0.0.1:${forwarded}${deviceUri.pathname}ws`;
  ws = new WebSocket(uri);
  await new Promise((resolve, reject) => { ws.onopen = resolve; ws.onerror = () => reject(new Error('VM service connection failed')); });
  let id = 0;
  const pending = new Map();
  ws.onmessage = event => {
    const message = JSON.parse(event.data);
    const work = pending.get(message.id);
    if (work) { pending.delete(message.id); clearTimeout(work.timeout); message.error ? work.reject(new Error(message.error.message)) : work.resolve(message.result); }
  };
  rpc = (method, params = {}) => new Promise((resolve, reject) => {
    const key = String(++id);
    const timeout = setTimeout(() => { pending.delete(key); reject(new Error(`RPC timeout: ${method}`)); }, 20000);
    pending.set(key, {resolve, reject, timeout});
    ws.send(JSON.stringify({jsonrpc: '2.0', id: key, method, params}));
  });
  const vm = await rpc('getVM');
  const isolateId = (vm.isolates.find(i => i.name === 'main') || vm.isolates[0]).id;
  const extension = async action => {
    const response = await rpc(`ext.tallyperf.${action}`, {isolateId});
    return typeof response === 'string' ? JSON.parse(response) : response;
  };
  const info = await extension('info');
  if (info.mode !== 'profile') throw new Error('Debug/release captures are forbidden by this profile protocol');
  const initialMetadata = await metadata();
  const actualRate = m => m.surfacePeriodHz ?? m.panelRenderHz;
  if (Math.abs(actualRate(initialMetadata) - Number(expected)) > 0.2) throw new Error(`Native surface rate is ${actualRate(initialMetadata)}, expected ${expected}`);
  if (pkg.includes('floor_probe')) await rpc('ext.tallyperf.route', {isolateId, route});
  else {
    const x = {dashboard: 108, accounts: 756, insights: 324, goals: 540, profile: 972, transaction_dialog: 108}[route];
    if (x) await shell('input', 'tap', String(x), '2140');
    else if (!['transactions', 'promo_dialog'].includes(route)) throw new Error('Unsupported Tally route');
  }
  await pause(1800);
  await gestures(); // warm identical route and paint resources before capturing
  await pause(1200);
  const captures = [];
  for (let repetition = 1; repetition <= 3; repetition++) {
    const before = await metadata();
    // Flutter 3.41's Gradle profile type initWith(debug), so the Android
    // DEBUGGABLE flag cannot distinguish Dart JIT/debug from AOT/profile.
    // The entry point enforces kProfileMode and info.mode was checked above.
    if (Math.abs(actualRate(before) - Number(expected)) > .2) throw new Error('Native surface changed refresh rate before capture');
    // VM and FrameTiming use the monotonic trace clock. Exclude timings queued before begin.
    const timestamp = (await rpc('getVMTimelineMicros')).timestamp;
    await extension('begin');
    await gestures();
    await pause(1200);
    const raw = await extension('end');
    if (raw.truncated) throw new Error('Capture ring truncated');
    const frames = raw.frames.filter(f => f[1] >= timestamp).sort((a, b) => a[1] - b[1]);
    const stats = summarizeFrames(frames, {effectiveHz: actualRate(before)});
    if (Math.abs(stats.effectiveHz - Number(expected)) > 0.2) throw new Error('Refresh rate changed during capture');
    const after = await metadata();
    if (Math.abs(actualRate(after) - actualRate(before)) > .2) throw new Error('Native surface changed refresh rate during capture');
    const capture = {repetition, route, mode: 'profile', before, after,
      declaredCaptureInfo: {...raw, app: pkg, frames: undefined}, statistics: stats, columns: raw.columns, frames};
    captures.push(capture);
    await writeFile(output, JSON.stringify({protocol: route.endsWith('_dialog')
      ? 'Open dialog, show keyboard, dismiss through barrier; warmed; 3 repetitions; no text input or save'
      : '4 alternating 600ms drags + 2 alternating 100ms flings; warmed; 3 repetitions',
      staticControl: route === 'static' ? 'Continuous vsync requests; unchanged retained scene, no widget/paint mutation' : undefined,
      rendererLog: logs.split(/\r?\n/).filter(l => /Using the .* rendering backend/.test(l)).map(l => l.replace(/^.*Using the /, 'Using the ')), captures}, null, 2) + '\n');
    console.log(JSON.stringify({route, repetition, ...stats}));
    await pause(1000);
  }
} finally {
  ws?.close();
  if (forwarded) await exec(adb, ['forward', '--remove', `tcp:${forwarded}`]).catch(() => {});
}
