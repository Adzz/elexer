defmodule Elexer do
  @moduledoc """
  Documentation for `Elexer`.


  ### Interpreting the code

  So here is the thing. The AST forms a nested tree of sorts. But that's mad in some ways
  We build a tree out of the source code then we DFS the result. But to build a tree we
  build a stack... So why not just use the stack as the AST? That would make "executing"
  it much simpler because we'd just need to pope an instruction off of the stack and
  execute it. Is this what a stack based lang does?

  Executing the stack or executing a recursive function are two ways of doing the same
  thing probably.
  """
  def parse(source_code, handler \\ Elexer.StackHandler) do
    source_code
    |> Elexer.Emitter.read_source_code(handler, [])
    |> unwrap()
  end

  # This was pulled out as a public function so that we could call it when we
  # resume parsing after halting.
  def unwrap(result) do
    case result do
      {:syntax_error, message} -> raise Elexer.SytanxError, message
      {:syntax_error, message, arg} -> raise Elexer.SytanxError, message <> inspect(arg)
      {:ok, ast} -> ast
      {:halt, capture, state} -> {:halt, capture, state}
      {:error, state} -> {:error, state}
    end
  end

  def parse(source_code, handler, state) do
    Elexer.Emitter.read_source_code(source_code, handler, state) |> unwrap()
  end

  def run({"*", args}) when is_list(args) do
    Enum.reduce(args, 1, fn
      {inner_fn, inner_args}, total -> run({inner_fn, inner_args}) * total
      arg, total -> arg * total
    end)
  end

  def run({"+", args}) when is_list(args) do
    Enum.reduce(args, 0, fn
      {inner_fn_name, inner_args}, total -> run({inner_fn_name, inner_args}) + total
      arg, total -> arg + total
    end)
  end

  def run(_) do
    raise "Execution Error!"
  end
end
