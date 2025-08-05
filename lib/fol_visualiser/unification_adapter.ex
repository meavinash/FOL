defmodule FOLVisualiser.UnificationAdapter do
  @moduledoc """
  Adapter to convert between FOL terms and Unification module terms.
  """

  @doc """
  Convert FOL term to Unification module format.
  """
  def to_unification_term(term) do
    case term do
      {:var, name, _} -> {:var, name}
      {:const, name, _} -> {:atom, Atom.to_string(name)}
      {:app, f, x} -> 
        f_conv = to_unification_term(f)
        x_conv = to_unification_term(x)
        case f_conv do
          {:atom, name} -> {:function, name, [x_conv]}
          _ -> {:function, "app", [f_conv, x_conv]}
        end
      {:equals, t1, t2} -> 
        {:predicate, "=", [to_unification_term(t1), to_unification_term(t2)]}
      {:not, t} -> 
        {:not, to_unification_term(t)}
      {:and, t1, t2} -> 
        {:and, to_unification_term(t1), to_unification_term(t2)}
      {:or, t1, t2} -> 
        {:or, to_unification_term(t1), to_unification_term(t2)}
      {:imp, t1, t2} -> 
        {:implies, to_unification_term(t1), to_unification_term(t2)}
      _ -> term
    end
  end
  
  @doc """
  Convert Unification module term back to FOL term.
  """
  def from_unification_term(term) do
    case term do
      {:var, name} -> {:var, name, :i}
      {:atom, name} -> {:const, String.to_atom(name), :i}
      {:function, name, args} -> 
        conv_args = Enum.map(args, &from_unification_term/1)
        {:app, {:const, String.to_atom(name), {:arrow, :i, :i}}, hd(conv_args)}
      {:predicate, name, args} -> 
        conv_args = Enum.map(args, &from_unification_term/1)
        if name == "=" do
          {:equals, hd(conv_args), hd(tl(conv_args))}
        else
          {:app, {:const, String.to_atom(name), {:arrow, :i, :o}}, hd(conv_args)}
        end
      {:not, t} -> 
        {:not, from_unification_term(t)}
      {:and, t1, t2} -> 
        {:and, from_unification_term(t1), from_unification_term(t2)}
      {:or, t1, t2} -> 
        {:or, from_unification_term(t1), from_unification_term(t2)}
      {:implies, t1, t2} -> 
        {:imp, from_unification_term(t1), from_unification_term(t2)}
      _ -> term
    end
  end
  
  @doc """
  Apply substitution from Unification module to FOL term.
  """
  def apply_unification_substitution(term, substitution) do
    # Convert substitution to FOL format
    fol_subst = Map.new(substitution, fn {var, value} ->
      {var, from_unification_term(value)}
    end)
    
    # Apply substitution to term
    case term do
      {:var, name, type} ->
        case Map.get(fol_subst, name) do
          nil -> term
          new_term -> new_term
        end
      {:app, f, x} ->
        {:app, apply_unification_substitution(f, fol_subst), 
               apply_unification_substitution(x, fol_subst)}
      {:forall, var, type, body} ->
        if Map.has_key?(fol_subst, var) do
          term  # Don't substitute bound variables
        else
          {:forall, var, type, apply_unification_substitution(body, fol_subst)}
        end
      {:exists, var, type, body} ->
        if Map.has_key?(fol_subst, var) do
          term  # Don't substitute bound variables
        else
          {:exists, var, type, apply_unification_substitution(body, fol_subst)}
        end
      {:not, t} -> 
        {:not, apply_unification_substitution(t, fol_subst)}
      {:and, t1, t2} -> 
        {:and, apply_unification_substitution(t1, fol_subst), 
               apply_unification_substitution(t2, fol_subst)}
      {:or, t1, t2} -> 
        {:or, apply_unification_substitution(t1, fol_subst), 
              apply_unification_substitution(t2, fol_subst)}
      {:imp, t1, t2} -> 
        {:imp, apply_unification_substitution(t1, fol_subst), 
              apply_unification_substitution(t2, fol_subst)}
      {:equals, t1, t2} -> 
        {:equals, apply_unification_substitution(t1, fol_subst), 
                  apply_unification_substitution(t2, fol_subst)}
      _ -> term
    end
  end
end
