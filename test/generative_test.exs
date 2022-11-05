defmodule GenerativeTests do
  use ExUnit.Case

  folder = Path.expand("./test/generative_fixtures/") <> "/"

  files =
    folder
    |> File.ls!()
    |> Enum.reject(&(&1 == ".gitignore"))

  FakeSauce.generate(folder, 100, 5, 10)

  for file <- files do
    test "#{file}" do
      (unquote(folder) <> unquote(file))
      |> File.read!()
      |> Elexer.parse()
    end
  end
end
