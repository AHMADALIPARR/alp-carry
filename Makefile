CC      = cc
AS      = nasm
PY      = python3
CFLAGS  = -std=c11 -O3 -mavx2 -Wall -Wextra -pedantic \
          -Isrc/host -Isrc/atomizer -Isrc/kernels
ASFLAGS = -f elf64
HAVE_NASM := $(shell command -v nasm 2>/dev/null)

OBJS = build/tensor.o build/dispatch.o build/atomized.o \
       build/verifier.o build/proof_masks.o \
       build/carry_adx.o build/carry_portable.o

.PHONY: all synthesize test clean zkernel

all: build/nnhost

build:
	mkdir -p build

build/tensor.o: src/host/tensor.c src/host/tensor.h | build
	$(CC) $(CFLAGS) -c $< -o $@

build/dispatch.o: src/host/dispatch.c src/host/cpu_dispatch.h | build
	$(CC) $(CFLAGS) -c $< -o $@

build/atomized.o: src/kernels/atomized.c src/atomizer/generated_constraints.h | build
	$(CC) $(CFLAGS) -c $< -o $@

build/proof_masks.o: src/kernels/proof_masks.c src/atomizer/generated_constraints.h | build
	$(CC) $(CFLAGS) -c $< -o $@

build/verifier.o: src/host/verifier.c src/host/tensor.h src/atomizer/generated_constraints.h | build
	$(CC) $(CFLAGS) -c $< -o $@

ifneq ($(HAVE_NASM),)
build/carry_adx.o: src/kernels/carry_x86.nasm | build
	$(AS) $(ASFLAGS) $< -o $@
build/carry_portable.o: src/kernels/carry_portable.nasm | build
	$(AS) $(ASFLAGS) $< -o $@
else
build/carry_adx.o: src/kernels/carry_x86.S | build
	$(CC) -c $< -o $@
build/carry_portable.o: src/kernels/carry_portable.S | build
	$(CC) -c $< -o $@
endif

build/nnhost: src/host/host.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ -lm
	chmod +x $@

synthesize:
	$(PY) src/alp/examples_gen.py
	$(PY) src/alp/alp_engine.py
	$(PY) src/atomizer/atomizer.py

zkernel:
	@echo "HLASM kernel: assemble src/kernels/carry_z.hlasm on z/OS, link into host"

test: synthesize all
	bash tests/run_tests.sh

clean:
	rm -rf build src/atomizer/generated_constraints.h src/alp/examples.json \
	       src/alp/induced.pl src/alp/induced.json src/atomizer/test_vectors.json \
	       src/kernels/proof_masks.c
