defmodule ElexerTest do
  use ExUnit.Case
  doctest Elexer

  describe "parse/1 ints and floats" do
    test "raises syntax error when program starts incorrectly" do
      string = "@+ 1 2)"
      message = "Program should start with a comment or an S - expression"
      assert_raise(Elexer.SytanxError, message, fn -> Elexer.parse(string) end)
    end

    test "Parses simple S expression" do
      string = "(+ 1 -2)"
      ast = Elexer.parse(string)
      assert ast === {"+", [1, -2]}
    end

    test "parses arbitrary args" do
      string = "(+ 1 2 2 3 4 5 6)"
      ast = Elexer.parse(string)
      assert ast === {"+", [1, 2, 2, 3, 4, 5, 6]}
    end

    test "we can cast to float" do
      string = "(+ 1 2.1 -2.2 3 4 5 6)"
      ast = Elexer.parse(string)
      assert ast === {"+", [1, 2.1, -2.2, 3, 4, 5, 6]}
    end

    test "we can cast to large int" do
      string =
        "(+ 100000000000000000000000000000000000000000000000000000000000000000000000000000)"

      ast = Elexer.parse(string)

      assert ast ===
               {"+",
                [
                  100_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000
                ]}
    end
  end

  describe "parse/1 Strings" do
    test "we can parse a string into the AST" do
      string = "(+ \"123abc,\" \"!@#$%^&*\")"
      ast = Elexer.parse(string)
      assert ast === {"+", ["\"123abc,\"", "\"!@#$%^&*\""]}
    end
  end

  describe "parse/1 ints and floats errors" do
    # Does this require a type system? To know which args are good or not.
    test "we syntax error when we parse args" do
      string = "(+ 1, 2)"
      message = "Could not cast value to number: \"1,\""
      assert_raise(Elexer.SytanxError, message, fn -> Elexer.parse(string) end)
    end

    test "a bunch of integer / float syntax errors" do
      ["1,", "-1,", "-100.00_", "0.00,", "0..0", "."]
      |> Enum.each(fn invalid ->
        string = "(+ #{invalid} 2)"
        message = "Could not cast value to number: #{inspect(invalid)}"

        assert_raise(Elexer.SytanxError, message, fn ->
          Elexer.parse(string)
        end)
      end)
    end
  end
end
