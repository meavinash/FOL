defmodule FOLVisualiser.Unification do
  @moduledoc """
  Basic unification algorithm for FOL (First-Order Logic) terms.
  """

  @doc """
  Attempt to unify two terms.
  Returns {:ok, substitution} if successful, or :error if unification fails.

  Example:
    unify(term1, term2)
    # => {:ok, %{...}} or :error
  """
  def unify(term1, term2, substitution \\ %{}) do
    # Always apply current substitutions to both terms first.
    case {apply_substitution(term1, substitution), apply_substitution(term2, substitution)} do

      # Case 1: Terms are identical after substitution.
      {t, t} -> {:ok, substitution}

      # Case 2: One term is a variable, try to unify variable with the other term.
      {{:var, var1}, t2} -> unify_var(var1, t2, substitution)
      {t1, {:var, var2}} -> unify_var(var2, t1, substitution)

      # Case 3: Both are atoms (constants); they unify only if identical.
      {{:atom, a1}, {:atom, a2}} when a1 == a2 -> {:ok, substitution}

      # Case 4: Both are functions (like f(x, y)); functors and arity must match.
      {{:function, f1, args1}, {:function, f2, args2}} when f1 == f2 and length(args1) == length(args2) ->
        unify_lists(args1, args2, substitution)

      # Case 5: Both are predicates; predicate symbols and arity must match.
      {{:predicate, p1, args1}, {:predicate, p2, args2}} when p1 == p2 and length(args1) == length(args2) ->
        unify_lists(args1, args2, substitution)

      # Case 6: Both are negations (¬A).
      {{:not, t1}, {:not, t2}} ->
        unify(t1, t2, substitution)

      # Case 7: Both are conjunctions (A ∧ B).
      {{:and, t1_1, t1_2}, {:and, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end

      # Case 8: Both are disjunctions (A ∨ B).
      {{:or, t1_1, t1_2}, {:or, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end

      # Case 9: Both are implications (A ⇒ B).
      {{:implies, t1_1, t1_2}, {:implies, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end

      # Case 10: Anything else—cannot be unified.
      _ -> :error
    end
  end

  # Unifies a variable with a term, updating the substitution map if valid.
  defp unify_var(var, term, substitution) do
    case term do
      # Unifying a variable with itself does nothing.
      {:var, ^var} -> {:ok, substitution}
      _ ->
        # Check for occurs-check: variable must not appear inside term (avoids cycles).
        if occurs_in(var, term) do
          :error
        else
          # Add (or overwrite) the substitution for var.
          {:ok, Map.put(substitution, var, term)}
        end
    end
  end

  # Helper to recursively unify two lists of terms (e.g., function/predicate arguments).
  defp unify_lists([], [], substitution), do: {:ok, substitution}
  defp unify_lists([h1 | t1], [h2 | t2], substitution) do
    case unify(h1, h2, substitution) do
      {:ok, subst1} -> unify_lists(t1, t2, subst1)
      :error -> :error
    end
  end
  defp unify_lists(_, _, _), do: :error # Different arity: cannot unify.

  # Applies all substitutions in the map to the term (recursively).
  defp apply_substitution(term, substitution) do
    case term do
      # If it's a variable, check if we have a substitution for it.
      {:var, var} ->
        case Map.get(substitution, var) do
          nil -> term
          replacement -> apply_substitution(replacement, substitution)
        end

      # Recursively apply substitution to function arguments.
      {:function, f, args} ->
        {:function, f, Enum.map(args, &apply_substitution(&1, substitution))}

      # Recursively apply substitution to predicate arguments.
      {:predicate, p, args} ->
        {:predicate, p, Enum.map(args, &apply_substitution(&1, substitution))}

      # Recursively apply substitution to logical connectives.
      {:not, t} ->
        {:not, apply_substitution(t, substitution)}

      {:and, t1, t2} ->
        {:and, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}

      {:or, t1, t2} ->
        {:or, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}

      {:implies, t1, t2} ->
        {:implies, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}

      # Atoms and any other base terms are unchanged.
      _ -> term
    end
  end

  # Checks if a variable occurs inside a term (to prevent cyclic substitutions).
  defp occurs_in(var, term) do
    case term do
      {:var, ^var} -> true
      {:var, _} -> false
      {:function, _, args} -> Enum.any?(args, &occurs_in(var, &1))
      {:predicate, _, args} -> Enum.any?(args, &occurs_in(var, &1))
      {:not, t} -> occurs_in(var, t)
      {:and, t1, t2} -> occurs_in(var, t1) or occurs_in(var, t2)
      {:or, t1, t2} -> occurs_in(var, t1) or occurs_in(var, t2)
      {:implies, t1, t2} -> occurs_in(var, t1) or occurs_in(var, t2)
      _ -> false
    end
  end
end
