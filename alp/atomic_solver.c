/* atomic_solver.c — generated shape. Constants are baked by alp_engine.emit_c.
   One entry, no calls, no data branches. */
#include <immintrin.h>
#include <stddef.h>

#define MAXD 64

static const float LO[MAXD] = {0};
static const float HI[MAXD] = {0};
static const float EPS = 0.f;

void atomic_solver(const float *restrict neural,
                   float *restrict refined,
                   size_t dims)
{
    for (size_t i = 0; i + 8 <= dims; i += 8) {
        __m256 v  = _mm256_loadu_ps(neural + i);
        __m256 lo = _mm256_loadu_ps(LO + i);
        __m256 hi = _mm256_loadu_ps(HI + i);
        __m256 c1 = _mm256_max_ps(_mm256_min_ps(v, hi), lo);
        __m256 e  = _mm256_set1_ps(EPS);
        __m256 c2 = _mm256_max_ps(_mm256_min_ps(v, _mm256_add_ps(v, e)),
                                  _mm256_sub_ps(v, e));
        __m256 out = _mm256_max_ps(c1, c2);
        __m256 hit = _mm256_or_ps(
            _mm256_cmp_ps(c1, v, _CMP_NEQ_OQ),
            _mm256_cmp_ps(c2, v, _CMP_NEQ_OQ));
        out = _mm256_blendv_ps(v, out, hit);
        _mm256_storeu_ps(refined + i, out);
    }
    for (size_t i = dims & ~(size_t)7; i < dims; i++) {
        float v = neural[i];
        float c1 = v < LO[i] ? LO[i] : (v > HI[i] ? HI[i] : v);
        float c2 = v < v - EPS ? v - EPS : (v > v + EPS ? v + EPS : v);
        refined[i] = c1 > c2 ? c1 : c2;
    }
}
