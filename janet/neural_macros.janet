# alp-carry — carry-chain proof kernel
# Copyright (C) 2026 Ahmad Ali Parr
# SPDX-License-Identifier: AGPL-3.0-only

# neural_macros.janet
# Neuron, attention head, and layer macros. Bodies call the Owl bridge.

(defmacro defneuron
  [name input-dim output-dim]
  ~(def ,name
     (fn [input]
       (let [weights (random-weights ,input-dim ,output-dim)
             bias (random-biases ,output-dim)
             output (linear input weights bias)]
         output))))

(defmacro defattention
  [name dim]
  ~(def ,name
     (fn [query key value]
       (let [scores (dot-product query key)
             weights (softmax scores)
             output (weighted-sum weights value)]
         output))))

(defmacro deflayer
  [name type input-dim output-dim]
  (case type
    "dense" ~(def ,name (fn [x] (dense-layer x ,input-dim ,output-dim)))
    "attention" ~(def ,name (fn [q k v] (attention-layer q k v ,output-dim)))
    "conv" ~(def ,name (fn [x] (conv-layer x ,input-dim ,output-dim)))
    "pool" ~(def ,name (fn [x] (pool-layer x ,input-dim ,output-dim)))
    (error "Unknown layer type")))
