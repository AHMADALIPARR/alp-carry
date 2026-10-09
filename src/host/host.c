/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

#define _POSIX_C_SOURCE 199309L
/* nnhost — C11 host. Forward, encode, carry-prove, converge. */
#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <time.h>
#include "tensor.h"
#include "generated_constraints.h"

#define ITER_MAX 200
#define LOSS_THRESHOLD 1e-4f

typedef struct {
    _Atomic uint32_t iteration;
    _Atomic float    loss;
    Tensor           activations;
    Tensor           refined;
    uint64_t         verdict[2];
} LifeNode;

extern int alp_verify_encoder(const char *path);

static double now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1e9 + ts.tv_nsec;
}

int main(void) {
    srand(0xC0FFEE);
    if (alp_verify_encoder("src/atomizer/test_vectors.json") != 0) {
        fprintf(stderr, "ENCODER VERIFICATION FAILED — refusing to run\n");
        return 1;
    }
    Tensor x = tensor_new(8, 64);
    Tensor w = tensor_new(64, 64);
    Tensor b = tensor_new(1, 64);
    tensor_randomize(&x, -2, 2);
    tensor_randomize(&w, -0.05f, 0.05f);
    tensor_randomize(&b, -0.1f, 0.1f);
    LifeNode node;
    node.activations = tensor_new(8, 64);
    node.refined = tensor_new(8, 64);
    atomic_store(&node.iteration, 0);
    double t0 = now_ns();
    for (;;) {
        linear_avx2(&x, &w, &b, &node.activations);
        for (size_t row = 0; row < 8; row++) {
            float *n = node.activations.data + row * node.activations.stride;
            float *r = node.refined.data + row * node.refined.stride;
            atomic_solver_ref(n, r, 64);
            uint64_t words[4];
            int k = alp_encode_proofs(n, r, words);
            alp_carry_prove(words, node.verdict, k);
        }
        float loss = 0;
        for (size_t row = 0; row < 8; row++)
            for (size_t j = 0; j < 64; j++) {
                float d = node.activations.data[row * node.activations.stride + j]
                        - node.refined.data[row * node.refined.stride + j];
                loss += d * d;
            }
        atomic_store(&node.loss, loss);
        uint32_t it = atomic_fetch_add(&node.iteration, 1) + 1;
        if (loss < LOSS_THRESHOLD || it >= ITER_MAX) {
            printf("[dspy] converged: iter=%u loss=%g verdict=%016llx\n",
                   it, (double)loss, (unsigned long long)node.verdict[0]);
            break;
        }
    }
    double t1 = now_ns();
    printf("[host] %u iterations in %.1f us (%.1f ns/iter)\n",
           atomic_load(&node.iteration), (t1 - t0) / 1e3,
           (t1 - t0) / atomic_load(&node.iteration));
    tensor_free(&x); tensor_free(&w); tensor_free(&b);
    tensor_free(&node.activations); tensor_free(&node.refined);
    return 0;
}
