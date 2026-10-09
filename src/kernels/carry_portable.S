; alp-carry — carry-chain proof kernel
; Copyright (C) 2026 Ahmad Ali Parr
; SPDX-License-Identifier: AGPL-3.0-only

/* GAS twin of carry_portable.nasm. */
        .intel_syntax noprefix
        .text
        .globl alp_carry_prove_portable
        .type alp_carry_prove_portable, @function

alp_carry_prove_portable:
        mov     r11, 0x8000000000000000
        xor     r8, r8
        xor     r10, r10
        mov     ecx, edx
        test    ecx, ecx
        jz      .Ldefault_only
.Lchain_loop:
        cmp     QWORD PTR [rdi], -1
        adc     r8, r10
        lea     rdi, [rdi + 8]
        dec     ecx
        jnz     .Lchain_loop
        xor     rax, rax
        test    r8, r8
        cmovz   rax, r11
        jmp     .Lfinalize
.Ldefault_only:
        xor     rax, rax
.Lfinalize:
        test    rax, rax
        cmovz   rax, QWORD PTR [rip + identity_word_portable]
        mov     QWORD PTR [rsi], rax
        mov     QWORD PTR [rsi + 8], r8
        ret

        .section .rodata
identity_word_portable:
        .quad 0xFFFFFFFFFFFFFFFF
