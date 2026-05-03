;;extends

; Case: Functions (including async functions).
(module
  (function_definition
    name: (identifier) @treescope_function
  ) @treescope_function.scope)

; Case: Non-decorated methods (including async methods).
(module
  (class_definition
    body: (block
      (function_definition
        name: (identifier) @treescope_function
      ) @treescope_function.scope)))

; Case: Decorated methods.
(module
  (class_definition
    body: (block
      (decorated_definition
        definition: (function_definition
          name: (identifier) @treescope_function)
      ) @treescope_function.scope)))
