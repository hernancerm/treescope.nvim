;;extends

; function foo() end
; local function foo() end
(function_declaration
  name: (identifier) @treescope_function
) @treescope_function.scope

; function M.foo() end
(function_declaration
  name: (dot_index_expression
    field: (identifier) @treescope_function
  ) @treescope_function.name
) @treescope_function.scope

; function obj:method() end
; function outer.inner:method() end
(function_declaration
  name: (method_index_expression
    method: (identifier) @treescope_function
  ) @treescope_function.name
) @treescope_function.scope

; my_func = function() end
(assignment_statement
  (variable_list
    name: (identifier) @treescope_function)
  (expression_list
    value: (function_definition))
) @treescope_function.scope

; local calculate = function() end
(variable_declaration
  (assignment_statement
    (variable_list
      name: (identifier) @treescope_function)
    (expression_list
      value: (function_definition)))
) @treescope_function.scope

; { field = function() end } - any depth
(field
  name: (identifier) @treescope_function
  value: (function_definition)
) @treescope_function.scope
