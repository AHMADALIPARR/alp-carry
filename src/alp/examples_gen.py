# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

#!/usr/bin/env python3
"""Generate training examples for ALP induction.
Each example: (neural_out, constraint_spec, verified_solution).
Simulates the DSPy loop's runtime telemetry."""
import json, random

DIMS = 64
random.seed(0xC0FFEE)

def make_neural():
    return [random.uniform(-2.0, 2.0) for _ in range(DIMS)]

def verify_solution(neural, lo, hi, eps):
    """Ground-truth solver: clamp to [lo,hi], then project within eps."""
    out = []
    for j, v in enumerate(neural):
        c = max(lo[j], min(hi[j], v))
        e = max(v - eps, min(v + eps, c))
        out.append(e)
    return out

def main():
    examples = []
    for _trial in range(500):
        center = [random.uniform(-1, 1) for _ in range(DIMS)]
        width  = [random.uniform(0.1, 1.5) for _ in range(DIMS)]
        lo     = [center[j] - width[j] for j in range(DIMS)]
        hi     = [center[j] + width[j] for j in range(DIMS)]
        eps    = random.uniform(0.01, 0.3)
        neural = make_neural()
        refined = verify_solution(neural, lo, hi, eps)
        examples.append({
            "neural": neural,
            "lo": lo, "hi": hi, "eps": eps,
            "refined": refined,
            "spec": {"type": "clamp_project", "lo": lo, "hi": hi, "eps": eps}
        })
    with open("src/alp/examples.json", "w") as f:
        json.dump(examples, f)
    print(f"wrote {len(examples)} examples")

if __name__ == "__main__":
    main()
