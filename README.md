# Moon Quantile

**可合并的流式分位数库 / Mergeable streaming quantiles in MoonBit.**

Summarize latency, payload sizes, or signed measurements without storing every
sample. Merge worker counters before computing global P50/P95/P99; averaging
worker percentiles does not yield a global percentile.

Pure MoonBit core, no FFI or third-party runtime packages. DDSketch-style
logarithmic bins with explicit capacity errors instead of silent collapsing.
AI-assisted original implementation; see [sources](docs/PROVENANCE.md).

## Build and run

Install the free [official toolchain](https://www.moonbitlang.com/download/).
Validated with moon 0.1.20261119, moonc v0.10.22+124d61d05 on Windows.
Uses the current `moon.mod` / `moon.pkg` format.

```sh
moon check
moon build
moon test
moon test --target wasm-gc
moon test --target js
moon run cmd/demo
moon build --target js
python tests/differential.py
```

The independent Python oracle needs Node 22+. The Wasm library needs neither.
Native remains unverified locally because a C compiler is absent. CI installs
the latest official toolchain; future compiler compatibility is not guaranteed.

Demo merges two service regions: approximately P50=15.03 ms, P95=P99=120.31 ms,
max=399.47 ms. With ten samples, lower-rank P99 selects the ninth observation.

## API

The executable `cmd/demo` is a working consumer of the public API. Import
`"Liqingqing001/moon_quantile" @sketch` in a consumer package. Registry
publication is pending; do not use `moon add` until a release exists.

```moonbit
let s = @sketch.Sketch::new(accuracy=0.01, capacity=4096).unwrap()
s.add(12.0).unwrap()
s.add(80.0, weight=3L).unwrap()
let p95 = s.quantile(0.95).unwrap()
let saved = s.to_json_string()
let restored = @sketch.Sketch::from_json_string(saved).unwrap()
```

`unwrap()` is for controlled examples. Applications must handle `Err`, especially
capacity rejection, and retain or route rejected observations explicitly.

| Contract | Behavior |
| --- | --- |
| Accuracy | alpha in [0.0001, 0.5], relative value error alpha plus floating-point roundoff |
| Values | zero or finite magnitude [1e-150, 1e150]; other values are rejected |
| Quantile | lower rank `floor(q*(n-1))`, Double rank arithmetic, no interpolation |
| Empty | `Ok(None)`; invalid q still errors |
| Weights | positive Int64; total at most 2^53-1, no fractional weights |
| Capacity | maximum occupied signed bins; zero counter is separate |
| Failure | add and merge errors leave state unchanged |
| Merge | equal accuracy, target capacity applies, source unchanged; self-merge doubles counts |
| Snapshots | detached, sorted, versioned; count/key/order validation on restore |
| JSON | default 1 MiB input cap, depth limit, duplicate keys rejected |
| Concurrency | caller serializes access; separate worker instances can be merged |

For B occupied bins: memory O(B), insertion O(log B), query O(B); multi-query
repeats scans. Merge uses O(B2) temporary copies and O((B1+B2) log B1) time.
JSON snapshots are not Datadog protobuf compatible. No deletion, sliding windows,
network exporter, fractional weights or formal floating-point proof is claimed.

## Three intended uses

1. Request latency: merge per-worker summaries for one reporting window.
2. Payload sizes: summarize wide size ranges with a fixed bin budget.
3. Signed numerical residuals: retain both tails and zero, persist snapshots.

## Evidence and project status

11 test blocks pass on Wasm, Wasm-GC and JS. An independent Python exact-sort
oracle passes 1,200 quantile checks across 20 datasets and five precision settings,
100 merge/restore comparisons and three invalid CLI cases. See
[validation](docs/VALIDATION.md). All inputs are synthetic.

MoonBit implements the library and CLI. Python is only a test oracle; JavaScript
is compiler output. Development started 2026-11-24. Competition registration,
organizer acceptance and Mooncakes publication are pending. No award/payment has
been received; no external adoption or speed advantage is claimed. MIT license.
