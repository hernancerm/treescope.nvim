;;extends

; Case: Functions.
(module
  (function_definition name: (identifier) @treescope_outermost_function))

; Case: Non-decorated methods.
(module
  (class_definition
    body: (block
            (function_definition name: (identifier) @treescope_outermost_function))))

; Case: Decorated methods.
(module
  (class_definition
    body: (block
            (decorated_definition
              definition: (function_definition
                            name: (identifier) @treescope_outermost_function)))))
