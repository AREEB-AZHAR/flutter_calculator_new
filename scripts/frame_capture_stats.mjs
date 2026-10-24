// Shared measurement math only. No application/runtime dependency.
export function percentile(values, fraction) {
  if (!values.length) throw new Error('No frame samples');
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.max(0, Math.ceil(sorted.length * fraction) - 1)];
}

export function summarizeFrames(frames, {effectiveHz} = {}) {
  if (frames.length < 2) throw new Error('At least two frames are required');
  for (const row of frames) {
    if (row.length !== 6 || !row.every(Number.isFinite) || row[5] <= 0 || row[2] < 0 || row[3] < 0) {
      throw new Error('Invalid FrameTiming row');
    }
  }
  const rates = frames.map(f => f[5]);
  if (Math.max(...rates) - Math.min(...rates) > 0.1) {
    throw new Error('Mixed effective refresh rates; discard this capture');
  }
  const reportedDisplayHz = percentile(rates, 0.5);
  const hz = effectiveHz ?? reportedDisplayHz;
  if (!Number.isFinite(hz) || hz <= 0) throw new Error('Invalid effective refresh rate');
  const build = frames.map(f => f[2] / 1000);
  const raster = frames.map(f => f[3] / 1000);
  const stats = xs => ({p50: percentile(xs, 0.5), p95: percentile(xs, 0.95), worst: Math.max(...xs)});
  const budgetMs = 1000 / hz;
  const jankyFrames = frames.filter(f => Math.max(f[2], f[3]) / 1000 > budgetMs).length;
  const deltas = frames.slice(1).map((f, i) => (f[1] - frames[i][1]) / 1000).filter(d => d > 0);
  return {frames: frames.length, effectiveHz: hz, reportedDisplayHz, budgetMs,
    buildMs: stats(build), rasterMs: stats(raster),
    worstStageMs: Math.max(...build, ...raster), worstTotalSpanMs: Math.max(...frames.map(f => f[4] / 1000)),
    jankyFrames, jankyRatio: jankyFrames / frames.length, jankyPercent: jankyFrames / frames.length * 100,
    vsyncIntervalMs: deltas.length ? stats(deltas) : null};
}
