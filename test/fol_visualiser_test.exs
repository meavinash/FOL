defmodule FOLVisualiserTest do
  use ExUnit.Case
  doctest FOLVisualiser

  alias FOLVisualiser.{Parser, FOL}

  test "parses simple implication" do
    assert {:ok, {:imp, {:const, :A, :o}, {:const, :B, :o}}} = 
           Parser.parse("A → B")
  end

  test "parses conjunction" do
    assert {:ok, {:and, {:const, :A, :o}, {:const, :B, :o}}} = 
           Parser.parse("A ∧ B")
  end

  test "parses disjunction" do
    assert {:ok, {:or, {:const, :A, :o}, {:const, :B, :o}}} = 
           Parser.parse("A ∨ B")
  end

  test "parses negation" do
    assert {:ok, {:not, {:const, :A, :o}}} = 
           Parser.parse("¬A")
  end

  test "parses universal quantification" do
    assert {:ok, {:forall, :x, :i, {:app, {:const, :P, {:arrow, :i, :o}}, {:var, :x, :i}}}} = 
           Parser.parse("∀x:i. P(x)")
  end

  test "parses existential quantification" do
    assert {:ok, {:exists, :x, :i, {:app, {:const, :P, {:arrow, :i, :o}}, {:var, :x, :i}}}} = 
           Parser.parse("∃x:i. P(x)")
  end

  test "parses equality" do
    assert {:ok, {:equals, {:var, :x, :i}, {:var, :y, :i}}} = 
           Parser.parse("x = y")
  end

  test "proves simple tautology" do
    formula = "A → A"
    {:ok, ast} = Parser.parse(formula)
    {result, _steps} = FOL.prove_with_detailed_steps(ast)
    assert result.is_valid
  end

  test "proves modus ponens" do
    formula = "(A → B) → (A → B)"
    {:ok, ast} = Parser.parse(formula)
    {result, _steps} = FOL.prove_with_detailed_steps(ast)
    assert result.is_valid
  end

  test "formats FOL terms correctly" do
    term = {:imp, {:const, :A, :o}, {:const, :B, :o}}
    assert FOL.format_fol_term(term) == "(A → B)"
    
    term = {:and, {:const, :A, :o}, {:const, :B, :o}}
    assert FOL.format_fol_term(term) == "(A ∧ B)"
    
    term = {:forall, :x, :i, {:app, {:const, :P, {:arrow, :i, :o}}, {:var, :x, :i}}}
    assert FOL.format_fol_term(term) == "∀x:i.(P(x))"
  end

  test "handles parse errors gracefully" do
    assert {:error, _reason} = Parser.parse("invalid formula")
    assert {:error, _reason} = Parser.parse("")
  end

  test "negates terms correctly" do
    term = {:const, :A, :o}
    negated = FOL.negate_term(term)
    assert negated == {:not, {:const, :A, :o}}
    
    term = {:not, {:const, :A, :o}}
    negated = FOL.negate_term(term)
    assert negated == {:const, :A, :o}
  end
end