;;extends

; IMPORTANT: These are **identical** to ../javascript/textobjects.scm

; Case: function name() {}
(function_declaration
  name: (identifier) @treescope_outermost_function)

; Case: const/let name = () => {}
(lexical_declaration
  (variable_declarator
    name: (identifier) @treescope_outermost_function
    value: (arrow_function)))

; Case: const/let name = function() {}
(lexical_declaration
  (variable_declarator
    name: (identifier) @treescope_outermost_function
    value: (function_expression)))

; Case: var name = () => {}
(variable_declaration
  (variable_declarator
    name: (identifier) @treescope_outermost_function
    value: (arrow_function)))

; Case: var name = function() {}
(variable_declaration
  (variable_declarator
    name: (identifier) @treescope_outermost_function
    value: (function_expression)))

; Case: { name: function() {} }
(pair
  key: (property_identifier) @treescope_outermost_function
  value: (function_expression))

; Case: { name: () => {} }
(pair
  key: (property_identifier) @treescope_outermost_function
  value: (arrow_function))
