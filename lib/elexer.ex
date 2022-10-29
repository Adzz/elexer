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

  defp cast_arg("-" <> value = all) do
    case parse_number(value, 0) do
      :number_parse_error ->
        raise SytanxError, "Could not cast value to number: #{inspect(all)}"

      :float ->
        case Float.parse(value) do
          {float, ""} ->
            -float

          {_float, _rest} ->
            raise SytanxError, "Could not cast value to number: #{inspect(all)}"

          # We shouldn't ever hit this case I think
          :error ->
            raise SytanxError, "Could not cast value to number: #{inspect(all)}"
        end

      int ->
        -int
    end
  end

  defp cast_arg(value) do
    # Instead of accumulating into a list we can just multiply by base
    case parse_number(value, 0) do
      :number_parse_error ->
        raise SytanxError, "Could not cast value to number: #{inspect(value)}"

      :float ->
        case Float.parse(value) do
          {float, ""} ->
            float

          {_float, _rest} ->
            raise SytanxError, "Could not cast value to number: #{inspect(value)}"

          # We shouldn't ever hit this case I think
          :error ->
            raise SytanxError, "Could not cast value to number: #{inspect(value)}"
        end

      int ->
        int
    end
  end

  defp parse_number("", acc), do: acc

  defp parse_number(".", _acc), do: :float
  defp parse_number(<<".", _rest::binary>>, _acc), do: :float

  defp parse_number(<<?0, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 0)
  defp parse_number(<<?1, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 1)
  defp parse_number(<<?2, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 2)
  defp parse_number(<<?3, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 3)
  defp parse_number(<<?4, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 4)
  defp parse_number(<<?5, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 5)
  defp parse_number(<<?6, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 6)
  defp parse_number(<<?7, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 7)
  defp parse_number(<<?8, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 8)
  defp parse_number(<<?9, rest::binary>>, acc), do: parse_number(rest, acc * 10 + 9)

  defp parse_number(_binary, _acc) do
    :number_parse_error
  end
end
