defmodule Elexer do
  defmodule SytanxError do
    defexception [:message]
  end

  @moduledoc """
  Documentation for `Elexer`.
  """
  @doc """
  Parses lisps.
  """
  def parse("(" <> string) do
    {fn_name, rest} = parse_fn_name(string, "")
    {args, rest} = parse_args(rest, [])
    {fn_name, args}
  end

  def parse(_) do
    raise SytanxError, "Program should start with a comment or an S - expression"
  end

  # This would be the case where we had something like (+  or (+)
  # Basically we never get to the end of the fn name, is this possible?
  defp parse_fn_name("", fn_name) do
    raise SytanxError, "(a)"
  end

  defp parse_fn_name(<<head::binary-size(1), rest::binary>>, fn_name) do
    # This case gives us the chance to error handle
    case head do
      " " -> {fn_name, rest}
      ")" -> {fn_name, rest}
      char -> parse_fn_name(rest, fn_name <> char)
    end
  end

  defp parse_args(function_body, args) do
    # How would we think about casting args here? I guess we'd need a type system
    # Some way to annotate the types and or infer them so we could cast it correctly.
    {arg, rest} = parse_fn_name(function_body, "")
    args = [arg | args]

    case rest do
      "" -> {Enum.reverse(args), rest}
      ")" -> {Enum.reverse(args), rest}
      _ -> parse_args(rest, args)
    end
  end

  defp parse_s_expression(<<head::binary-size(1), rest::binary>>, acc) do
    case head do
      ")" ->
        acc

      char ->
        nil
    end
  end
end
