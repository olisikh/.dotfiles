;; extends

; sql"""SELECT * FROM user"""
(interpolated_string_expression
  interpolator: (identifier) @interpolator (#match? @interpolator "^sql[u]?|fr|fr0$")
  (interpolated_string) @injection.content (#match? @injection.content "^[\"]{3,}.*[\"]{3,}$")
  (#set! injection.language "sql")
  (#offset! @injection.content 0 3 0 -3)
)

; sql"SELECT * FROM user"
(interpolated_string_expression
  interpolator: (identifier) @interpolator (#match? @interpolator "^sql[u]?|fr|fr0$")
  (interpolated_string) @injection.content
  (#set! injection.language "sql")
  (#offset! @injection.content 0 1 0 -1)
)

; json"""{ "hello": "world" }"""
(interpolated_string_expression 
  interpolator: (identifier) @interpolator (#eq? @interpolator "json")
  (interpolated_string) @injection.content (#match? @injection.content "^[\"]{3,}.*[\"]{3,}$")
  (#set! injection.language "json")
  (#offset! @injection.content 0 3 0 -3)
)

