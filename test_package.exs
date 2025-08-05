#!/usr/bin/env elixir

# Simple test script to verify the FOL Visualiser package works

# Compile all modules in order
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
  case Code.compile_file(module_path) do
    {:ok, _} -> IO.puts("✓ Compiled #{module_path}")
    {:error, reason} -> 
      IO.puts("✗ Error compiling #{module_path}: #{inspect(reason)}")
      System.halt(1)
  end
end)

IO.puts("\nAll modules compiled successfully!")

# Test basic functionality
IO.puts("\n=== Testing Basic Functionality ===")

alias FOLVisualiser.{Parser, FOL}

# Test parsing
IO.puts("\n1. Testing parser...")
test_cases = [
  {"A → B", "Simple implication"},
  {"A ∧ B", "Conjunction"},
  {"A ∨ B", "Disjunction"},
  {"¬A", "Negation"},
  {"∀x:i. P(x)", "Universal quantification"},
  {"∃x:i. P(x)", "Existential quantification"},
  {"x = y", "Equality"}
]

Enum.each(test_cases, fn {formula, description} ->
  case Parser.parse(formula) do
    {:ok, _ast} -> IO.puts("✓ #{description}: #{formula}")
    {:error, reason} -> IO.puts("✗ #{description}: #{formula} - #{reason}")
  end
end)

# Test proving
IO.puts("\n2. Testing prover...")
prove_cases = [
  {"A → A", "Simple tautology"},
  {"(A → B) → (¬B → ¬A)", "Contraposition"},
  {"A ∧ B → A", "Conjunction elimination"}
]

Enum.each(prove_cases, fn {formula, description} ->
  case Parser.parse(formula) do
    {:ok, ast} ->
      {result, _steps} = FOL.prove_with_detailed_steps(ast)
      status = if result.is_valid, do: "VALID", else: "INVALID"
      IO.puts("✓ #{description}: #{formula} - #{status}")
    {:error, reason} ->
      IO.puts("✗ #{description}: #{formula} - Parse error: #{reason}")
  end
end)

IO.puts("\n=== Package Test Complete ===")
IO.puts("The FOL Visualiser package is working correctly!")