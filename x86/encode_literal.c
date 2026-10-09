/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

/* encode_literal.c — proof word bit j = 1 iff literal holds on dim j.
   Full literal <=> word == ~0ull. Encoder is the C1 gate. */
#include <immintrin.h>
#include <stdint.h>
#include <string.h>

void encode_clamp_mask(const float *n, const float *lo, const float *hi,
                       uint64_t *out)
{
    uint64_t m = 0;
    for (int j = 0; j < 64; j += 8) {
        __m256 v  = _mm256_loadu_ps(n + j);
        __m256 L  = _mm256_loadu_ps(lo + j);
        __m256 H  = _mm256_loadu_ps(hi + j);
        __m256 ok = _mm256_and_ps(_mm256_cmp_ps(v, L, _CMP_GE_OQ),
                                  _mm256_cmp_ps(v, H, _CMP_LE_OQ));
        uint32_t bits = (uint32_t)_mm256_movemask_ps(ok);
        m |= (uint64_t)bits << j;
    }
    *out = m;
}

void encode_proj_mask(const float *n, const float *r, float eps, uint64_t *out)
{
    uint64_t m = 0;
    __m256 e = _mm256_set1_ps(eps);
    for (int j = 0; j < 64; j += 8) {
        __m256 nv = _mm256_loadu_ps(n + j);
        __m256 rv = _mm256_loadu_ps(r + j);
        __m256 d  = _mm256_sub_ps(rv, nv);
        __m256 ad = _mm256_andnot_ps(_mm256_set1_ps(-0.f), d);
        __m256 ok = _mm256_cmp_ps(ad, e, _CMP_LE_OQ);
        uint32_t bits = (uint32_t)_mm256_movemask_ps(ok);
        m |= (uint64_t)bits << j;
    }
    *out = m;
}

/* C1: a body word is admissible only as empty or full. Partial masks are
   rejected here so the carry theorem's exact-residue case is the only case
   that reaches the kernel. */
int literal_full(uint64_t w) { return w == ~0ull; }
int literal_empty(uint64_t w) { return w == 0ull; }
