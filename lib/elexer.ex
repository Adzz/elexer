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
    {fn_name, rest} = parse_until_space(string, "")
    {args, ""} = parse_args(rest, [])
    {fn_name, args}
  end

  def parse(_) do
    raise SytanxError, "Program should start with a comment or an S - expression"
  end

  # This would be the case where we had something like (+  or (+)
  # Basically we never get to the end of the fn name, is this possible?
  defp parse_until_space("", _fn_name) do
    raise SytanxError, "(a)"
  end

  defp parse_until_space(<<head::binary-size(1), rest::binary>>, fn_name) do
    # This case gives us the chance to error handle
    case head do
      " " -> {fn_name, rest}
      ")" -> {fn_name, rest}
      char -> parse_until_space(rest, fn_name <> char)
    end
  end

  defp parse_args(function_body, args) do
    # How would we think about casting args here? I guess we'd need a type system
    # Some way to annotate the types and or infer them so we could cast it correctly.
    {arg, rest} = parse_until_space(function_body, "")

    args = [cast_arg(arg) | args]

    case rest do
      "" -> {Enum.reverse(args), rest}
      ")" -> {Enum.reverse(args), rest}
      _ -> parse_args(rest, args)
    end
  end

  # I think this is getting into type system territory but I don't know nothing about them.

  # This assumes string because we start with an open ", of course we need to check for a
  # closing speech mark which we don't do right now.
  defp cast_arg("\"" <> rest_value) do
    "\"" <> rest_value
  end

  # If it's not a speechmark it will be an Integer?
  defp cast_arg(value) do
    case Integer.parse(value) do
      :error ->
        raise SytanxError, "Could not cast value to number: #{inspect(value)}"

      {int, ""} ->
        int

      {_int, "." <> _rest} ->
        case Float.parse(value) do
          {float, ""} ->
            float

          {_float, _rest} ->
            raise SytanxError, "Could not cast value to number: #{inspect(value)}"

          # We shouldn't ever hit this case I think
          :error ->
            raise SytanxError, "Could not cast value to number: #{inspect(value)}"
        end

      {_int, _rest} ->
        raise SytanxError, "Could not cast value to number: #{inspect(value)}"
    end
  end
end
