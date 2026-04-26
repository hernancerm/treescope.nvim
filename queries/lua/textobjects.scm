;;extends

; Case: function foo() end
; Case: local function foo() end
(chunk
  (function_declaration
    name: (identifier) @treescope_outermost_function))

; Case: function M.foo() end
(chunk
  (function_declaration
    name: (dot_index_expression
      field: (identifier) @treescope_outermost_function)))

; Case: function obj:method() end
; Case: function outer.inner:method() end
(chunk
  (function_declaration
    name: (method_index_expression
      method: (identifier) @treescope_outermost_function)))

; Case: my_func = function() end
(chunk
  (assignment_statement
    (variable_list
      name: (identifier) @treescope_outermost_function)
    (expression_list
      value: (function_definition))))

; Case: local calculate = function() end
(chunk
  (variable_declaration
    (assignment_statement
      (variable_list
        name: (identifier) @treescope_outermost_function)
      (expression_list
        value: (function_definition)))))

; Case: local things = { field_with_function = function() end }
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (table_constructor
          (field
            name: (identifier) @treescope_outermost_function
            value: (function_definition)))))))

; Case: things = { field_with_function = function() end }
(chunk
  (assignment_statement
    (expression_list
      (table_constructor
        (field
          name: (identifier) @treescope_outermost_function
          value: (function_definition))))))
