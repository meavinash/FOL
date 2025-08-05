defmodule FOLVisualiser.Unification do
  @moduledoc """
  Basic unification algorithm for FOL terms.
  """

  @doc """
  Attempt to unify two terms.
  Returns {:ok, substitution} or :error if unification fails.
  """
  def unify(term1, term2, substitution \\ %{}) do
    case {apply_substitution(term1, substitution), apply_substitution(term2, substitution)} do
      {t, t} -> {:ok, substitution}
      {{:var, var1}, t2} -> unify_var(var1, t2, substitution)
      {t1, {:var, var2}} -> unify_var(var2, t1, substitution)
      {{:atom, a1}, {:atom, a2}} when a1 == a2 -> {:ok, substitution}
      {{:function, f1, args1}, {:function, f2, args2}} when f1 == f2 and length(args1) == length(args2) ->
        unify_lists(args1, args2, substitution)
      {{:predicate, p1, args1}, {:predicate, p2, args2}} when p1 == p2 and length(args1) == length(args2) ->
        unify_lists(args1, args2, substitution)
      {{:not, t1}, {:not, t2}} -> unify(t1, t2, substitution)
      {{:and, t1_1, t1_2}, {:and, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end
      {{:or, t1_1, t1_2}, {:or, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end
      {{:implies, t1_1, t1_2}, {:implies, t2_1, t2_2}} ->
        case unify(t1_1, t2_1, substitution) do
          {:ok, subst1} -> unify(t1_2, t2_2, subst1)
          :error -> :error
        end
      _ -> :error
    end
  end

  defp unify_var(var, term, substitution) do
    case term do
      {:var, ^var} -> {:ok, substitution}
      _ ->
        if occurs_in(var, term) do
          :error  # Occurs check fails
        else
          {:ok, Map.put(substitution, var, term)}
        end
    end
  end

  defp unify_lists([], [], substitution), do: {:ok, substitution}
  defp unify_lists([h1 | t1], [h2 | t2], substitution) do
    case unify(h1, h2, substitution) do
      {:ok, subst1} -> unify_lists(t1, t2, subst1)
      :error -> :error
    end
  end
  defp unify_lists(_, _, _), do: :error

  defp apply_substitution(term, substitution) do
    case term do
      {:var, var} ->
        case Map.get(substitution, var) do
          nil -> term
          replacement -> apply_substitution(replacement, substitution)
        end
      {:function, f, args} ->
        {:function, f, Enum.map(args, &apply_substitution(&1, substitution))}
      {:predicate, p, args} ->
        {:predicate, p, Enum.map(args, &apply_substitution(&1, substitution))}
      {:not, t} ->
        {:not, apply_substitution(t, substitution)}
      {:and, t1, t2} ->
        {:and, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}
      {:or, t1, t2} ->
        {:or, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}
      {:implies, t1, t2} ->
        {:implies, apply_substitution(t1, substitution), apply_substitution(t2, substitution)}
      _ -> term
    end
  end

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