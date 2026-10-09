/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

/* 2.6 verification obligation. Discrepancy is an encoder or kernel bug. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tensor.h"
#include "generated_constraints.h"

static int load_vectors(const char *path, float (*neural)[ALP_MAXD],
                        int *expect_full, int max) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    size_t cap = 1 << 24;
    char *buf = malloc(cap);
    if (!buf) { fclose(f); return -1; }
    size_t n = fread(buf, 1, cap - 1, f);
    buf[n] = 0;
    fclose(f);
    int count = 0;
    char *p = buf;
    while (count < max && (p = strstr(p, "\"neural\""))) {
        p = strchr(p, '[');
        if (!p) break;
        p++;
        for (int j = 0; j < ALP_MAXD; j++) {
            neural[count][j] = strtof(p, &p);
            while (*p == ',' || *p == ' ' || *p == '\n') p++;
        }
        p = strstr(p, "\"expect_clamp_full\"");
        if (!p) break;
        p = strchr(p, ':');
        if (!p) break;
        p++;
        while (*p == ' ') p++;
        expect_full[count] = (*p == 't' || *p == '1');
        count++;
    }
    free(buf);
    return count;
}

int alp_verify_encoder(const char *vector_path) {
    static float neural[4096][ALP_MAXD];
    static int expect[4096];
    int n = load_vectors(vector_path, neural, expect, 4096);
    if (n <= 0) {
        fprintf(stderr, "[verifier] no vectors at %s\n", vector_path);
        return -1;
    }
    int failures = 0;
    const uint64_t head = 0x8000000000000000ull;
    const uint64_t ident = 0xFFFFFFFFFFFFFFFFull;
    for (int t = 0; t < n; t++) {
        uint64_t words[4], out[2];
        int k = alp_encode_proofs(neural[t], neural[t], words);
        alp_carry_prove(words, out, k);
        int entailed = out[0] == head;
        int ref = expect[t];
        /* project(n, n) is full for eps >= 0, so body entailment == clamp full */
        if (ref) {
            if (!entailed) failures++;
        } else if (out[0] != ident) {
            failures++;
        }
    }
    printf("[verifier] %d/%d vectors pass\n", n - failures, n);
    return failures;
}
