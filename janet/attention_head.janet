# attention_head.janet
# Synthetic attention head. Weights are lifted above the closure.

(defmacro def-synthetic-attention
  [name input-dim output-dim num-heads]
  ~(do
     (var W_q (random-weights ,input-dim ,output-dim))
     (var W_k (random-weights ,input-dim ,output-dim))
     (var W_v (random-weights ,input-dim ,output-dim))
     (var W_o (random-weights ,output-dim ,input-dim))
     (def ,name
       (fn [input]
         (let [query (linear input W_q)
               key (linear input W_k)
               value (linear input W_v)
               scores (matmul query (transpose key))
               scale (math/sqrt ,num-heads)
               attention-weights (softmax (map |(/ $ scale) scores))
               context (matmul attention-weights value)
               output (linear context W_o)]
           output)))
     ,name))

(def-synthetic-attention attention-head-1 512 512 8)
