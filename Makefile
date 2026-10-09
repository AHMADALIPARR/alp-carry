CC      ?= cc
CFLAGS  ?= -std=c11 -O3 -mavx2
OCAML   ?= ocamlfind ocamlopt

.PHONY: host owl

host: host/host.c alp/atomic_solver.c
	$(CC) $(CFLAGS) -c host/host.c -o host.o
	$(CC) $(CFLAGS) -c alp/atomic_solver.c -o atomic_solver.o

owl: owl/owl_constraints.ml
	$(OCAML) -output-obj -o owl_constraints.o -package owl owl/owl_constraints.ml
	ar rcs libowl_constraints.a owl_constraints.o
