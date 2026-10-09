% bk.pl — constraint lattice used as ALP background knowledge
holds(le(X, Y)) :- X =< Y.
holds(proj(I, V, N, EPS)) :- abs(V - N) =< EPS.
holds(clamp(I, V, LO, HI)) :- V >= LO, V =< HI.
holds(ident(N, R)) :- R = N.
