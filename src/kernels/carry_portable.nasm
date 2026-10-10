; alp-carry — carry-chain proof kernel
; Copyright (C) 2026 Ahmad Ali Parr
; SPDX-License-Identifier: AGPL-3.0-only
;
; alp_carry_prove_portable — single-rail ADC fallback.
; No ADX. Same verdict as alp_carry_prove_adx:
;   residue 0 iff every word is full, then head, else identity.
; A summing ADC chain is not used: a zero word followed by a full
; mask rebuilds CF, and n=1 all-full never raises CF.

        bits 64
        default rel
        section .text
        global alp_carry_prove_portable

alp_carry_prove_portable:
        mov     r11, 0x8000000000000000
        xor     r8, r8
        xor     r10, r10
        mov     ecx, edx
        test    ecx, ecx
        jz      .default_only
.chain_loop:
        cmp     qword [rdi], -1         ; CF = 1 iff word is short
        adc     r8, r10                 ; deficiency count, cannot repair
        lea     rdi, [rdi + 8]
        dec     ecx
        jnz     .chain_loop
        xor     rax, rax
        test    r8, r8
        cmovz   rax, r11                ; entailed ? head : 0
        jmp     .finalize
.default_only:
        xor     rax, rax
.finalize:
        test    rax, rax
        cmovz   rax, [rel identity_word]
        mov     [rsi], rax
        mov     [rsi + 8], r8
        ret

        section .rodata
identity_word:
        dq 0xFFFFFFFFFFFFFFFF
