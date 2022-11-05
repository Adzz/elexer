# Elexer

An elixir lisp lexer.

Don't use it.


## The assignment

Lisp parser

Write code that takes some Lisp code and returns an abstract syntax tree. The AST should represent the structure of the code and the meaning of each token. For example, if your code is given

```elixir
"(first (list 1 (+ 2 3) 9))"
```

it could return a nested array like

```elixir
["first", ["list", 1, ["+", 2, 3], 9]].
```

During your interview, you will pair on writing an interpreter to run the AST. You can start by implementing a single built-in function (for example, `+`) and add more if you have time.
