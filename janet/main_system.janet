# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

# main_system.janet
# Load the stack and run one DSPy pipeline.

(load "neural_macros")
(load "attention_head")
(load "dspy_loop")
(load "constraint_bridge")
(load "neural_operations")

(defmacro def-neural-network
  [name layers]
  ~(do
     (def ,name
       (fn [input]
         (var current input)
         (each layer ,layers
           (set current (layer current)))
         current))
     (each layer ,layers
       (initialize-parameters layer))
     ,name))

(def-neural-network simple-network
  [(dense-layer 784 128)
   (relu)
   (dense-layer 128 64)
   (attention-head-1)
   (softmax)])

(defn run-pipeline
  [pipeline test-data]
  (def bridge (neural-symbolic-bridge (pipeline :neural) (pipeline :symbolic)))
  (map bridge test-data))
