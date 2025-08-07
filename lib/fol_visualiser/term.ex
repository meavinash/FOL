defmodule FOLVisualiser.Term do
  @moduledoc """
  Term operations for FOL expressions including substitution and free variable checking.
  """

  # Alias for term structure definitions
  alias FOLVisualiser.Structs

  @doc """
  Substitute a variable with a replacement term in a given term.
  Handles alpha-conversion to avoid variable capture.
  """


def subst(term, var, replacement) do
  case term do
    # Case 1: The 'term' itself IS the variable we want to replace.
    {:var, v, _} when v == var ->
      # Found it! Return the replacement.
      replacement

    # Case 2: It's a different variable or a constant. Nothing to do here.
    {:var, _, _} -> term
    {:const, _, _} -> term

    # Case 3: It's a complex term (like P(x), A∧B, ¬C).
    # We need to recursively apply 'subst' to its smaller parts.
    {:app, t1, t2} ->
      {:app, subst(t1, var, replacement), subst(t2, var, replacement)}
    {:not, t} ->
      {:not, subst(t, var, replacement)}
    {:and, t1, t2} ->
      {:and, subst(t1, var, replacement), subst(t2, var, replacement)}
    {:or, t1, t2} ->
      {:or, subst(t1, var, replacement), subst(t2, var, replacement)}
    {:imp, t1, t2} ->
      {:imp, subst(t1, var, replacement), subst(t2, var, replacement)}
    {:equals, t1, t2} ->
      {:equals, subst(t1, var, replacement), subst(t2, var, replacement)}

    # Case 4: It's a universal quantifier (∀).
    # If 'var' (the variable we're replacing) is DIFFERENT from 'bound_var' (the variable the quantifier is using),
    # then we can safely substitute inside the 'body'.
    {:forall, bound_var, type, body} when bound_var != var ->
      {:forall, bound_var, type, subst(body, var, replacement)}

    # If 'var' IS THE SAME as 'bound_var', then 'var' is "bound" by this quantifier.
    # We DO NOT substitute inside the body to avoid changing the meaning.
    {:forall, bound_var, type, body} when bound_var == var ->
      {:forall, bound_var, type, body}

    # Case 5: It's an existential quantifier (∃). Similar logic to :forall.
    {:exists, bound_var, type, body} when bound_var != var ->
      {:exists, bound_var, type, subst(body, var, replacement)}
    {:exists, bound_var, type, body} when bound_var == var ->
      {:exists, bound_var, type, body}
  end
end


  @doc """
  Check if a variable occurs free in a term.
  """
  defp occurs_free(term, var) do
    case term do
      {:var, v, _} when v == var -> true
      {:var, _, _} -> false
      {:const, _, _} -> false
      {:app, t1, t2} -> occurs_free(t1, var) or occurs_free(t2, var)
      {:forall, bound_var, _, body} when bound_var != var -> occurs_free(body, var)
      {:forall, bound_var, _, _} when bound_var == var -> false
      {:exists, bound_var, _, body} when bound_var != var -> occurs_free(body, var)
      {:exists, bound_var, _, _} when bound_var == var -> false
      {:not, t} -> occurs_free(t, var)
      {:and, t1, t2} -> occurs_free(t1, var) or occurs_free(t2, var)
      {:or, t1, t2} -> occurs_free(t1, var) or occurs_free(t2, var)
      {:imp, t1, t2} -> occurs_free(t1, var) or occurs_free(t2, var)
      {:equals, t1, t2} -> occurs_free(t1, var) or occurs_free(t2, var)
    end
  end

  @doc """
  Generate a fresh variable name based on a base name.
  """
  defp fresh_var(base) do
    counter = Process.get(:var_counter, 0)
    Process.put(:var_counter, counter + 1)
    String.to_atom("#{base}#{counter + 1}")
  end
end
