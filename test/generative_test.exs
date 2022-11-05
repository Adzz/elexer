defmodule GenerativeTests do
  use ExUnit.Case

  folder = Path.expand("./test/generative_fixtures/") <> "/"

  files =
    folder
    |> File.ls!()
    |> Enum.reject(&(&1 in [".gitignore", "perf"]))

  FakeSauce.generate(folder, 100, 100, 10, 10)

  for file <- files do
    test "#{file}" do
      (unquote(folder) <> unquote(file))
      |> File.read!()
      |> Elexer.parse()
    end
  end
end
