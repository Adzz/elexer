defmodule FakeSauce do
  @pretty false

  @fn_names ["+", "concat"]
  # require Logger
  @string_chars 48..122 |> Enum.map(&<<&1>>)
  @number_chars 48..57 |> Enum.map(&<<&1>>)

  def random_string() do
    "\"#{random_arg(@string_chars)}\""
  end

  def random_int() do
    "#{random_arg(@number_chars)}"
  end

  def arg_type_mapping() do
    %{
      string: &random_string/0,
      int: &random_int/0,
      s_expression: &random_s_expression/3
    }
  end

  def arg_types(), do: Map.keys(arg_type_mapping())

  def random_arg_type() do
    Enum.random(arg_types())
  end

  def desired_length() do
    Enum.random(0..10)
  end

  def random_arg(character_list) do
    Enum.reduce(0..desired_length(), "", fn _count, acc ->
      acc <> Enum.random(character_list)
    end)
  end

  def wrap_s_expression(s_expression, max_arg_count) do
    args_before = Enum.random(0..max_arg_count)
    args_after = Enum.random(0..max_arg_count)

    types =
      FakeSauce.arg_type_mapping()
      |> Map.drop([:s_expression])
      |> Map.keys()

    args_before =
      0..args_before
      |> Enum.reduce("", fn _count, acc ->
        random_arg_type = types |> Enum.random()
        arg_fun = Map.fetch!(arg_type_mapping(), random_arg_type)
        acc <> " " <> arg_fun.()
      end)

    "(#{Enum.random(@fn_names)}#{args_before} #{s_expression} #{args_after})"
  end

  def random_s_expression(count, max_depth, max_arg_count) when count >= max_depth do
    args_count = Enum.random(0..max_arg_count)
    indentation = String.duplicate(" ", count * 2)

    args =
      0..args_count
      |> Enum.reduce("", fn _count, acc ->
        random_arg_type =
          FakeSauce.arg_type_mapping()
          |> Map.drop([:s_expression])
          |> Map.keys()
          |> Enum.random()

        arg_fun = Map.fetch!(arg_type_mapping(), random_arg_type)
        acc <> spacing(indentation) <> arg_fun.()
      end)

    "(#{Enum.random(@fn_names)}#{args})"
  end

  def random_s_expression(count, max_depth, max_arg_count) do
    # could configure min and max here and elsewhere
    args_count = Enum.random(0..max_arg_count)
    indentation = String.duplicate(" ", count * 2)

    args =
      0..args_count
      |> Enum.reduce("", fn _count, acc ->
        case random_arg_type() do
          :s_expression ->
            arg_fun = Map.fetch!(arg_type_mapping(), :s_expression)
            # If we get a nested one then use many less args.
            acc <> spacing(indentation) <> arg_fun.(count + 1, max_depth, max_arg_count)

          random_arg_type ->
            arg_fun = Map.fetch!(arg_type_mapping(), random_arg_type)
            acc <> spacing(indentation) <> arg_fun.()
        end
      end)

    "(#{Enum.random(@fn_names)}#{args})"
  end

  defp spacing(indentation) do
    if @pretty do
      indentation
    else
      " "
    end
  end

  def generate(file_prefix, iterations, max_depth, max_arg_count) do
    for n <- 0..iterations do
      depth = Enum.random(0..max_depth)
      seed = "(+ 1 2)"

      data =
        Enum.reduce(0..depth, seed, fn d, prev ->
          wrap_s_expression(prev, max_arg_count)
        end)

      # Do we want a unique ID for these so that we don't overwrite them?
      # That would allow easier shrinking or whatever.
      file_name = file_prefix <> "source_code_#{n}"
      File.write!(file_name, data)
    end
  end
end
