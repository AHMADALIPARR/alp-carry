#ifndef CPU_DISPATCH_H
#define CPU_DISPATCH_H
/* alp-carry — carry-chain proof kernel
 * Copyright (C) 2026 Ahmad Ali Parr
 * SPDX-License-Identifier: AGPL-3.0-only
 *
 * One-time CPU feature detection, zero deps.
 * __builtin_cpu_supports: GCC/Clang instant path.
 * Fallback: raw CPUID leaf 7 (ebx bit 19 = ADX). */
#include <stdint.h>

int cpu_has_adx(void);
#endif
