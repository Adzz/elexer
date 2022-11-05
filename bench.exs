# Module to enable benchmarking of various source code examples.
# We want to be able to generate random source code.
# We could do that by generating the AST then turning that into source code.

source = File.read!("/Users/Adz/Projects/elexer/test/generative_fixtures/perf/source_code_8")

Benchee.run(
  %{
    "4mb file stack handler" => fn ->
      Elexer.Emitter.read_source_code(source, Elexer.StackHandler, []) |> Elexer.unwrap()
    end,
    # "4mb file Ignore handler" => fn ->
    #   Elexer.Emitter.read_source_code(source, Elexer.Ignore, []) |> Elexer.unwrap()
    # end,
    "4mb stack handler No halt emitter" => fn ->
      Elexer.EmitterNoHalt.read_source_code(source, Elexer.StackHandler, []) |> Elexer.unwrap()
    end
  },
  memory_time: 1,
  reduction_time: 1
)
