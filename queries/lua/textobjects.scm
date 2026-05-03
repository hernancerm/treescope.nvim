;;extends

; Case: function foo() end
; Case: local function foo() end
(chunk
  (function_declaration
    name: (identifier) @treescope_outermost_function
  ) @treescope_outermost_function.scope)

; Case: function M.foo() end
; Movement lands on 'foo' (inner identifier).
; Statusline displays 'M.foo' (full dot_index_expression text via .name capture).
(chunk
  (function_declaration
    name: (dot_index_expression
      field: (identifier) @treescope_outermost_function
    ) @treescope_outermost_function.name
  ) @treescope_outermost_function.scope)

; Case: function obj:method() end
; Case: function outer.inner:method() end
; Movement lands on 'method' (inner identifier).
; Statusline displays 'obj:method' or 'outer.inner:method' (full method_index_expression
; text via .name capture).
(chunk
  (function_declaration
    name: (method_index_expression
      method: (identifier) @treescope_outermost_function
    ) @treescope_outermost_function.name
  ) @treescope_outermost_function.scope)

; Case: my_func = function() end
; Scope is assignment_statement so cursor on 'my_func' (before '=') is inside scope.
(chunk
  (assignment_statement
    (variable_list
      name: (identifier) @treescope_outermost_function)
    (expression_list
      value: (function_definition))
  ) @treescope_outermost_function.scope)

; Case: local calculate = function() end
; Scope is variable_declaration so cursor on 'calculate' is inside scope.
(chunk
  (variable_declaration
    (assignment_statement
      (variable_list
        name: (identifier) @treescope_outermost_function)
      (expression_list
        value: (function_definition)))
  ) @treescope_outermost_function.scope)

; For each depth new queries are needed:

; Depth 1
;
; Case: local things = { field_with_function = function() end }
; Scope is the 'field' node: spans from the key name to the end of the function body,
; so cursor on the key name is inside scope.
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (table_constructor
          (field
            name: (identifier) @treescope_outermost_function
            value: (function_definition)) @treescope_outermost_function.scope)))))
; Case: things = { field_with_function = function() end }
(chunk
  (assignment_statement
    (expression_list
      (table_constructor
        (field
          name: (identifier) @treescope_outermost_function
          value: (function_definition)) @treescope_outermost_function.scope))))
; Case: return { field_with_function = function() end }
(chunk
  (return_statement
    (expression_list
      (table_constructor
        (field
          name: (identifier) @treescope_outermost_function
          value: (function_definition)) @treescope_outermost_function.scope))))
; Case: foo("bar", { baz = function() end })
; Case: M.foo("bar", { baz = function() end })
(chunk
  (function_call
    (arguments
      (table_constructor
        (field
          name: (identifier) @treescope_outermost_function
          value: (function_definition)) @treescope_outermost_function.scope))))

; Depth 2
;
; Case: local things = { { nested_field = function() end } }
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (table_constructor
          (field
            value: (table_constructor
              (field
                name: (identifier) @treescope_outermost_function
                value: (function_definition)) @treescope_outermost_function.scope)))))))
; Case: things = { { nested_field = function() end } }
(chunk
  (assignment_statement
    (expression_list
      (table_constructor
        (field
          value: (table_constructor
            (field
              name: (identifier) @treescope_outermost_function
              value: (function_definition)) @treescope_outermost_function.scope))))))
; Case: return { { nested_field = function() end } }
(chunk
  (return_statement
    (expression_list
      (table_constructor
        (field
          value: (table_constructor
            (field
              name: (identifier) @treescope_outermost_function
              value: (function_definition)) @treescope_outermost_function.scope))))))
; Case: foo("bar", { { baz = function() end } })
; Case: M.foo("bar", { { baz = function() end } })
(chunk
  (function_call
    (arguments
      (table_constructor
        (field
          value: (table_constructor
            (field
              name: (identifier) @treescope_outermost_function
              value: (function_definition)) @treescope_outermost_function.scope))))))
; Case: local T = new_set({ hooks = { post_once = function() end } })
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (function_call
          (arguments
            (table_constructor
              (field
                value: (table_constructor
                  (field
                    name: (identifier) @treescope_outermost_function
                    value: (function_definition)) @treescope_outermost_function.scope)))))))))
; Case: T = new_set({ hooks = { post_once = function() end } })
(chunk
  (assignment_statement
    (expression_list
      (function_call
        (arguments
          (table_constructor
            (field
              value: (table_constructor
                (field
                  name: (identifier) @treescope_outermost_function
                  value: (function_definition)) @treescope_outermost_function.scope))))))))

; Depth 3
;
; Case: local things = { { { deeply_nested_field = function() end } } }
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (table_constructor
          (field
            value: (table_constructor
              (field
                value: (table_constructor
                  (field
                    name: (identifier) @treescope_outermost_function
                    value: (function_definition)) @treescope_outermost_function.scope)))))))))
; Case: things = { { { deeply_nested_field = function() end } } }
(chunk
  (assignment_statement
    (expression_list
      (table_constructor
        (field
          value: (table_constructor
            (field
              value: (table_constructor
                (field
                  name: (identifier) @treescope_outermost_function
                  value: (function_definition)) @treescope_outermost_function.scope))))))))
; Case: return { { { deeply_nested_field = function() end } } }
(chunk
  (return_statement
    (expression_list
      (table_constructor
        (field
          value: (table_constructor
            (field
              value: (table_constructor
                (field
                  name: (identifier) @treescope_outermost_function
                  value: (function_definition)) @treescope_outermost_function.scope))))))))
; Case: foo("bar", { { { baz = function() end } } })
; Case: M.foo("bar", { { { baz = function() end } } })
(chunk
  (function_call
    (arguments
      (table_constructor
        (field
          value: (table_constructor
            (field
              value: (table_constructor
                (field
                  name: (identifier) @treescope_outermost_function
                  value: (function_definition)) @treescope_outermost_function.scope))))))))
; Case: local T = new_set({ hooks = { hooks = { post_once = function() end } } })
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (function_call
          (arguments
            (table_constructor
              (field
                value: (table_constructor
                  (field
                    value: (table_constructor
                      (field
                        name: (identifier) @treescope_outermost_function
                        value: (function_definition)) @treescope_outermost_function.scope)))))))))))
; Case: T = new_set({ hooks = { hooks = { post_once = function() end } } })
(chunk
  (assignment_statement
    (expression_list
      (function_call
        (arguments
          (table_constructor
            (field
              value: (table_constructor
                (field
                  value: (table_constructor
                    (field
                      name: (identifier) @treescope_outermost_function
                      value: (function_definition)) @treescope_outermost_function.scope))))))))))

; Depth 4
;
; Case: local T = new_set({ hooks = { hooks = { hooks = { post_once = function() end } } } })
(chunk
  (variable_declaration
    (assignment_statement
      (expression_list
        (function_call
          (arguments
            (table_constructor
              (field
                value: (table_constructor
                  (field
                    value: (table_constructor
                      (field
                        value: (table_constructor
                          (field
                            name: (identifier) @treescope_outermost_function
                            value: (function_definition)) @treescope_outermost_function.scope)))))))))))))
; Case: T = new_set({ hooks = { hooks = { hooks = { post_once = function() end } } } })
(chunk
  (assignment_statement
    (expression_list
      (function_call
        (arguments
          (table_constructor
            (field
              value: (table_constructor
                (field
                  value: (table_constructor
                    (field
                      value: (table_constructor
                        (field
                          name: (identifier) @treescope_outermost_function
                          value: (function_definition)) @treescope_outermost_function.scope))))))))))))
