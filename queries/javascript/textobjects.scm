;;extends

; Case: function name() {}
(program
  (function_declaration
    name: (identifier) @treescope_function
  ) @treescope_function.scope)

; Case: const/let name = () => {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_function
      value: (arrow_function))
  ) @treescope_function.scope)

; Case: const/let name = function() {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_function
      value: (function_expression))
  ) @treescope_function.scope)

; Case: var name = () => {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_function
      value: (arrow_function))
  ) @treescope_function.scope)

; Case: var name = function() {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_function
      value: (function_expression))
  ) @treescope_function.scope)
