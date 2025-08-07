# FOL Visualiser Usage Example
# Run with: elixir usage_example.exs

# Compile all modules
IO.puts("Compiling FOL Visualiser modules...")

modules = [
  "lib/fol_visualiser/structs.ex",
  "lib/fol_visualiser/term.ex", 
  "lib/fol_visualiser/unification.ex",
  "lib/fol_visualiser/unification_adapter.ex",
  "lib/fol_visualiser/parser.ex",
  "lib/fol_visualiser/fol.ex",
  "lib/fol_visualiser/tree_visualizer.ex",
  "lib/fol_visualiser.ex"
]

Enum.each(modules, fn module_path ->
  try do
    modules_loaded = Code.compile_file(module_path)
    IO.puts("✓ Compiled #{module_path} (Loaded: #{inspect(Enum.map(modules_loaded, fn {mod, _} -> mod end))})")
  rescue
    e ->
      IO.puts("✗ Error compiling #{module_path}: #{Exception.message(e)}")
      System.halt(1)
  end
end)

# Import the FOLVisualiser module
alias FOLVisualiser

IO.puts("\n=== FOL Visualiser Demo ===")

# Example formulas to test
formulas = [
  "A → A",
  "(A → B) → (¬B → ¬A)", 
  "A ∧ B → A",
  "A → A ∨ B",
  "∀x:i. P(x) → P(x)",
  "∃x:i. P(x) → ¬∀x:i. ¬P(x)"
]

IO.puts("\nTesting various FOL formulas:")
IO.puts("================================")

Enum.each(formulas, fn formula ->
  IO.puts("\nFormula: #{formula}")
  IO.puts("--------------------------------")
  
  try do
    result = FOLVisualiser.prove_and_visualize(formula)
    
    # Check if result is a string (HTML) or Kino.HTML struct
    case result do
      html when is_binary(html) ->
        IO.puts("✓ HTML visualization generated successfully!")
      _ ->
        IO.puts("✓ Kino.HTML visualization generated successfully!")
    end
    
    # Extract basic info (this won't work for Kino.HTML, but will for our HTML string)
    if is_binary(result) do
      # Try to extract some basic info from the HTML
      if String.contains?(result, "VALID") do
        IO.puts("  Result: VALID")
      else
        IO.puts("  Result: INVALID")
      end
    end
    
    IO.puts("  (Full visualization available as HTML/Kino.HTML)")
  rescue
    e ->
      IO.puts("✗ Error: #{Exception.message(e)}")
  end
end)

IO.puts("\n=== Demo Complete ===")
IO.puts("To see the full visualizations:")
IO.puts("1. Run this in LiveBook with Kino dependency for interactive widgets")
IO.puts("2. Save the HTML output to a file and open in a browser")
IO.puts("3. Use the fol_visualiser_demo.livemd file for the best experience")
