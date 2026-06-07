; Case: function foo() end
(function_declaration name: (identifier) @treescope_outermost_function)

; Case: function M.foo() end
(function_declaration
  name: (dot_index_expression
          field: (identifier) @treescope_outermost_function))

; Case: function obj:foo() end
(function_declaration
  name: (method_index_expression method: (identifier) @treescope_outermost_function))

; Case: foo = function() end
(assignment_statement
  (variable_list name: (identifier) @treescope_outermost_function)
  (expression_list value: (function_definition)))

; Case: { foo = function() end }
(field
  name: (identifier) @treescope_outermost_function
  value: (function_definition))
