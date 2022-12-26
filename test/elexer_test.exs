defmodule ElexerTest do
  use ExUnit.Case
  doctest Elexer

  describe "run/1" do
    test "we can execute an S expression" do
      ast = {"+", [1, 2]}
      assert Elexer.run(ast) == 3
    end

    test "we can execute an S expression with many args" do
      ast = {"+", [1, 2, 2, 3, 4, 5, 6]}
      assert Elexer.run(ast) == 23
    end

    test "S expressions all the way down" do
      ast = {"+", [{"+", [3, 4]}, 2]}
      assert Elexer.run(ast) == 9
    end

    test "a bit more nesting" do
      ast = {"+", [{"+", [3, {"+", [100, 10]}]}, 2]}
      assert Elexer.run(ast) == 115
    end

    test "we can multiply, we have the power" do
      ast = {"*", [1, 2]}
      assert Elexer.run(ast) == 2
    end

    test "we can multiply bigger number we have the power" do
      ast = {"*", [5, 2]}
      assert Elexer.run(ast) == 10
    end

    test "nested multiplication" do
      ast = {"*", [{"*", [5, 2]}, 2]}
      assert Elexer.run(ast) == 20
    end
  end

  test "emitter" do
    string = "(+ 1 -2)"
    ast = Elexer.parse(string)
    assert ast === {"+", [1, -2]}
  end

  describe "pausing the parser" do
    test "we can pause it halfway through?" do
      string = "(+ 1 -2)"
      assert {:halt, capture, [{"+", [1]}] = state} = Elexer.parse(string, HaltHandler)
      assert {:halt, capture, state} = capture.(state)
      ast = capture.(state)
      assert ast == {"+", [1, -2]}
    end
  end

  describe "parse/1 - nested S expression" do
    test "one level nested" do
      string = "(+ (+ 3 4) 2)"
      ast = Elexer.parse(string)
      assert ast === {"+", [{"+", [3, 4]}, 2]}
    end

    test "multi nested works" do
      string = "(+ (+ 3 4) (+ 2 44))"
      ast = Elexer.parse(string)
      assert ast === {"+", [{"+", [3, 4]}, {"+", [2, 44]}]}
    end

    test "multi nested 2 - spacing weird" do
      string = "(+ (+ 3 4) (+ 2 44) )"
      ast = Elexer.parse(string)
      assert ast === {"+", [{"+", [3, 4]}, {"+", [2, 44]}]}
    end

    test "multi nested extra close bracket" do
      string = "(+ (+ 3 4) (+ 2 44)))"
      message = "Could not parse argument, missing closing bracket."

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "nested syntax error" do
      string = "(+ (+ 3 4) (+ 2 44)"
      message = "Could not parse argument, missing closing bracket."

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end
  end

  describe "parse/1 - start errors" do
    test "raises syntax error when program starts incorrectly" do
      string = "@+ 1 2)"
      message = "Program should start with a comment or an S - expression"

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "missing closing paren" do
      string = "(+ 1 2"
      message = "Could not parse argument, missing closing bracket."

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "missing closing paren no args with space" do
      string = "(+ "
      message = "Could not parse argument, missing closing bracket."

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "missing closing paren no args no space" do
      string = "(+"
      message = "Could not parse function name. Fn should be separated from args by a space"
      assert_raise(Elexer.SytanxError, message, fn -> Elexer.parse(string) end)
    end
  end

  describe "parse/1 ints and floats" do
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
      string = "(concat \"123abc,\" \"!@#$%^&*\")"
      ast = Elexer.parse(string)
      assert ast === {"concat", ["123abc,", "!@#$%^&*"]}
    end

    test "strings that don't close syntax error" do
      string = "(+ \"@#$%^&*sss)"
      message = "Binary was missing closing \""

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end
  end

  describe "parse/1 ints and floats errors" do
    test "we syntax error when we parse args" do
      string = "(+ 1, 2)"
      message = "Could not cast value to number: \"1,\""

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "invalid argument type" do
      string = "(+ . 2)"
      message = "Unrecognised argument type: \".\""

      assert_raise(Elexer.SytanxError, message, fn ->
        Elexer.parse(string)
      end)
    end

    test "a bunch of integer / float syntax errors" do
      ["1,", "-1,", "-100.00_", "0.00,", "0..0"]
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
