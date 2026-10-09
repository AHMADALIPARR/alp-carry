; alp_carry_prove_x86 — dual-rail carry proof
; System V: rdi = proof words, rsi = out, edx = literal count
; CF rail (ADCX) = clause-body conjunction
; OF rail (ADOX) = clause-head disjunction
; Broadwell+ ADCX/ADOX. Chains do not serialize each other.

        bits 64
        default rel
        section .text
        global alp_carry_prove_x86

alp_carry_prove_x86:
        xor     r8, r8                  ; conjunction residue
        xor     r9, r9                  ; head accumulator
        xor     eax, eax
        add     eax, eax                ; CF = 0, OF = 0
        mov     ecx, edx
        mov     r11, 0x8000000000000000 ; clause head bit
        mov     r12, -1                 ; identity word, forced totality
        test    ecx, ecx
        jz      .store
.chain_loop:
        adcx    r8, [rdi]               ; CF rail: r8 += W(L_i) + CF
        adox    r9, r11                 ; OF rail: r9 += head + OF
        lea     rdi, [rdi + 8]
        dec     ecx
        jnz     .chain_loop
.store:
        setc    al                      ; verdict = final CF
        movzx   eax, al
        test    r9, r9
        cmovz   r9, r12                 ; no head fired -> identity
        mov     [rsi], r9
        mov     [rsi + 8], r8
        ret
