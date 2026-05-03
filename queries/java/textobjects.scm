;;extends

; Case: Methods.
(class_declaration body: (class_body
  (method_declaration
    name: (identifier) @treescope_function
  ) @treescope_function.scope))

; Case: Constructors.
(class_declaration body: (class_body
  (constructor_declaration
    name: (identifier) @treescope_function
  ) @treescope_function.scope))
