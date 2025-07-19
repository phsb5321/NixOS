; Nix treesitter queries for injections
; This is a placeholder file for Neovim Nix syntax highlighting

; Inject bash into shell scripts
((string_expression 
  (indented_string_expression) @injection.content)
 (#match? @injection.content "^[\s]*#!.*/bin/(bash|sh)")
 (#set! injection.language "bash"))

; Inject lua into Lua expressions
((string_expression
  (indented_string_expression) @injection.content)
 (#match? @injection.content "^[\s]*--.*[Ll]ua")
 (#set! injection.language "lua"))
