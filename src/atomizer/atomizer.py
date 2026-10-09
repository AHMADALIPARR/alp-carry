# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

#!/usr/bin/env python3
"""Atomizer: induced program -> constants, mask encoder, verification vectors.
C1 dimension-complete words. C2 body length <= 63. C3 monotone literals. C4 minimized body.
"""
import json, os, random, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from templates import CONSTRAINTS_H, BODY_BOTH, BODY_CLAMP_ONLY

DIMS = 64

def f32(x):
    return struct.unpack("f", struct.pack("f", float(x)))[0]

def fmt_floats(xs):
    return ", ".join(f"{f32(x):.9g}f" for x in xs)

def emit_constraints(prog):
    body = BODY_BOTH if len(prog["body"]) > 1 else BODY_CLAMP_ONLY
    src = CONSTRAINTS_H.format(
        LO_INIT=fmt_floats(prog["lo"]),
        HI_INIT=fmt_floats(prog["hi"]),
        EPS=f"{prog['eps']:.6f}f",
        N_LITERALS=len(prog["body"]),
        BODY=body,
    )
    with open("src/atomizer/generated_constraints.h", "w") as f:
        f.write(src)
    print("wrote generated_constraints.h")

MASK_ENCODER = r"""/* GENERATED: proof-mask encoder. Full word <=> literal holds on every dim.
 * C1: bit j defined for j in 0..63. C3: threshold literals, monotone. */
#include <stdint.h>
#include <immintrin.h>
#include "generated_constraints.h"

static inline uint64_t pack8(uint32_t bits, int j) {
    return (uint64_t)(bits & 0xffu) << j;
}

static inline uint64_t mask_clamp(const float *restrict n) {
    uint64_t m = 0;
    for (int j = 0; j < ALP_MAXD; j += 8) {
        __m256 v  = _mm256_loadu_ps(n + j);
        __m256 L  = _mm256_loadu_ps(ALP_LO + j);
        __m256 H  = _mm256_loadu_ps(ALP_HI + j);
        __m256 ok = _mm256_and_ps(_mm256_cmp_ps(v, L, _CMP_GE_OQ),
                                  _mm256_cmp_ps(v, H, _CMP_LE_OQ));
        m |= pack8((uint32_t)_mm256_movemask_ps(ok), j);
    }
    return m;
}

#if ALP_HAS_PROJECTION
static inline uint64_t mask_project(const float *restrict n,
                                    const float *restrict r) {
    uint64_t m = 0;
    __m256 e = _mm256_set1_ps(ALP_EPS);
    for (int j = 0; j < ALP_MAXD; j += 8) {
        __m256 nv = _mm256_loadu_ps(n + j);
        __m256 rv = _mm256_loadu_ps(r + j);
        __m256 d  = _mm256_andnot_ps(_mm256_set1_ps(-0.0f), _mm256_sub_ps(nv, rv));
        __m256 ok = _mm256_cmp_ps(d, e, _CMP_LE_OQ);
        m |= pack8((uint32_t)_mm256_movemask_ps(ok), j);
    }
    return m;
}
#endif

int alp_encode_proofs(const float *restrict n,
                      const float *restrict r,
                      uint64_t *restrict words) {
    words[0] = mask_clamp(n);
    int k = 1;
#if ALP_HAS_PROJECTION
    words[1] = mask_project(n, r);
    k = 2;
#endif
    return k;
}
"""

def emit_encoder():
    with open("src/kernels/proof_masks.c", "w") as f:
        f.write(MASK_ENCODER)
    print("wrote proof_masks.c")

def emit_test_vectors(prog):
    lo = [f32(x) for x in prog["lo"]]
    hi = [f32(x) for x in prog["hi"]]
    random.seed(0xABCDEF)
    vecs = []
    for t in range(4096):
        kind = t % 3
        if kind == 0:
            n = [random.uniform(lo[j], hi[j]) for j in range(DIMS)]
        elif kind == 1:
            n = [random.choice([lo[j], hi[j]]) for j in range(DIMS)]
        else:
            n = [lo[j] - random.uniform(1e-4, 0.5) if random.random() < 0.5
                 else hi[j] + random.uniform(1e-4, 0.5) for j in range(DIMS)]
        n = [f32(x) for x in n]
        clamp_full = all(lo[j] <= n[j] <= hi[j] for j in range(DIMS))
        vecs.append({"neural": n, "expect_clamp_full": 1 if clamp_full else 0})
    with open("src/atomizer/test_vectors.json", "w") as f:
        json.dump(vecs, f)
    print(f"wrote {len(vecs)} verification vectors")

def main():
    with open("src/alp/induced.json") as f:
        prog = json.load(f)
    emit_constraints(prog)
    emit_encoder()
    emit_test_vectors(prog)

if __name__ == "__main__":
    main()
