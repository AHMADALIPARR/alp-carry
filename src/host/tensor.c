/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

#include "tensor.h"
#include <stdlib.h>
#include <string.h>
#include <immintrin.h>

Tensor tensor_new(size_t r, size_t c) {
    size_t stride_bytes = (c * sizeof(float) + 63) & ~(size_t)63;
    size_t stride = stride_bytes / sizeof(float);
    float *d = NULL;
    if (posix_memalign((void **)&d, 64, stride_bytes * r)) abort();
    memset(d, 0, stride_bytes * r);
    return (Tensor){ d, r, c, stride };
}

void tensor_free(Tensor *t) { free(t->data); t->data = NULL; }

void tensor_randomize(Tensor *t, float lo, float hi) {
    for (size_t i = 0; i < t->rows; i++)
        for (size_t j = 0; j < t->cols; j++) {
            float u = (float)rand() / (float)RAND_MAX;
            t->data[i * t->stride + j] = lo + u * (hi - lo);
        }
}

void linear_avx2(const Tensor *x, const Tensor *w, const Tensor *b, Tensor *out) {
    for (size_t i = 0; i < x->rows; i++) {
        const float *xi = x->data + i * x->stride;
        float *oi = out->data + i * out->stride;
        memcpy(oi, b->data, b->cols * sizeof(float));
        for (size_t k = 0; k < x->cols; k++) {
            __m256 xv = _mm256_set1_ps(xi[k]);
            size_t j = 0;
            for (; j + 8 <= w->cols; j += 8) {
                __m256 wv = _mm256_loadu_ps(w->data + k * w->stride + j);
                __m256 ov = _mm256_loadu_ps(oi + j);
                _mm256_storeu_ps(oi + j, _mm256_add_ps(ov, _mm256_mul_ps(xv, wv)));
            }
            for (; j < w->cols; j++)
                oi[j] += xi[k] * w->data[k * w->stride + j];
        }
    }
}
