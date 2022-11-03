defmodule Elexer do
  defmodule SytanxError do
    defexception [:message]
  end

  @moduledoc """
  Documentation for `Elexer`.
  """

  defmodule StackHandler do
    def handle_event(:open_s_expression, fn_name, state) do
      state |> IO.inspect(limit: :infinity, label: "before open_s_expression")

      {:ok, [{fn_name, []} | state]}
      |> IO.inspect(limit: :infinity, label: "after open_s_expression")
    end

    def handle_event(:string_arg, string, state) do
      state |> IO.inspect(limit: :infinity, label: "before string_arg")
      [{fn_name, args} | rest_of_state] = state

      {:ok, [{fn_name, [string | args]} | rest_of_state]}
      |> IO.inspect(limit: :infinity, label: "after string_arg")
    end

    def handle_event(:number_arg, number, state) do
      state |> IO.inspect(limit: :infinity, label: "before number_arg")
      [{fn_name, args} | rest_of_state] = state

      {:ok, [{fn_name, [number | args]} | rest_of_state]}
      |> IO.inspect(limit: :infinity, label: "after number_arg")
    end

    def handle_event(:close_s_expression, [{fn_name, args}] = state) do
      state |> IO.inspect(limit: :infinity, label: "before close_s_expression 1")

      {:ok, {fn_name, Enum.reverse(args)}}
      |> IO.inspect(limit: :infinity, label: "after close_s_expression 1")
    end

    def handle_event(
          :close_s_expression,
          [{fn_name, args}, {parent_fn_name, parent_args} | rest_of_state] = state
        ) do
      state |> IO.inspect(limit: :infinity, label: "before close_s_expression 2")

      {:ok, [{parent_fn_name, [{fn_name, Enum.reverse(args)} | parent_args]} | rest_of_state]}
      |> IO.inspect(limit: :infinity, label: "after close_s_expression 2")
    end

    def handle_event(:close_s_expression, _state) do
      raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
    end

    # This means we never reached the last paren
    def handle_event(:end_file, [{_fn_name, _args}] = s) do
      raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
    end

    def handle_event(:end_file, {_fn_name, _args} = ast) do
      ast |> IO.inspect(limit: :infinity, label: "before end_file_event")

      {:ok, ast}
      |> IO.inspect(limit: :infinity, label: "after end_file_event")
    end
  end

  defmodule Emitter do
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
          raise SytanxError,
                "Could not parse function name. Fn should be separated from args by a space"

        {@space, fn_name, rest} ->
          case handler.handle_event(@open_fn_event, fn_name, state) do
            # obvs improve this in a minute add halting / pause capabilities to the parser.
            # would be cool to do a JSON parser like that too. alas/
            # :halt -> {:error, "something went wrong"}

            {:ok, updated_state} ->
              parse_args(rest, handler, updated_state)
          end
      end
    end

    def read_source_code(_, _handler, _state) do
      raise SytanxError, "Program should start with a comment or an S - expression"
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
          raise SytanxError, "Binary was missing closing #{@speech_mark}"

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
          raise SytanxError, "Could not cast value to number: #{inspect(value)}"

        {@space, number_string, rest_of_source_code} ->
          # if it's a space then we found an arg so do our thang
          case parse_absolute_number(number_string) do
            :error ->
              raise SytanxError,
                    "Could not cast value to number: #{inspect(@negative_symbol <> number_string)}"

            number ->
              {:ok, new_state} = handler.handle_event(@number_arg_event, -number, state)
              parse_args(String.trim(rest_of_source_code), handler, new_state)
          end

        {@close_paren, number_string, rest_of_source_code} ->
          case parse_absolute_number(number_string) do
            :error ->
              raise SytanxError,
                    "Could not cast value to number: #{inspect(@negative_symbol <> number_string)}"

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
          raise SytanxError, "Could not parse argument, missing closing bracket."

        {@space, number_string, rest_of_source_code} ->
          # if it's a space then we found an arg so do our thang
          case parse_absolute_number(number_string) do
            :error ->
              raise SytanxError, "Could not cast value to number: #{inspect(number_string)}"

            number ->
              {:ok, new_state} = handler.handle_event(@number_arg_event, number, state)
              parse_args(String.trim(rest_of_source_code), handler, new_state)
          end

        {@close_paren, number_string, rest_of_source_code} ->
          number_string |> IO.inspect(limit: :infinity, label: "ppppppppppp")

          case parse_absolute_number(number_string) do
            :error ->
              raise SytanxError, "Could not cast value to number: #{inspect(number_string)}"

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

    # this should be public and unit tested. Then we could document but if you provide
    # multiple terminal chars then we OR them - ie stop as soon as we see any of them.
    # Function returns a tuple of the extracted text and the rest of the text that's left to parse.
    # (ie all the text _after_ the terminal char).
    defp parse_until("", _terminal_char, _fn_name), do: :terminal_char_never_reached

    defp parse_until(<<head::binary-size(1), rest::binary>>, [_ | _] = terminal_chars, fn_name) do
      if head in terminal_chars do
        {head, fn_name, rest}
      else
        parse_until(rest, terminal_chars, fn_name <> head)
      end
    end

    defp parse_until(<<head::binary-size(1), rest::binary>>, terminal_char, fn_name) do
      case head do
        ^terminal_char -> {head, fn_name, rest}
        char -> parse_until(rest, terminal_char, fn_name <> char)
      end
    end
  end

  def parse(source_code) do
    {:ok, ast} = Emitter.read_source_code(source_code, StackHandler, [])
    ast
  end

  # @doc """
  # Parses lisps.
  # """
  # def parse(string) do
  #   case do_parse(string) do
  #     {ast, ")"} -> raise SytanxError, "One too many closing parens :("
  #     {ast, ""} -> ast
  #   end
  # end

  # def do_parse("(" <> string) do
  #   case parse_until(string, [" ", ")"], "") do
  #     :terminal_char_never_reached ->
  #       raise SytanxError, "Could not parse function name, missing closing bracket."

  #     {fn_name, rest} ->
  #       case parse_args(rest, []) do
  #         {args, rest} -> {{fn_name, args}, rest}
  #       end
  #   end
  # end

  # def do_parse(_) do
  #   raise SytanxError, "Program should start with a comment or an S - expression"
  # end

  # # We don't check for closing paren here... problematic
  # defp parse_args("(" <> _value = nested_expression, args) do
  #   case do_parse(nested_expression) |> IO.inspect(limit: :infinity, label: "dp") do
  #     # If the rest of the source code is just a closing bracket then we are finished.
  #     {nested_s_expression_ast, ")" = _rest_of_source_code} ->
  #       {Enum.reverse([nested_s_expression_ast | args]), ""}

  #     # If the rest contains other things then there must be more args to parse so we continue
  #     {nested_s_expression_ast, rest_of_source_code} ->
  #       parse_args(rest_of_source_code, [nested_s_expression_ast | args])
  #   end
  # end

  # defp parse_args(function_body, args) do
  #   case parse_until(function_body, [" ", ")"], "") do
  #     :terminal_char_never_reached -> raise SytanxError, @missing_paren_on_arg_error
  #     # If there is no arg_string that's because we hit the terminal char, so we are done
  #     # with the args, we reverse and return the rest of the string to continue parsing.
  #     # {"", ")"} ->
  #     # function_body |> IO.inspect(limit: :infinity, label: "")
  #     # raise "hi"
  #     # {Enum.reverse(args), rest}
  #     {"", rest} -> {Enum.reverse(args), rest}
  #     # If there is no rest of the string we are also done.
  #     {arg_string, ")"} -> {Enum.reverse([cast_arg(arg_string) | args]), ")"}
  #     {arg_string, ""} -> {Enum.reverse([cast_arg(arg_string) | args]), ""}
  #     # {arg_string, ""} -> {Enum.reverse([cast_arg(arg_string) | args]), ""}
  #     # If there is an arg_string and some more to parse then we continue.
  #     {arg_string, rest} -> parse_args(rest, [cast_arg(arg_string) | args])
  #   end
  # end

  # # I think this is getting into type system territory but I don't know nothing about them.

  # # IS STRING
  # # String parsing currently does not handle escaping speech marks in text.
  # defp cast_arg("\"" <> rest_value = full_string) do
  #   case parse_until(rest_value, "\"", "") do
  #     :terminal_char_never_reached -> raise SytanxError, "Binary was missing closing \""
  #     # I _think_ it should always be empty if parse_arg is working correctly.
  #     {_fn_name, ""} -> full_string
  #   end
  # end

  # # IS S EXPRESSION. Is this the right place to do this? I think nawt.
  # defp cast_arg("(" <> _value = nested_expression) do
  #   raise "noa"
  #   parse(nested_expression)
  # end

  # # IS NEGATIVE NUMBER
  # defp cast_arg("-" <> value = all) do
  #   case parse_absolute_number(value) do
  #     :error -> raise SytanxError, "Could not cast value to number: #{inspect(all)}"
  #     number -> -number
  #   end
  # end

  # # IS NUMBER
  # defp cast_arg(value) do
  #   case parse_absolute_number(value) do
  #     :error -> raise SytanxError, "Could not cast value to number: #{inspect(value)}"
  #     number -> number
  #   end
  # end

  # defp parse_absolute_number(value) do
  #   case parse_integer(value, 0) do
  #     :number_parse_error -> :error
  #     :float -> parse_float(value)
  #     int -> int
  #   end
  # end

  # # this should be public and unit tested. Then we could document but if you provide
  # # multiple terminal chars then we OR them - ie stop as soon as we see any of them.
  # # Function returns a tuple of the extracted text and the rest of the text that's left to parse.
  # # (ie all the text _after_ the terminal char).
  # defp parse_until("", _terminal_char, _fn_name), do: :terminal_char_never_reached

  # defp parse_until(<<head::binary-size(1), rest::binary>>, [_ | _] = terminal_chars, fn_name) do
  #   if head in terminal_chars do
  #     {fn_name, rest}
  #   else
  #     parse_until(rest, terminal_chars, fn_name <> head)
  #   end
  # end

  # defp parse_until(<<head::binary-size(1), rest::binary>>, terminal_char, fn_name) do
  #   # This case gives us the chance to error handle
  #   case head do
  #     ^terminal_char -> {fn_name, rest}
  #     char -> parse_until(rest, terminal_char, fn_name <> char)
  #   end
  # end

  # defp parse_integer("", acc), do: acc

  # defp parse_integer(".", _acc), do: :float
  # # Kind of inefficient to throw away acc but until we know how float parsing works we have to
  # defp parse_integer(<<".", _rest::binary>>, _acc), do: :float
  # defp parse_integer(<<?0, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 0)
  # defp parse_integer(<<?1, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 1)
  # defp parse_integer(<<?2, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 2)
  # defp parse_integer(<<?3, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 3)
  # defp parse_integer(<<?4, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 4)
  # defp parse_integer(<<?5, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 5)
  # defp parse_integer(<<?6, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 6)
  # defp parse_integer(<<?7, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 7)
  # defp parse_integer(<<?8, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 8)
  # defp parse_integer(<<?9, rest::binary>>, acc), do: parse_integer(rest, acc * 10 + 9)
  # defp parse_integer(_binary, _acc), do: :number_parse_error

  # # We should parse this manually for fun.
  # defp parse_float(value) do
  #   case Float.parse(value) do
  #     {float, ""} -> float
  #     {_float, _rest} -> :error
  #     :error -> :error
  #   end
  # end
end
