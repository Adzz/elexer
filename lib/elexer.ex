defmodule Elexer do
  @moduledoc """
  Documentation for `Elexer`.
  """

  def parse(source_code, handler \\ Elexer.StackHandler) do
    case Elexer.Emitter.read_source_code(source_code, handler, []) do
      {:syntax_error, message} -> raise Elexer.SytanxError, message
      {:syntax_error, message, arg} -> raise Elexer.SytanxError, message <> inspect(arg)
      {:ok, ast} -> ast
      {:halt, state} -> {:halt, state}
      {:error, state} -> {:error, state}
    end
  end
end
