defmodule Elexer.StackHandler do
  @moduledoc """
  TODO: add halting and early termination to this.
  """
  @with_trace Application.compile_env!(:elexer, :with_trace?)

  defmacro with_trace(state, event, result) do
    if @with_trace do
      quote do
        IO.inspect(unquote(state), limit: :infinity, label: "before #{unquote(event)}")
        IO.inspect(unquote(result), limit: :infinity, label: "after #{unquote(event)}")
      end
    else
      quote do
        unquote(result)
      end
    end
  end

  def handle_event(:open_s_expression, fn_name, state) do
    with_trace(state, :open_s_expression, {:ok, [{fn_name, []} | state]})
  end

  def handle_event(:string_arg, string, state) do
    [{fn_name, args} | rest_of_state] = state
    with_trace(state, :string_arg, {:ok, [{fn_name, [string | args]} | rest_of_state]})
  end

  def handle_event(:number_arg, number, state) do
    [{fn_name, args} | rest_of_state] = state
    with_trace(state, :number_arg, {:ok, [{fn_name, [number | args]} | rest_of_state]})
  end

  def handle_event(:close_s_expression, [{fn_name, args}]) do
    with_trace([{fn_name, args}], :close_s_expression, {:ok, {fn_name, Enum.reverse(args)}})
  end

  def handle_event(
        :close_s_expression,
        [{fn_name, args}, {parent_fn_name, parent_args} | rest_of_state]
      ) do
    with_trace(
      [{fn_name, args}, {parent_fn_name, parent_args} | rest_of_state],
      :close_s_expression,
      {:ok, [{parent_fn_name, [{fn_name, Enum.reverse(args)} | parent_args]} | rest_of_state]}
    )
  end

  def handle_event(:close_s_expression, _state) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  # This means we never reached the last paren
  def handle_event(:end_file, [{_fn_name, _args}] = _s) do
    raise Elexer.SytanxError, "Could not parse argument, missing closing bracket."
  end

  def handle_event(:end_file, {_fn_name, _args} = ast) do
    with_trace(ast, :end_file, {:ok, ast})
  end
end
