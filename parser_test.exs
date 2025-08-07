# parser_test.exs
# Run with: elixir parser_test.exs

IO.puts("=== FOL Visualiser Parser Tests ===\n")

# You may need to adjust this path depending on your project structure
Code.compile_file("lib/fol_visualiser/parser.ex")

alias FOLVisualiser.Parser

test_cases = [
  {"A → A", :ok},
  {"(A → B) → (¬B → ¬A)", :ok},
  {"A ∧ B → A", :ok},
  {"A → A ∨ B", :ok},
  {"∀x:i. P(x) → P(x)", :ok},
  {"∃x:i. P(x) → ¬∀x:i. ¬P(x)", :ok},
  {"P(x) ∨ Q(y)", :ok},
  {"¬P", :ok},
  {"A &", :error},    # deliberately broken input
  {"∀x. (", :error},  # deliberately broken input
]

for {input, expected} <- test_cases do
  IO.puts("Parsing: #{input}")
  try do
    result = Parser.parse(input)
    cond do
      match?({:ok, _}, result) and expected == :ok ->
        IO.puts("  ✓ Parsed successfully.")
      match?({:error, _}, result) and expected == :error ->
        IO.puts("  ✓ Correctly failed to parse.")
      match?({:ok, _}, result) and expected == :error ->
        IO.puts("  ✗ ERROR: Parsed when it should have failed!")
      match?({:error, _}, result) and expected == :ok ->
        IO.puts("  ✗ ERROR: Failed to parse when it should have succeeded!")
      true ->
        IO.puts("  ? Unexpected result: #{inspect(result)}")
    end
  rescue
    e ->
      if expected == :error do
        IO.puts("  ✓ Correctly raised an error: #{Exception.message(e)}")
      else
        IO.puts("  ✗ ERROR: Unexpected exception: #{Exception.message(e)}")
      end
  end
end

IO.puts("\n=== Parser Test Complete ===")
