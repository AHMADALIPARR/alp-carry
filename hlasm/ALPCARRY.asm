* ALPCARRY - ALP proof evaluation via carry propagation
* z/Architecture, 64-bit. Entailment = carry out 1. Refutation = carry out 0.
* R2 proof words (clause-major)  R3 refined out  R4 literal count
         CSECT
         YREGS
ALPCARRY AMODE 64
ALPCARRY RMODE ANY
         LGFI  R5,0
         LGFI  R6,0
         LGR   R7,R4
         ALGR  R0,R0
CHAINLP  LG    R1,0(,R2)
         ALCGR R6,R1
         LA    R2,8(,R2)
         BRCT  R7,CHAINLP
         LGFI  R8,HEADMSK
         ALCGR R5,R0
         LGR   R9,R5
         SLFI  R9,1
         LA    R10,IDWORD
         LOCR  R3,R10,8
         STG   R5,0(,R3)
         STG   R6,8(,R3)
         BR    R14
HEADMSK  DC    XL4'80000000'
IDWORD   DC    XL8'FFFFFFFFFFFFFFFF'
         END
