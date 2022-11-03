defmodule Elexer.Emitter do
  @space " "
  @speech_mark "\""
  @negative_symbol "-"
  @open_paren "("
  @close_paren ")"

  @open_fn_event :open_s_expression
  @close_fn_event :close_s_expression
  @string_arg_event :string_arg
  @number_arg_event :number_arg
  @end_file_event :end_file

  def read_source_code(@open_paren <> function_body, handler, state) do
    # For now we say you always expect there to be a function name.
    case parse_until(function_body, @space, "") do
      :terminal_char_never_reached ->
        {:syntax_error,
         "Could not parse function name. Fn should be separated from args by a space"}

      {@space, fn_name, rest} ->
        case handler.handle_event(@open_fn_event, fn_name, state) do
          # :halt -> {:error, "something went wrong"}

          {:ok, updated_state} ->
            parse_args(rest, handler, updated_state)
        end
    end
  end

  def read_source_code(_, _handler, _state) do
    {:syntax_error, "Program should start with a comment or an S - expression"}
  end

  defp parse_args(@close_paren <> rest, handler, state) do
    {:ok, new_state} = handler.handle_event(@close_fn_event, state)
    parse_args(rest, handler, new_state)
  end

  defp parse_args("", handler, state) do
    handler.handle_event(@end_file_event, state)
  end

  # PARSE STRING
  # Currently we don't support string escaping.
  defp parse_args(@speech_mark <> function_body, handler, state) do
    case parse_until(function_body, @speech_mark, "") do
      :terminal_char_never_reached ->
        {:syntax_error, "Binary was missing closing \""}

      # raise Elexer.SytanxError, "Binary was missing closing #{@speech_mark}"

      {@speech_mark, string, rest_of_source_code} ->
        {:ok, new_state} = handler.handle_event(@string_arg_event, string, state)
        parse_args(String.trim(rest_of_source_code), handler, new_state)
    end
  end

  # Parse S expression arg
  defp parse_args(@open_paren <> _function_body = nested_expression, handler, state) do
    # we need the rest of the source code?
    read_source_code(nested_expression, handler, state)
  end

  # IS NEGATIVE NUMBER
  defp parse_args(@negative_symbol <> value, handler, state) do
    case parse_until(value, [@space, @close_paren], "") do
      :terminal_char_never_reached ->
        {:syntax_error, "Binary was missing closing", value}

      # raise Elexer.SytanxError, "Could not cast value to number: #{inspect(value)}"

      {@space, number_string, rest_of_source_code} ->
        # if it's a space then we found an arg so do our thang
        case parse_absolute_number(number_string) do
          :error ->
            {:syntax_error, "Could not cast value to number: ", @negative_symbol <> number_string}

          # raise Elexer.SytanxError,
          # "Could not cast value to number: #{inspect(@negative_symbol <> number_string)}"

          number ->
            {:ok, new_state} = handler.handle_event(@number_arg_event, -number, state)
            parse_args(String.trim(rest_of_source_code), handler, new_state)
        end

      {@close_paren, number_string, rest_of_source_code} ->
        case parse_absolute_number(number_string) do
          :error ->
            {:syntax_error, "Could not cast value to number: ", @negative_symbol <> number_string}

          # raise Elexer.SytanxError,
          # "Could not cast value to number: #{inspect(@negative_symbol <> number_string)}"

          number ->
            {:ok, new_state} = handler.handle_event(@number_arg_event, -number, state)
            {:ok, new_state} = handler.handle_event(@close_fn_event, new_state)
            parse_args(String.trim(rest_of_source_code), handler, new_state)
        end
    end
  end

  # IS NUMBER
  defp parse_args(value, handler, state) do
    case parse_until(value, [@space, @close_paren], "") do
      :terminal_char_never_reached ->
        {:syntax_error, "Could not parse argument, missing closing bracket."}

      # raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."

      {@space, number_string, rest_of_source_code} ->
        # if it's a space then we found an arg so do our thang
        case parse_absolute_number(number_string) do
          :error ->
            {:syntax_error, "Could not cast value to number: ", number_string}

          # raise Elexer.SytanxError, "Could not cast value to number: #{inspect(number_string)}"

          number ->
            {:ok, new_state} = handler.handle_event(@number_arg_event, number, state)
            parse_args(String.trim(rest_of_source_code), handler, new_state)
        end

      {@close_paren, number_string, rest_of_source_code} ->
        case parse_absolute_number(number_string) do
          :error ->
            {:syntax_error, "Could not cast value to number: ", number_string}

          # raise Elexer.SytanxError, "Could not cast value to number: #{inspect(number_string)}"

          number ->
            {:ok, new_state} = handler.handle_event(@number_arg_event, number, state)
            {:ok, new_state} = handler.handle_event(@close_fn_event, new_state)
            parse_args(String.trim(rest_of_source_code), handler, new_state)
        end
    end
  end

  defp parse_absolute_number("") do
    # This is "there is a bug in the parser" and not "user typed the wrong source code".
    raise "Parser Error!"
  end

  defp parse_absolute_number(value) do
    case parse_integer(value, 0) do
      :number_parse_error -> :error
      :float -> parse_float(value)
      int -> int
    end
  end

  defp parse_integer("", acc), do: acc
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

  # could we inline this? Would that be better?
  @doc """
       Splits a binary into everything up to the a terminating character, the terminating
       character and everything after that.

       This iterates through the binary one byte at a time which means the terminating char should
       be one byte. If multiple terminating chars are provided we stop as soon as we see any one
       of them.

       It's faster to keep this in this module as the match context gets re-used if we do.
       you can see the warnings if you play around with this:

          ERL_COMPILER_OPTIONS=bin_opt_info mix compile --force
       """ && false
  def parse_until(<<>>, _terminal_char, _acc), do: :terminal_char_never_reached

  def parse_until(<<head::binary-size(1), rest::binary>>, [_ | _] = terminal_chars, acc) do
    if head in terminal_chars do
      {head, acc, rest}
    else
      parse_until(rest, terminal_chars, acc <> head)
    end
  end

  def parse_until(<<head::binary-size(1), rest::binary>>, terminal_char, acc) do
    case head do
      ^terminal_char -> {head, acc, rest}
      char -> parse_until(rest, terminal_char, acc <> char)
    end
  end
end
