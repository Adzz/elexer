defmodule FakeSauce do
  @fn_names ["+", "concat", "-", "/", "*"]
  @string_chars 48..122 |> Enum.map(&<<&1>>)
  @number_chars 48..57 |> Enum.map(&<<&1>>)

  def generate(file_prefix, iterations, max_depth, max_arg_count, max_arg_length) do
    for n <- 0..iterations do
      depth = Enum.random(0..max_depth)
      seed = "(+ 1 2)"

      data =
        Enum.reduce(0..depth, seed, fn _, prev ->
          wrap_s_expression(prev, max_arg_count, max_arg_length)
        end)

      # Do we want a unique ID for these so that we don't overwrite them?
      # That would allow easier shrinking or whatever.
      file_name = file_prefix <> "source_code_#{n}"
      File.write!(file_name, data)
    end
  end

  def random_string(max_arg_length) do
    "\"#{random_arg(@string_chars, max_arg_length)}\""
  end

  def random_int(max_arg_length) do
    "#{random_arg(@number_chars, max_arg_length)}"
  end

  def arg_type_mapping() do
    %{
      string: &random_string/1,
      int: &random_int/1
    }
  end

  def arg_types(), do: Map.keys(arg_type_mapping())

  def random_arg_type() do
    Enum.random(arg_types())
  end

  def random_arg(character_list, max_arg_length) do
    max_arg_length = Enum.random(0..max_arg_length)

    Enum.reduce(0..max_arg_length, "", fn _count, acc ->
      acc <> Enum.random(character_list)
    end)
  end

  def wrap_s_expression(s_expression, max_arg_count, max_arg_length) do
    args_before = Enum.random(0..max_arg_count)
    args_after = Enum.random(0..max_arg_count)

    types = Map.keys(FakeSauce.arg_type_mapping())

    args_before =
      0..args_before
      |> Enum.reduce("", fn _count, acc ->
        random_arg_type = types |> Enum.random()
        arg_fun = Map.fetch!(arg_type_mapping(), random_arg_type)
        acc <> " " <> arg_fun.(max_arg_length)
      end)

    args_after =
      0..args_after
      |> Enum.reduce("", fn _count, acc ->
        random_arg_type = types |> Enum.random()
        arg_fun = Map.fetch!(arg_type_mapping(), random_arg_type)
        acc <> " " <> arg_fun.(max_arg_length)
      end)

    "(#{Enum.random(@fn_names)}#{args_before} #{s_expression} #{args_after})"
  end
end
