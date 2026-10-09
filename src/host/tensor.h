/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

#ifndef TENSOR_H
#define TENSOR_H
#include <stddef.h>
#include <stdint.h>

typedef struct {
    float  *data;
    size_t  rows, cols;
    size_t  stride;
} Tensor;

Tensor  tensor_new(size_t rows, size_t cols);
void    tensor_free(Tensor *t);
void    tensor_randomize(Tensor *t, float lo, float hi);
void    linear_avx2(const Tensor *x, const Tensor *w, const Tensor *b, Tensor *out);

int     alp_encode_proofs(const float *restrict n, const float *restrict r,
                          uint64_t *restrict words);
void    alp_carry_prove(const uint64_t *words, uint64_t *out, int n);
void    atomic_solver_ref(const float *restrict neural,
                          float *restrict refined, size_t dims);
#endif
