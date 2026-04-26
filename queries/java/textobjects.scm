;;extends

; Case: Methods.
(class_declaration body: (class_body
  (method_declaration name: (identifier) @treescope_outermost_function)))

; Case: Constructors.
(class_declaration body: (class_body
  (constructor_declaration name: (identifier) @treescope_outermost_function)))
