"""Independent exact-sort oracle. Run after moon build --target js.

Only Python stdlib and Node are required. Fixed seeds make failures reproducible.
No production algorithm is reimplemented in this oracle.
"""
import json
import math
from pathlib import Path
import random
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "_build/js/debug/build/cmd/quantile/quantile.js"
QS = [0, .001, .01, .1, .25, .5, .75, .9, .95, .99, .999, 1]
rng = random.Random(20261124)
cases = {
    "empty": [],
    "singleton": [42.5],
    "zeros": [0.0] * 80,
    "latency_long_tail": [rng.lognormvariate(3, 2) for _ in range(500)],
    "signed_normal": [rng.gauss(0, 100) for _ in range(500)],
    "duplicates": [-10.0] * 120 + [0.0] * 130 + [500.0] * 250,
    "extreme_magnitudes": [-1e150, -1e-150, 0, 1e-150, 1e150],
    "ordered": [float(x) for x in range(-200, 201)],
    "reverse": [float(x) for x in range(200, -201, -1)],
    "wide_dynamic_range": [10 ** rng.uniform(-140, 140) for _ in range(400)],
}
for i in range(10):
    cases[f"random_signed_{i}"] = [rng.choice([-1, 1]) * 10 ** rng.uniform(-12, 12) for _ in range(200)]

checks = 0
worst_ratio = 0.0
for alpha in [0.0001, .001, .01, .1, .5]:
    for name, values in cases.items():
        request = dict(values=values, quantiles=QS, accuracy=alpha, capacity=4096)
        process = subprocess.run(["node", str(CLI), json.dumps(request, separators=(",", ":"))],
                                 capture_output=True, text=True, check=True)
        report = json.loads(process.stdout)
        assert int(report["count"]) == len(values), (name, report)
        assert report["estimates"] == report["merged_estimates"], name
        assert report["estimates"] == report["restored_estimates"], name
        ordered = sorted(values)
        for q, estimate in zip(QS, report["estimates"]):
            checks += 1
            if not values:
                assert estimate is None
                continue
            exact = ordered[math.floor(q * (len(values) - 1))]
            if exact == 0:
                assert estimate == 0, (name, q, estimate)
            else:
                error = abs(estimate / exact - 1)
                assert error <= alpha + 1e-12, (name, alpha, q, exact, estimate, error)
                worst_ratio = max(worst_ratio, error / alpha)

for bad in ["not-json", '{"values":[],"values":[]}', json.dumps(dict(
        values=[1e151], quantiles=[.5], accuracy=.01, capacity=10))]:
    process = subprocess.run(["node", str(CLI), bad], capture_output=True, text=True)
    assert process.returncode == 2, (bad, process.stdout, process.stderr)

result = dict(seed=20261124, datasets=len(cases), accuracy_settings=5,
              quantile_checks=checks, merge_and_restore_cases=len(cases)*5,
              invalid_cli_cases=3, max_error_divided_by_alpha=worst_ratio,
              oracle="Python exact sort, floor(q*(n-1))", status="passed")
print(json.dumps(result, indent=2))
