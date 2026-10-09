/* host.c — C11 host. Owl is a static C symbol; tensors are local. */
#include <stdalign.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>
#include <math.h>
#include <immintrin.h>

typedef struct {
    float *data;
    size_t rows, cols;
    size_t stride;
} Tensor;

static Tensor tensor_new(size_t r, size_t c) {
    size_t stride = (c * sizeof(float) + 63) & ~(size_t)63;
    float *d = NULL;
    if (posix_memalign((void **)&d, 64, stride * r)) abort();
    memset(d, 0, stride * r);
    return (Tensor){ d, r, c, stride / sizeof(float) };
}

static void linear_avx2(const Tensor *x, const Tensor *w, const Tensor *b, Tensor *out) {
    for (size_t i = 0; i < x->rows; i++) {
        const float *xi = x->data + i * x->stride;
        float *oi = out->data + i * out->stride;
        memcpy(oi, b->data, b->cols * sizeof(float));
        for (size_t k = 0; k < x->cols; k++) {
            __m256 xv = _mm256_set1_ps(xi[k]);
            size_t j = 0;
            for (; j + 8 <= w->cols; j += 8) {
                __m256 wv = _mm256_loadu_ps(w->data + k * w->stride + j);
                __m256 ov = _mm256_loadu_ps(oi + j);
                _mm256_storeu_ps(oi + j, _mm256_add_ps(ov, _mm256_mul_ps(xv, wv)));
            }
            for (; j < w->cols; j++) oi[j] += xi[k] * w->data[k * w->stride + j];
        }
    }
}

extern int  owl_constraint_solve(const float *neural_out, size_t dims,
                                 const char *constraints, float *solution);
extern void owl_constraint_init(void);
extern void atomic_solver(const float *restrict neural, float *restrict refined, size_t dims);
extern void alp_carry_prove_x86(const uint64_t *proof_words, uint64_t *verdict_out, uint32_t n);

#define MAX_DIMS 64
#define THRESHOLD 1e-4f

typedef struct {
    _Atomic uint32_t iteration;
    _Atomic float    loss;
    Tensor           activations;
    Tensor           refined;
} LifeNode;

static void notify_lifenode(LifeNode *node) { (void)node; }

static int dspy_loop(LifeNode *node, const char *cl1_program) {
    owl_constraint_init();
    for (;;) {
        linear_avx2(&node->activations, &node->activations, &node->refined, &node->activations);
        float solution[MAX_DIMS];
        int ok = owl_constraint_solve(node->activations.data,
                                      node->activations.cols,
                                      cl1_program, solution);
        atomic_solver(node->activations.data, node->refined.data, node->activations.cols);
        if (ok && atomic_load(&node->loss) < THRESHOLD) break;
        notify_lifenode(node);
        atomic_fetch_add(&node->iteration, 1);
    }
    return 0;
}

int main(void) {
    LifeNode node;
    atomic_store(&node.iteration, 0);
    atomic_store(&node.loss, 1.f);
    node.activations = tensor_new(1, MAX_DIMS);
    node.refined = tensor_new(1, MAX_DIMS);
    return dspy_loop(&node, "ident\n");
}
