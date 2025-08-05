defmodule FOLVisualiser.Term do
  @moduledoc """
  Term operations for FOL expressions including substitution and free variable checking.
  """

  alias FOLVisualiser.Structs

  @doc """
  Substitute a variable with a replacement term in a given term.
  Handles alpha-conversion to avoid variable capture.
  """
  def subst(term, var, replacement) do
    case term do
      {:var, v, _} when v == var -> replacement
      {:var, _, _} -> term
      {:const, _, _} -> term
      {:app, t1, t2} ->
        {:app, subst(t1, var, replacement), subst(t2, var, replacement)}
      {:forall, bound_var, type, body} when bound_var != var ->
        {:forall, bound_var, type, subst(body, var, replacement)}
      {:forall, bound_var, type, body} when bound_var == var ->
        {:forall, bound_var, type, body}
      {:exists, bound_var, type, body} when bound_var != var ->
        {:exists, bound_var, type, subst(body, var, replacement)}
      {:exists, bound_var, type, body} when bound_var == var ->
        {:exists, bound_var, type, body}
      {:not, t} -> {:not, subst(t, var, replacement)}
      {:and, t1, t2} -> {:and, subst(t1, var, replacement), subst(t2, var, replacement)}
      {:or, t1, t2} -> {:or, subst(t1, var, replacement), subst(t2, var, replacement)}
      {:imp, t1, t2} -> {:imp, subst(t1, var, replacement), subst(t2, var, replacement)}
      {:equals, t1, t2} -> {:equals, subst(t1, var, replacement), subst(t2, var, replacement)}
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
