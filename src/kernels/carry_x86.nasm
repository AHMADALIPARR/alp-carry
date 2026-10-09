; alp_carry_prove_adx
; rdi words, rsi out, edx n
; Deficiency count: cmp word, -1 sets CF when the word is not full,
; ADCX adds that CF into r8. Residue 0 iff every literal is full.
; ADOX is a second pass so it cannot merge into the CF chain.

        bits 64
        default rel
        section .text
        global alp_carry_prove_adx

alp_carry_prove_adx:
        mov     r11, 0x8000000000000000
        xor     r8, r8
        xor     r9, r9
        xor     r10, r10
        mov     ecx, edx
        test    ecx, ecx
        jz      .default_only
        push    rbx
        push    r12
        mov     ebx, edx
        mov     r12, rdi
.cf_loop:
        cmp     qword [rdi], -1
        adcx    r8, r10
        lea     rdi, [rdi + 8]
        dec     ecx
        jnz     .cf_loop
        mov     rdi, r12
        mov     ecx, ebx
        xor     eax, eax
.of_loop:
        adox    r9, r11
        dec     ecx
        jnz     .of_loop
        xor     rax, rax
        test    r8, r8
        cmovz   rax, r11
        pop     r12
        pop     rbx
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
