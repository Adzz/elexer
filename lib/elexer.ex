defmodule Elexer do
  @moduledoc """
  Documentation for `Elexer`.
  """

  def parse(source_code, handler \\ Elexer.StackHandler) do
    source_code
    |> Elexer.Emitter.read_source_code(handler, [])
    |> unwrap()
  end

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
end
