;;extends

; Case: function name() {}
(program
  (function_declaration
    name: (identifier) @treescope_outermost_function))

; Case: const/let name = () => {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (arrow_function))))

; Case: const/let name = function() {}
(program
  (lexical_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (function_expression))))

; Case: var name = () => {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (arrow_function))))

; Case: var name = function() {}
(program
  (variable_declaration
    (variable_declarator
      name: (identifier) @treescope_outermost_function
      value: (function_expression))))
