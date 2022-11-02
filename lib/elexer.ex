defmodule Elexer do
  defmodule SytanxError do
    defexception [:message]
  end

  @missing_paren_on_arg_error "Could not parse argument, missing closing bracket."

  @moduledoc """
  Documentation for `Elexer`.
  """

  @doc """
  Parses lisps.
  """
  def parse(string) do
    {ast, ""} = do_parse(string)
    ast
  end

  def do_parse("(" <> string) do
    case parse_until(string, [" ", ")"], "") do
      :terminal_char_never_reached ->
        raise SytanxError, "Could not parse function name, missing closing bracket."

      {fn_name, rest} ->
        case parse_args(rest, []) do
          {args, rest} -> {{fn_name, args}, rest}
        end
    end
  end

  def do_parse(_) do
    raise SytanxError, "Program should start with a comment or an S - expression"
  end

  defp parse_args("(" <> _value = nested_expression, args) do
    {nested_s_expression_ast, rest} = do_parse(nested_expression)
    parse_args(rest, [nested_s_expression_ast | args])
  end

  defp parse_args(function_body, args) do
    case parse_until(function_body, [" ", ")"], "") do
      :terminal_char_never_reached -> raise SytanxError, @missing_paren_on_arg_error
      # This is for this case "(1 )" ; we'd hit the space but then there are no arguments.
      {"", ""} -> {[], ""}
      # This is when a nested S expression was an arg and there is still some outer S expression to parse.
      {"", rest} -> {Enum.reverse(args), rest}
      # This is when we hit an ")"  BUT there is no more string to parse.
      {arg, ""} -> {Enum.reverse([cast_arg(arg) | args]), ""}
      {arg, rest} -> parse_args(rest, [cast_arg(arg) | args])
    end
  end

  # I think this is getting into type system territory but I don't know nothing about them.

  # IS STRING
  # String parsing currently does not handle escaping speech marks in text.
  defp cast_arg("\"" <> rest_value = full_string) do
    case parse_until(rest_value, "\"", "") do
      :terminal_char_never_reached -> raise SytanxError, "Binary was missing closing \""
      # I _think_ it should always be empty if parse_arg is working correctly.
      {_fn_name, ""} -> full_string
    end
  end

  # IS S EXPRESSION. Is this the right place to do this? I think nawt.
  defp cast_arg("(" <> _value = nested_expression) do
    raise "noa"
    parse(nested_expression)
  end

  # IS NEGATIVE NUMBER
  defp cast_arg("-" <> value = all) do
    case parse_absolute_number(value) do
      :error -> raise SytanxError, "Could not cast value to number: #{inspect(all)}"
      number -> -number
    end
  end

  # IS NUMBER
  defp cast_arg(value) do
    case parse_absolute_number(value) do
      :error -> raise SytanxError, "Could not cast value to number: #{inspect(value)}"
      number -> number
    end
  end

  defp parse_absolute_number(value) do
    case parse_integer(value, 0) do
      :number_parse_error -> :error
      :float -> parse_float(value)
      int -> int
    end
  end

  # this should be public and unit tested. Then we could document but if you provide
  # multiple terminal chars then we OR them - ie stop as soon as we see any of them.
  # Function returns a tuple of the extracted text and the rest of the text that's left to parse.
  # (ie all the text _after_ the terminal char).
  defp parse_until("", _terminal_char, _fn_name), do: :terminal_char_never_reached

  defp parse_until(<<head::binary-size(1), rest::binary>>, [_ | _] = terminal_chars, fn_name) do
    if head in terminal_chars do
      {fn_name, rest}
    else
      parse_until(rest, terminal_chars, fn_name <> head)
    end
  end

  defp parse_until(<<head::binary-size(1), rest::binary>>, terminal_char, fn_name) do
    # This case gives us the chance to error handle
    case head do
      ^terminal_char -> {fn_name, rest}
      char -> parse_until(rest, terminal_char, fn_name <> char)
    end
  end

  defp parse_integer("", acc), do: acc

  defp parse_integer(".", _acc), do: :float
  # Kind of inefficient to throw away acc but until we know how float parsing works we have to
  defp parse_integer(<<".", _rest::binary>>, _acc), do: :float
  defp parse_integer(<<?0, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 0)
  defp parse_integer(<<?1, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 1)
  defp parse_integer(<<?2, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 2)
  defp parse_integer(<<?3, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 3)
  defp parse_integer(<<?4, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 4)
  defp parse_integer(<<?5, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 5)
  defp parse_integer(<<?6, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 6)
  defp parse_integer(<<?7, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 7)
  defp parse_integer(<<?8, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 8)
  defp parse_integer(<<?9, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 9)
  defp parse_integer(_binary, _acc), do: :number_parse_error

  # We should parse this manually for fun.
  defp parse_float(value) do
    case Float.parse(value) do
      {float, ""} -> float
      {_float, _rest} -> :error
      :error -> :error
    end
  end
end
