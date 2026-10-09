# dspy_loop.janet
# Iterative refinement. Each pass emits (neural, spec, verified) for ALP.

(var threshold 1e-4)

(defn dspy-pipeline
  [symbolic-program neural-data]
  (let [modules (parse-symbolic-program symbolic-program)
        optimizer (create-optimizer)]
    (var neural-model (initialize-neural-model modules))
    (var iteration 0)
    (var convergence false)
    (var program symbolic-program)
    (while (not convergence)
      (def predictions (forward-pass neural-model neural-data))
      (def loss (calculate-loss predictions neural-data))
      (if (< loss threshold)
        (set convergence true)
        (do
          (def gradients (backward-pass neural-model loss))
          (update-parameters neural-model gradients optimizer)
          (def refined-program
            (refine-symbolic-program program predictions neural-data))
          (set program refined-program)
          (set neural-model (initialize-neural-model refined-program))
          (set iteration (+ iteration 1)))))
    {:symbolic program
     :neural neural-model
     :iterations iteration}))
