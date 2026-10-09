CC      ?= cc
CFLAGS  ?= -std=c11 -O3 -mavx2
NASM    ?= nasm
OCAML   ?= ocamlfind ocamlopt

.PHONY: host owl x86

host: host/host.c alp/atomic_solver.c
	$(CC) $(CFLAGS) -c host/host.c -o host.o
	$(CC) $(CFLAGS) -c alp/atomic_solver.c -o atomic_solver.o

x86: x86/alp_carry_prove.asm x86/encode_literal.c
	$(NASM) -f elf64 x86/alp_carry_prove.asm -o alp_carry_prove.o
	$(CC) $(CFLAGS) -c x86/encode_literal.c -o encode_literal.o

owl: owl/owl_constraints.ml
	$(OCAML) -output-obj -o owl_constraints.o -package owl owl/owl_constraints.ml
	ar rcs libowl_constraints.a owl_constraints.o
