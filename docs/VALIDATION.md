# Validation — 2026-11-24

Windows x86-64; moon 0.1.20261119 (738607b), moonc v0.10.22+124d61d05.

- Check, JS build and runnable demo passed.
- Wasm, Wasm-GC, JavaScript: 11/11 test blocks each.
- Independent Python sort: 1,200 quantile checks; 100 merge/restore comparisons;
  three invalid CLI cases passed. Maximum relative error / alpha:
  0.9992905400737939. See `tests/last-differential-result.json`.
- Native: blocked by absent C compiler, not a passing test.
- Remote Actions status is recorded separately after publication.

The oracle sorts raw observations; it does not reimplement the sketch formula.
It checks lower-rank order statistics over signed Gaussian data, lognormal
latencies, duplicates, zeros, sorted/reverse input, 280 decades of range and
endpoint magnitudes. Unit tests cover capacity, overflow, invalid snapshots,
source independence and self-merge. Large Int64 JSON roundtrips pass all backends.

Independent checks found and drove fixes for Node argv layout and MoonBit Option
JSON encoding. CLI output now uses explicit JSON null/numbers. No throughput,
process RSS, formal proof or production readiness claim is made. Bin capacity
bounds data structure cardinality; JSON parsing allocates within its input cap.
