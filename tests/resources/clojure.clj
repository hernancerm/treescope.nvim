; cursor-9a3b5c7d
(defn greet [name]
  ; cursor-1x2y3z4w
  (str "Hello, " name "!"))

; cursor-7a1nko2i[6w]
(def salute (fn [name]
  ; cursor-5m6n7o8p
  (str "Hello, " name "!")))

(defn process-data [data]
  (filter (fn [n]
    ; cursor-2k3l4m5n
    (> n 0))
    data)
  (defn nested-fn []
    ; cursor-8d9e0f1g
    (do-something)))

(defn fetch-data [url]
  (defn middle []
    (defn inner []
      ; cursor-6g7h8i9j
      (str "Fetching " url))
    (inner))
  (middle))
