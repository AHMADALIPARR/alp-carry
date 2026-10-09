/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 */

/* One public symbol. Resolved once, then an indirect call. */
#include <stdatomic.h>
#include "cpu_dispatch.h"

typedef void (*carry_fn)(const uint64_t *words, uint64_t *out, int n);

extern void alp_carry_prove_adx(const uint64_t *, uint64_t *, int);
extern void alp_carry_prove_portable(const uint64_t *, uint64_t *, int);

int cpu_has_adx(void) {
#if defined(__GNUC__) || defined(__clang__)
    __builtin_cpu_init();
    return __builtin_cpu_supports("adx");
#else
    uint32_t a, b, c, d;
    __asm__ __volatile__("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d) : "a"(0), "c"(0));
    if (a < 7) return 0;
    __asm__ __volatile__("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d) : "a"(7), "c"(0));
    return (b >> 19) & 1;
#endif
}

static carry_fn resolve(void) {
    return cpu_has_adx() ? alp_carry_prove_adx : alp_carry_prove_portable;
}

static _Atomic(carry_fn) g_kernel;

void alp_carry_prove(const uint64_t *words, uint64_t *out, int n) {
    carry_fn fn = atomic_load_explicit(&g_kernel, memory_order_acquire);
    if (__builtin_expect(fn == 0, 0)) {
        fn = resolve();
        atomic_store_explicit(&g_kernel, fn, memory_order_release);
    }
    fn(words, out, n);
}
