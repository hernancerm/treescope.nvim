;; extends

; Case: (defn name ...)
; Case: (deftest name ...)
; Case: (defmacro name ...)
(list_lit
  (sym_lit (sym_name) @_defn)
  (sym_lit (sym_name) @treescope_outermost_function)
  (#any-of? @_defn "defn" "deftest" "defmacro"))

; Case: (def name (fn ...))
(list_lit
  (sym_lit (sym_name) @_def)
  (sym_lit (sym_name) @treescope_outermost_function)
  (list_lit (sym_lit (sym_name) @_fn))
  (#eq? @_def "def")
  (#eq? @_fn "fn"))
