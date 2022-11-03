defmodule Elexer.StackHandler do
  @moduledoc """
  TODO: add halting and early termination to this.
  """
  def handle_event(:open_s_expression, fn_name, state) do
    # state |> IO.inspect(limit: :infinity, label: "before open_s_expression")

    {:ok, [{fn_name, []} | state]}
    # |> IO.inspect(limit: :infinity, label: "after open_s_expression")
  end

  def handle_event(:string_arg, string, state) do
    # state |> IO.inspect(limit: :infinity, label: "before string_arg")
    [{fn_name, args} | rest_of_state] = state

    {:ok, [{fn_name, [string | args]} | rest_of_state]}
    # |> IO.inspect(limit: :infinity, label: "after string_arg")
  end

  def handle_event(:number_arg, number, state) do
    # state |> IO.inspect(limit: :infinity, label: "before number_arg")
    [{fn_name, args} | rest_of_state] = state

    {:ok, [{fn_name, [number | args]} | rest_of_state]}
    # |> IO.inspect(limit: :infinity, label: "after number_arg")
  end

  def handle_event(:close_s_expression, [{fn_name, args}] = _state) do
    # state |> IO.inspect(limit: :infinity, label: "before close_s_expression 1")

    {:ok, {fn_name, Enum.reverse(args)}}
    # |> IO.inspect(limit: :infinity, label: "after close_s_expression 1")
  end

  def handle_event(
        :close_s_expression,
        [{fn_name, args}, {parent_fn_name, parent_args} | rest_of_state] = _state
      ) do
    # state |> IO.inspect(limit: :infinity, label: "before close_s_expression 2")

    {:ok, [{parent_fn_name, [{fn_name, Enum.reverse(args)} | parent_args]} | rest_of_state]}
    # |> IO.inspect(limit: :infinity, label: "after close_s_expression 2")
  end

  def handle_event(:close_s_expression, _state) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  # This means we never reached the last paren
  def handle_event(:end_file, [{_fn_name, _args}] = _s) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  def handle_event(:end_file, {_fn_name, _args} = ast) do
    # ast |> IO.inspect(limit: :infinity, label: "before end_file_event")

    {:ok, ast}
    # |> IO.inspect(limit: :infinity, label: "after end_file_event")
  end
end
