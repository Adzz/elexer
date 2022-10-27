defmodule ElexerTest do
  use ExUnit.Case
  doctest Elexer

  describe "parse/1" do
    test "raises syntax error when program starts incorrectly" do
      string = "@+ 1 2)"
      message = "Program should start with a comment or an S - expression"
      assert_raise(Elexer.SytanxError, message, fn -> Elexer.parse(string) end)
    end

    @tag :t
    test "Parses simple S expression" do
      string = "(+ 1 2)"
      ast = Elexer.parse(string)
      assert ast == {"+", ["1", "2"]}
    end
  end
end
