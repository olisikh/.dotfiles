;a string passed as an argument to a function with a comment on top
(_
  (comment content: (comment_content) @injection.language) 
  (string (string_content) @injection.content)
)

;variable string with a comment on top
(
  (comment
    content: (comment_content) @injection.language
  )
  (variable_declaration
    (assignment_statement
      (_)
      (expression_list
        value: (string
          content: (string_content) @injection.content
        )
      )
    )
  )
)

;a field of table with a comment on top
(table_constructor
  (comment content: (comment_content) @injection.language)
  (field name: (_) value: (string (string_content) @injection.content))
)
