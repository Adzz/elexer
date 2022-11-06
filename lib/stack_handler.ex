defmodule Elexer.Ignore do
  def handle_event(_event, _fn_name, state) do
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end

defmodule Elexer.StackHandler do
  @moduledoc """
  Creates a stack of elements as the source code is parsed, returning a tree of sorts; a
  recursive tuple data structure.
  TODO: add halting and early termination to this.
  """

  def handle_event(:open_s_expression, fn_name, state) do
    {:ok, [{fn_name, []} | state]}
  end

  def handle_event(:string_arg, string, state) do
    [{fn_name, args} | rest_of_state] = state
    {:ok, [{fn_name, [string | args]} | rest_of_state]}
  end

  def handle_event(:number_arg, number, state) do
    [{fn_name, args} | rest_of_state] = state
    {:ok, [{fn_name, [number | args]} | rest_of_state]}
  end

  def handle_event(:close_s_expression, [{fn_name, args}]) do
    {:ok, {fn_name, Enum.reverse(args)}}
  end

  def handle_event(
        :close_s_expression,
        [{fn_name, args}, {parent_fn_name, parent_args} | rest_of_state]
      ) do
    {:ok, [{parent_fn_name, [{fn_name, Enum.reverse(args)} | parent_args]} | rest_of_state]}
  end

  def handle_event(:close_s_expression, _state) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  # This means we never reached the last paren
  def handle_event(:end_file, [{_fn_name, _args}] = _s) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  def handle_event(:end_file, {_fn_name, _args} = ast) do
    {:ok, ast}
  end
end
