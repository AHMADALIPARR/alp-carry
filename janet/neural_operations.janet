# neural_operations.janet
# Owl-backed ops and activation macros.

(defn matmul
  [a b]
  (owl-exec "matmul" [a b]))

(defn transpose
  [matrix]
  (owl-exec "transpose" [matrix]))

(defn softmax
  [vector]
  (owl-exec "softmax" [vector]))

(defn linear
  [x w b]
  (owl-exec "linear" [x w b]))

(defmacro def-activation
  [name type]
  ~(def ,name
     (fn [x]
       (case ,type
         "relu" (owl-exec "relu" [x])
         "sigmoid" (owl-exec "sigmoid" [x])
         "tanh" (owl-exec "tanh" [x])
         (error "Unknown activation")))))

(def-activation relu "relu")
(def-activation sigmoid "sigmoid")
(def-activation tanh "tanh")

(defn compute-gradients
  [loss-fn params]
  (let [grad-fn (owl-gradient loss-fn params)]
    (grad-fn)))

(defn loss-fn
  [predictions targets]
  (mean (square (subtract predictions targets))))
