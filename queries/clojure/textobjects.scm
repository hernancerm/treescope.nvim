;; extends

; Case: (defn name ...)
; Case: (deftest name ...)
; Case: (defmacro name ...)
(source
  (list_lit
    (sym_lit (sym_name) @_defn)
    (sym_lit (sym_name) @treescope_function)
    (#any-of? @_defn "defn" "deftest" "defmacro")
  ) @treescope_function.scope)

; Case: (def name (fn ...))
(source
  (list_lit
    (sym_lit (sym_name) @_def)
    (sym_lit (sym_name) @treescope_function)
    (list_lit (sym_lit (sym_name) @_fn))
    (#eq? @_def "def")
    (#eq? @_fn "fn")
  ) @treescope_function.scope)
