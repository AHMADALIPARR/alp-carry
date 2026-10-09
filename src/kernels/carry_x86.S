; alp-carry — carry-chain proof kernel
; Copyright (C) 2026 Ahmad Ali Parr
; SPDX-License-Identifier: AGPL-3.0-only

/* GAS twin of carry_x86.nasm. */
        .intel_syntax noprefix
        .text
        .globl alp_carry_prove_adx
        .type alp_carry_prove_adx, @function

alp_carry_prove_adx:
        mov     r11, 0x8000000000000000
        xor     r8, r8
        xor     r9, r9
        xor     r10, r10
        mov     ecx, edx
        test    ecx, ecx
        jz      .Ldefault_only
        push    rbx
        push    r12
        mov     ebx, edx
        mov     r12, rdi
.Lcf_loop:
        cmp     QWORD PTR [rdi], -1
        adcx    r8, r10
        lea     rdi, [rdi + 8]
        dec     ecx
        jnz     .Lcf_loop
        mov     rdi, r12
        mov     ecx, ebx
        xor     eax, eax
.Lof_loop:
        adox    r9, r11
        dec     ecx
        jnz     .Lof_loop
        xor     rax, rax
        test    r8, r8
        cmovz   rax, r11
        pop     r12
        pop     rbx
        jmp     .Lfinalize
.Ldefault_only:
        xor     rax, rax
.Lfinalize:
        test    rax, rax
        cmovz   rax, QWORD PTR [rip + identity_word_adx]
        mov     QWORD PTR [rsi], rax
        mov     QWORD PTR [rsi + 8], r8
        ret

        .section .rodata
identity_word_adx:
        .quad 0xFFFFFFFFFFFFFFFF
