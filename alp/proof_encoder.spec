Proof-Encoder Formal Specification
alp-carry / dual-rail carry entailment

1. Encoding

Definition (Proof Word). For literal L over D = {0..63},

  W(L) = sum_{j in D} 2^j * [[L(j)]]

where [[L(j)]] in {0,1} is L's truth value at dimension j.

Definition (Full Literal). L is full iff W(L) = 2^64 - 1.

Definition (Empty Literal). L is empty iff W(L) = 0.

The encoder (x86/encode_literal.c) is the only producer of proof words.
Partial masks are not admissible inputs to the kernel (condition C1).

2. Soundness

Chain. C_0 = 0, S_0 = 0, and for i = 1..n:

  S_i = (S_{i-1} + W(L_i) + C_{i-1}) mod 2^64
  C_i = carry out of that addition

Theorem. Let H :- L_1, ..., L_n be encoded with full-or-empty weights,
n <= 63. Then

  C_n = 1 and S_n = (2^64 - n) mod 2^64
  iff every L_i is full
  iff the clause body is entailed.

Proof, left to right. If every W(L_i) = 2^64 - 1, then each step adds
all-ones plus the incoming carry. Direct invariant, i >= 1:

  C_i = 1
  S_i = (2^64 - i) mod 2^64

Base i = 1: 0 + (2^64 - 1) + 0 = 2^64 - 1, carry 0 is wrong for this
base — all-ones plus zero does not carry. The ratchet starts at the
second full addend:

  S_1 = 2^64 - 1, C_1 = 0
  S_2 = (2^64 - 1) + (2^64 - 1) + 0 = 2^64 + (2^64 - 2), so
        S_2 = 2^64 - 2, C_2 = 1
  S_{i} = (2^64 - (i-1)) + (2^64 - 1) + 1 = 2^64 + (2^64 - i), so
        S_i = 2^64 - i, C_i = 1  for i >= 2

For n = 1 the verdict is not the carry (C_1 = 0 on a full word). The
kernel's single-literal case is the residue test S_1 = 2^64 - 1, which
is the full-mask test. For n >= 2 the carry ratchets and stays set.
Entailment is therefore

  (n = 1 and S_1 = 2^64 - 1) or (n >= 2 and C_n = 1 and S_n = 2^64 - n)

not C_n alone.

Proof, right to left. Suppose some W(L_k) = w < 2^64 - 1, deficiency
delta = (2^64 - 1) - w >= 1. Addition of a word is monotone in w. The
full-mask sequence is the unique maximal chain. A deficiency of delta
is not repaired by a later full word: a later full word adds exactly
2^64 - 1 plus the incoming carry, which preserves the deficiency in the
residue class. Terminal state is strictly below the full-mask terminal
state, so the entailment predicate above fails. Contrapositive: the
predicate holds only if every literal is full.

Corollary (drain). One zero bit in any body word puts S_n in a deficient
residue class. One failed conjunct refutes the body.

3. Disjunction rail

CF computes the inner conjunction of one clause body.
OF accumulates clause heads. The two flags are independent, so the
rails overlap in one instruction stream.

  Verdict = OR_k [ AND_{i in body(k)} L_i ]

Head fusion gates on the CF verdict of that body: the head bit is
admitted to the OF rail only when that body's entailment predicate
holds. A head accumulator of zero means no clause fired.

4. Totality

If the head accumulator is zero, the identity word 2^64 - 1 is selected
(CMOVZ / borrow-select). This is the forced clause

  solve(N, N) :- true.

Identity is the top of the refinement lattice used by the atomizer:
the fallback copies the neural word and does not invent a tighter one.

5. Encoder obligations

C1  Every literal word is empty or full. Partial masks are rejected
    before the kernel. Bit j is defined for every j in 0..63.
C2  A body has at most 63 literals. At n = 64 the residue wraps onto
    the n = 0 class. Longer bodies split; the subchain terminal
    predicate is re-encoded as one full or empty bridge word.
C3  Literal truth is monotone in the neural output (threshold, clamp,
    epsilon ball). A non-monotone literal is re-encoded as a pair of
    comparisons before masking.
C4  ALP minimization drops redundant literals. Redundancy does not
    break the predicate; it spends carry depth.

C2 split is sound by applying the theorem to the subchain and emitting
its predicate as a single bridge literal.

6. Re-synthesis check

The kernel is fixed. The encoder is regenerated. On each hot-swap, for
sampled neural inputs and boundary inputs:

  entailment_predicate(alp_carry_prove(W(L_1)..W(L_n)))
    = [[ AND_i L_i ]]

A mismatch is an encoder bug. The check runs offline, before the
object is swapped in.
