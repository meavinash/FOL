defmodule FOLVisualiser.UnificationAdapter do
  @moduledoc """
  Adapter to convert between FOL terms and Unification module terms.

  This module lets you translate terms between your internal FOL (first-order logic) representation
  and whatever term structure your unification library expects. 
  It also lets you take a substitution result from the unification library and safely apply it back to your FOL terms.
  """

  #-------------------------
  # Conversion: FOL -> Unification
  #-------------------------

  @doc """
  Convert FOL term to Unification module format.

  This function walks your FOL term (which may contain type info, function apps, etc.)
  and builds the equivalent unification term, which may be a var, atom, function, predicate, etc.
  """
  def to_unification_term(term) do
    case term do
      # Variable: Drop type info, just use the name.
      {:var, name, _} -> {:var, name}

      # Constant: Convert to atom, and use string representation for the unification module.
      {:const, name, _} -> {:atom, Atom.to_string(name)}

      # Application: 
      # If the function part is just an atom (i.e., a function symbol), represent as {:function, name, [arg]}.
      # Otherwise, treat as generic application using "app" as function name and both parts as arguments.
      {:app, f, x} -> 
        f_conv = to_unification_term(f)
        x_conv = to_unification_term(x)
        case f_conv do
          {:atom, name} -> {:function, name, [x_conv]}
          _ -> {:function, "app", [f_conv, x_conv]}
        end

      # Equality: Represent as a predicate with "=" as the name and both sides as arguments.
      {:equals, t1, t2} -> 
        {:predicate, "=", [to_unification_term(t1), to_unification_term(t2)]}

      # Negation: Recursively convert the subterm.
      {:not, t} -> 
        {:not, to_unification_term(t)}

      # Conjunction: Convert both sides.
      {:and, t1, t2} -> 
        {:and, to_unification_term(t1), to_unification_term(t2)}

      # Disjunction: Convert both sides.
      {:or, t1, t2} -> 
        {:or, to_unification_term(t1), to_unification_term(t2)}

      # Implication: Convert both sides.
      {:imp, t1, t2} -> 
        {:implies, to_unification_term(t1), to_unification_term(t2)}

      # Anything else: Just return as is (could be extended for more term types).
      _ -> term
    end
  end

  #-------------------------
  # Conversion: Unification -> FOL
  #-------------------------

  @doc """
  Convert Unification module term back to FOL term.

  Walks the structure of a unification term and rebuilds your FOL representation.
  Type information is restored with a default when missing.
  """
  def from_unification_term(term) do
    case term do
      # Variable: Add a default type (:i, usually "individual")
      {:var, name} -> {:var, name, :i}

      # Atom (constant): Convert string back to atom and add type info.
      {:atom, name} -> {:const, String.to_atom(name), :i}

      # Function: Map arguments recursively, wrap as application.
      # Only uses the first argument, which assumes unary functions here.
      {:function, name, args} -> 
        conv_args = Enum.map(args, &from_unification_term/1)
        # {:const, name, {:arrow, :i, :i}} means a function from individuals to individuals
        {:app, {:const, String.to_atom(name), {:arrow, :i, :i}}, hd(conv_args)}

      # Predicate: Map arguments recursively.
      # If "=" treat as equality, otherwise treat as function application to boolean type.
      {:predicate, name, args} -> 
        conv_args = Enum.map(args, &from_unification_term/1)
        if name == "=" do
          {:equals, hd(conv_args), hd(tl(conv_args))}
        else
          # {:arrow, :i, :o} means function from individuals to booleans
          {:app, {:const, String.to_atom(name), {:arrow, :i, :o}}, hd(conv_args)}
        end

      # Negation: Recursively convert subterm.
      {:not, t} -> 
        {:not, from_unification_term(t)}

      # Conjunction: Recursively convert both sides.
      {:and, t1, t2} -> 
        {:and, from_unification_term(t1), from_unification_term(t2)}

      # Disjunction: Recursively convert both sides.
      {:or, t1, t2} -> 
        {:or, from_unification_term(t1), from_unification_term(t2)}

      # Implication: Recursively convert both sides.
      {:implies, t1, t2} -> 
        {:imp, from_unification_term(t1), from_unification_term(t2)}

      # Anything else: Return unchanged.
      _ -> term
    end
  end

  #-------------------------
  # Applying Substitution
  #-------------------------

  @doc """
  Apply substitution from Unification module to FOL term.

  - First converts the substitution (from unification term format) into FOL format.
  - Then walks the FOL term, replacing free variables with their substitution if present.
  - Bound variables (those inside a quantifier) are not substituted (standard capture-avoidance).
  """
  def apply_unification_substitution(term, substitution) do
    # Convert substitution to FOL format.
    # substitution is assumed to be a map: %{var_name => unification_term}
    fol_subst = Map.new(substitution, fn {var, value} ->
      {var, from_unification_term(value)}
    end)
    
    # Now, recursively walk the FOL term, applying substitution.
    case term do
      # Variable: If it’s in the substitution, replace it. Otherwise, keep it.
      {:var, name, type} ->
        case Map.get(fol_subst, name) do
          nil -> term
          new_term -> new_term
        end

      # Application: Substitute in both function and argument.
      {:app, f, x} ->
        {:app, apply_unification_substitution(f, fol_subst), 
               apply_unification_substitution(x, fol_subst)}

      # Universal quantifier: If the bound variable is in the substitution, don't substitute inside.
      {:forall, var, type, body} ->
        if Map.has_key?(fol_subst, var) do
          term  # skip substitution under bound variable
        else
          {:forall, var, type, apply_unification_substitution(body, fol_subst)}
        end

      # Existential quantifier: Same as above for exists.
      {:exists, var, type, body} ->
        if Map.has_key?(fol_subst, var) do
          term  # skip substitution under bound variable
        else
          {:exists, var, type, apply_unification_substitution(body, fol_subst)}
        end

      # Negation: Substitute recursively.
      {:not, t} -> 
        {:not, apply_unification_substitution(t, fol_subst)}

      # Conjunction: Substitute recursively in both sides.
      {:and, t1, t2} -> 
        {:and, apply_unification_substitution(t1, fol_subst), 
               apply_unification_substitution(t2, fol_subst)}

      # Disjunction: Substitute recursively in both sides.
      {:or, t1, t2} -> 
        {:or, apply_unification_substitution(t1, fol_subst), 
              apply_unification_substitution(t2, fol_subst)}

      # Implication: Substitute recursively in both sides.
      {:imp, t1, t2} -> 
        {:imp, apply_unification_substitution(t1, fol_subst), 
              apply_unification_substitution(t2, fol_subst)}

      # Equality: Substitute recursively in both sides.
      {:equals, t1, t2} -> 
        {:equals, apply_unification_substitution(t1, fol_subst), 
                  apply_unification_substitution(t2, fol_subst)}

      # Any other term: Leave unchanged.
      _ -> term
    end
  end
end
