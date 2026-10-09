/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

/* Portable atomized solver — golden model for the verification obligation. */
#include "generated_constraints.h"

void atomic_solver_ref(const float *restrict neural,
                       float *restrict refined,
                       size_t dims)
{
    for (size_t i = 0; i < dims; i++) {
        float v = neural[i];
        float c = v < ALP_LO[i] ? ALP_LO[i] : (v > ALP_HI[i] ? ALP_HI[i] : v);
        float loe = v - ALP_EPS;
        float hie = v + ALP_EPS;
        float p = c < loe ? loe : c;
        if (p > hie) p = hie;
        refined[i] = p;
    }
}
