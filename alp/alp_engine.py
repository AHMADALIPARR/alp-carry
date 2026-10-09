# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

# alp_engine.py — offline induction. Runtime never interprets clauses.
from dataclasses import dataclass, field

@dataclass
class Clause:
    head: str
    body: list
    consts: dict = field(default_factory=dict)

def saturate(neural, spec, verified, bk):
    """Most specific clause covering one (neural, spec, verified) triple."""
    body = []
    consts = {}
    for lit in spec:
        kind = lit[0]
        if kind == "clamp":
            _, i, lo, hi = lit
            body.append(("clamp", i, f"lo{i}", f"hi{i}"))
            consts[f"lo{i}"] = lo
            consts[f"hi{i}"] = hi
        elif kind == "proj":
            _, i, eps = lit
            body.append(("proj", i, "EPS"))
            consts["EPS"] = eps
        elif kind == "ident":
            body.append(("identity",))
    if not body:
        body.append(("identity",))
    return Clause("solve(N,R)", body, consts)

def covers(clause, example, bk):
    neural, spec, verified = example
    return all(any(b[0] == s[0] for s in spec) or b[0] == "identity" for b in clause.body)

def reduce(bottom, examples):
    kept = []
    for lit in bottom.body:
        trial = Clause(bottom.head, [l for l in bottom.body if l != lit], bottom.consts)
        if not all(covers(trial, e, None) for e in examples):
            kept.append(lit)
    return {Clause(bottom.head, kept or [("identity",)], bottom.consts)}

def minimize(hypothesis):
    return hypothesis

def induce(examples, bk):
    hypothesis = set()
    for neural, spec, verified in examples:
        bottom = saturate(neural, spec, verified, bk)
        hypothesis |= reduce(bottom, examples)
    return minimize(hypothesis)

def uncovered(hypothesis, examples):
    return [e for e in examples if not any(covers(c, e, None) for c in hypothesis)]

def force(hypothesis, examples, bk):
    for _e in uncovered(hypothesis, examples):
        hypothesis.add(Clause("solve(N,R)", [("identity",)], {}))
    return hypothesis

def emit_c(hypothesis, dims=64):
    lo = [0.0] * dims
    hi = [0.0] * dims
    eps = 0.0
    for clause in hypothesis:
        for lit in clause.body:
            if lit[0] == "clamp":
                i = lit[1]
                lo[i] = clause.consts.get(lit[2], lo[i])
                hi[i] = clause.consts.get(lit[3], hi[i])
            elif lit[0] == "proj":
                eps = clause.consts.get("EPS", eps)
    return lo, hi, eps
