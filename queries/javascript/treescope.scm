; Case: function name() {}
(function_declaration
  name: (identifier) @treescope_function)

; Case: const/let name = () => {}
(lexical_declaration
  (variable_declarator
    name: (identifier) @treescope_function
    value: (arrow_function)))

; Case: const/let name = function() {}
(lexical_declaration
  (variable_declarator
    name: (identifier) @treescope_function
    value: (function_expression)))

; Case: var name = () => {}
(variable_declaration
  (variable_declarator
    name: (identifier) @treescope_function
    value: (arrow_function)))

; Case: var name = function() {}
(variable_declaration
  (variable_declarator
    name: (identifier) @treescope_function
    value: (function_expression)))

; Case: { name: function() {} }
(pair
  key: (property_identifier) @treescope_function
  value: (function_expression))

; Case: { name: () => {} }
(pair
  key: (property_identifier) @treescope_function
  value: (arrow_function))

; Case: it("name", () => {}) and describe/test/suite, with .only/.skip/.todo
(call_expression
  function: [
    (identifier) @_test_fn
    (member_expression object: (identifier) @_test_fn)
  ]
  arguments: (arguments
    .
    (string (string_fragment) @treescope_function)
    [(arrow_function) (function_expression)])
  (#any-of? @_test_fn
    "describe" "it" "test" "suite"
    "xdescribe" "xit" "xtest" "fdescribe" "fit" "ftest"))

; Case: class Name {}
(class_declaration name: (identifier) @treescope_class)
