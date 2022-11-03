defmodule Elexer.DebugHandler do
  defmacro with_trace(state, event, fun) do
    quote do
      IO.inspect(unquote(state), limit: :infinity, label: "before #{unquote(event)}")
      IO.inspect(apply(unquote(fun), []), limit: :infinity, label: "after #{unquote(event)}")
    end
  end

  def handle_event(event, fn_name, state) do
    with_trace(state, event, fn ->
      Elexer.StackHandler.handle_event(event, fn_name, state)
    end)
  end

  def handle_event(event, state) do
    with_trace(state, event, fn ->
      Elexer.StackHandler.handle_event(event, state)
    end)
  end
end
