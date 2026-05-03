;;extends

; IMPORTANT: These are **identical** to ../javascript/textobjects.scm

; Case: function name() {}
(program
  (function_declaration
    name: (identifier) @treescope_outermost_function
  ) @treescope_outermost_function.scope)

; Case: const/let name = () => {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (arrow_function))
  ) @treescope_outermost_function.scope)

; Case: const/let name = function() {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (function_expression))
  ) @treescope_outermost_function.scope)

; Case: var name = () => {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (arrow_function))
  ) @treescope_outermost_function.scope)

; Case: var name = function() {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (function_expression))
  ) @treescope_outermost_function.scope)
