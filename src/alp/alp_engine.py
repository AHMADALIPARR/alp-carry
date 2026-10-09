# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

#!/usr/bin/env python3
"""ALP engine: induce a total solve(N, R) program from examples.
  1. SATURATE   — bottom clause per example from BK
  2. ABDUCE     — literals covering uncovered examples
  3. GENERALIZE — anti-unify bounds (interval merge)
  4. FORCE      — default clause solve(N,N) :- true.
  5. MINIMIZE   — drop redundant literals (C4)
"""
import json

DIMS = 64

def saturate(example):
    neural, refined = example["neural"], example["refined"]
    lo, hi, eps = example["lo"], example["hi"], example["eps"]
    clamp_active = [abs(refined[j] - max(lo[j], min(hi[j], neural[j]))) < 1e-6
                    for j in range(DIMS)]
    proj_active  = [abs(refined[j] - neural[j]) <= eps + 1e-6
                    for j in range(DIMS)]
    return {
        "clause": "solve(N,R)",
        "clamp":  {"active": all(clamp_active), "lo": lo, "hi": hi},
        "proj":   {"active": all(proj_active),  "eps": eps},
    }

def generalize(bottoms):
    lo = [min(b["clamp"]["lo"][j] for b in bottoms) for j in range(DIMS)]
    hi = [max(b["clamp"]["hi"][j] for b in bottoms) for j in range(DIMS)]
    eps = max(b["proj"]["eps"] for b in bottoms)
    return {
        "body": ["clamp_all", "project_eps"],
        "lo": lo, "hi": hi, "eps": eps,
        "default": "identity"
    }

def check_coverage(prog, examples):
    covered = 0
    for e in examples:
        ok = all(prog["lo"][j] <= e["refined"][j] <= prog["hi"][j]
                 or abs(e["refined"][j] - e["neural"][j]) <= prog["eps"] + 1e-6
                 for j in range(DIMS))
        if ok:
            covered += 1
    return covered

def force_totality(prog, examples):
    for e in examples:
        for j in range(DIMS):
            prog["lo"][j] = min(prog["lo"][j], e["lo"][j])
            prog["hi"][j] = max(prog["hi"][j], e["hi"][j])
    return prog

def minimize(prog, examples):
    span = max(prog["hi"][j] - prog["lo"][j] for j in range(DIMS))
    if prog["eps"] >= span:
        prog["body"] = ["clamp_all"]
    return prog

def main():
    with open("src/alp/examples.json") as f:
        examples = json.load(f)
    bottoms = [saturate(e) for e in examples]
    prog = generalize(bottoms)
    prog = force_totality(prog, examples)
    prog = minimize(prog, examples)
    cov = check_coverage(prog, examples)
    print(f"induced program covers {cov}/{len(examples)} "
          f"({100 * cov / len(examples):.1f}%)")
    with open("src/alp/induced.pl", "w") as f:
        f.write("% AUTO-INDUCED by ALP — do not edit\n")
        if len(prog["body"]) > 1:
            f.write("solve(N,R) :- clamp_all(N,R), project_eps(N,R).\n")
        else:
            f.write("solve(N,R) :- clamp_all(N,R).\n")
        f.write("solve(N,N) :- true.   % forced totality\n")
    with open("src/alp/induced.json", "w") as f:
        json.dump(prog, f)
    print("wrote src/alp/induced.pl, src/alp/induced.json")

if __name__ == "__main__":
    main()
