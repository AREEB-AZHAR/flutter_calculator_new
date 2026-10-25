// Recompute the archived investigation's numbers; no device or app mutations.
// Run from the repository root: node scripts/report_release_ad_captures.mjs
import assert from 'node:assert/strict';
import {readdir, readFile, writeFile} from 'node:fs/promises';
import {summarizeFrames} from './frame_capture_stats.mjs';

const directory = 'docs/audit-evidence';
const rows = [];
let thermalZero = 0;
let frameCount = 0;
for (const name of (await readdir(directory)).sort()) {
  if (!name.startsWith('release-ads-') || !name.endsWith('.json')) continue;
  const data = JSON.parse((await readFile(`${directory}/${name}`, 'utf8')).replace(/^\uFEFF/, ''));
  if (!data.captures) continue;
  assert.equal(data.captures.length, 3, `${name}: expected three repetitions`);
  for (const capture of data.captures) {
    const {before, after, statistics: stored, frames} = capture;
    assert.equal(capture.mode, 'profile');
    assert.equal(before.versionCode, after.versionCode);
    assert.ok(Math.abs(before.surfacePeriodHz - after.surfacePeriodHz) < 0.1);
    const stats = summarizeFrames(frames, {effectiveHz: before.surfacePeriodHz});
    assert.deepEqual(stats, stored, `${name}: summary differs from raw frames`);
    if (before.adState) {
      assert.equal(before.adState.adFree, false);
      assert.equal(after.adState.adFree, false);
    }
    if (before.thermalStatus === 0 && after.thermalStatus === 0) thermalZero++;
    frameCount += frames.length;
    const stages = metric => `${stats[metric].p50.toFixed(3)}/${stats[metric].p95.toFixed(3)}`;
    rows.push(`| [${name.slice(12, -5)}](${name}) | ${capture.repetition} | ${stats.frames} | ${stats.effectiveHz.toFixed(2)} | ${before.thermalStatus}/${after.thermalStatus} | ${stages('buildMs')} | ${stages('rasterMs')} | ${stats.buildMs.worst.toFixed(3)}/${stats.rasterMs.worst.toFixed(3)} | ${stats.jankyFrames}/${stats.frames} (${stats.jankyPercent.toFixed(3)}%) | ${stats.vsyncIntervalMs.p50.toFixed(3)} | ${before.adState?.activeTabNativeAdWidgets ?? '—'} |`);
  }
}
const path = `${directory}/release-ads-capture-inventory.md`;
const introduction = (await readFile(path, 'utf8')).split('| Configuration / raw capture')[0];
await writeFile(path, `${introduction}| Configuration / raw capture | Run | Frames | Surface Hz | Thermal before/after | Build p50/p95 | Raster p50/p95 | Worst build/raster | Over surface budget | Vsync delta p50 | Active native ad views |\n|---|---:|---:|---:|---|---|---|---|---|---:|---:|\n${rows.join('\n')}\n`);
const result = `PASS: ${rows.length} profile captures, ${frameCount} raw frames; all summaries exactly reproduce.\nThermal 0 before/after: ${thermalZero}; constrained: ${rows.length - thermalZero}.\nNo average FPS; surface-budget jank and sampled vsync deltas are distinct metrics.\n`;
await writeFile(`${directory}/release-ads-capture-validation.txt`, result);
console.log(result);
