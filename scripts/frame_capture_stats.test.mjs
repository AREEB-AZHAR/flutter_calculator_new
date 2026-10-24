import {test} from 'node:test';
import assert from 'node:assert/strict';
import {percentile, summarizeFrames} from './frame_capture_stats.mjs';

test('nearest-rank quantiles preserve source ordering', () => {
  const values = [30, 1, 10, 5];
  assert.equal(percentile(values, .5), 5);
  assert.equal(percentile(values, .95), 30);
  assert.deepEqual(values, [30, 1, 10, 5]);
});
test('jank uses max stage and the measured refresh budget, not stage sum', () => {
  const rows = [[1, 10000, 7000, 7000, 17000, 120], [2, 18333, 1000, 9000, 19000, 120]];
  const result = summarizeFrames(rows);
  assert.equal(result.jankyRatio, .5);
  assert.equal(result.worstStageMs, 9);
  assert.equal(result.vsyncIntervalMs.p50, 8.333);
  assert.equal(summarizeFrames(rows.map(r => [...r.slice(0, 5), 60])).jankyRatio, 0);
});
test('mixed rates, invalid rows and empty captures are rejected', () => {
  assert.throws(() => summarizeFrames([]));
  assert.throws(() => summarizeFrames([[1, 0, 1, 1, 1, 60], [2, 1, 1, 1, 1, 120]]), /Mixed/);
  assert.throws(() => summarizeFrames([[1, 0, NaN, 1, 1, 60], [2, 1, 1, 1, 1, 60]]), /Invalid/);
});
test('verified native surface rate overrides a stale Flutter display rate', () => {
  const rows = [[1, 10000, 7000, 7000, 17000, 120], [2, 26667, 1000, 9000, 19000, 120]];
  const stats = summarizeFrames(rows, {effectiveHz: 60});
  assert.equal(stats.jankyRatio, 0);
  assert.equal(stats.reportedDisplayHz, 120);
  assert.equal(stats.budgetMs, 1000 / 60);
});
