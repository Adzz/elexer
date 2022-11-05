# Elexer

An elixir lisp lexer / parser / compiler?? thing. I don't even know the difference really I just like to call it a lexer because it makes the title pun make sense.

Don't use it.

But if you want to you can call it like:

```elixir
source_code = "(first (list 1 (+ 2 3) 9))"
Elexer.parse(source_code)
```

## Features

### Handlers

The parser emits events that you can consume and do stuff on the back of. The specific events that get emitted are open to change as we learn more but the idea is you can implement your own handlers and do whatever you want when you get an event.

By default we use a stack based handler which builds up a simple AST that looks like this:

```elixir
{function_name, args}
```

where args can be a string, an integer a float or nested S expression.


### Halting / Resuming

You can also halt / resume the parser by returning a `:halt` tuple that looks like this:

```elixir
{:halt, state}
```

That will make the parser return this:
```elixir
{:halt, continuation, state}
```
allowing you to continue by doing this:
```elixir
continuation.(state)
```

I'm not really sure why this would be good but one thought is if this parser was a Nif that halting would maybe play nice with the BEAM and stuff. It's not a nif though so it's more just a "I wonder if this is possible" kind of thing.

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
