# Sources and ecosystem positioning

Checked 2026-11-24. Original MoonBit implementation assisted by OpenAI Codex.
AI-written code is not represented as manually written. Human understanding and
a human-written competition proposal remain necessary.

Algorithm: Masson, Rim, Lee, DDSketch, VLDB 2019:
https://www.vldb.org/pvldb/vol12/p2195-masson.pdf

Reference inspected: DataDog/sketches-py, Apache-2.0:
https://github.com/DataDog/sketches-py
https://github.com/DataDog/sketches-py/blob/master/ddsketch/mapping.py

Reference scope: logarithmic bin formula, representative value, lower-rank
semantics. No upstream source file copied or translated line by line. This is
not a complete Datadog port and does not implement its wire protocol.
gamma=(1+alpha)/(1-alpha), key=ceil(log(value)/log(gamma)),
representative=exp(key*log(gamma))*(1-alpha). Negative bins traverse in reverse.
Out-of-range values and excess capacity fail instead of silently collapsing bins.

MoonBit standard library, Apache-2.0: https://github.com/moonbitlang/core

## Existing alternatives

`superbigcup325/colenc` already includes t-digest and HyperLogLog:
https://mooncakes.io/docs/superbigcup325/colenc%400.1.4

Mooncakes searches for DDSketch / logarithmic quantile did not surface a direct
equivalent. This is limited search evidence, **not proof of absence**. Recheck
the registry and ask organizers before declaring an ecosystem gap.

The proposed distinction from t-digest is relative error in measurement values
across wide ranges, signed mergeable counters and explicit atomic resource
failures. No comparative speed, memory, adoption or priority claim is made.
JSON Schema, JSON Patch and retry candidates were dropped after active libraries
were found. The contribution should be judged on useful behavior, not code volume.

Synthetic test data uses a fixed seed. No employer code, customer records,
credentials or wallet material is used. The Python oracle uses only the stdlib.
