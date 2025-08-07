defmodule FOLVisualiser.FOL do
  @moduledoc """
  FOL Tableau Prover implementation.
  
  Implements the semantic tableau method for automated theorem proving.
  """

  # Aliases for FOL term structures, term operations, and unification logic
  alias FOLVisualiser.Structs
  alias FOLVisualiser.Term
  alias FOLVisualiser.UnificationAdapter    # To help with comparing terms
  alias FOLVisualiser.Unification            # The actual unification system

  @max_steps 50

  @doc """
  Prove a goal term with detailed step tracking.
  Returns {result_map, detailed_steps_list}
  """
  def prove_with_detailed_steps(goal_term) do
      # Step 1: Negate the original formula. We try to find a contradiction in its negation.
 
    negated_goal = negate_term(goal_term)
    
    # Step 2: Create the very first node of our proof tree (the "root").
    # This node contains our initial assumption (the negated goal).

    root = %Structs.TableauNode{           # Creating the very first TableauNode (the root of our proof tree)

      formulas: [negated_goal], 
      id: 0, 
      step: 0, 
      branch_path: ["root"],
      instantiations: [],
      node_type: :open,
      original_formula: goal_term,
      rule_description: "Negate goal for contradiction"
    }

        # Step 3: Initialize the overall state of the tableau prover.


    # Creating the overall TableauState to manage the proof

    state = %Structs.TableauState{
      root: root,                # The state knows about the root node
      node_counter: 1,           # Next ID will be 1
      witness_counter: 0,
      steps: []                  # No steps yet
    }
    
        # Step 4: Start the recursive expansion of the tableau tree.


    {final_state, detailed_steps} = expand_tableau_with_correct_steps(state)

  
    # Step 5: After expansion, classify all nodes (open, closed, intermediate).

    
    final_root = classify_all_nodes(final_state.root)

        # Step 6: Collect all final leaf branches to determine overall validity.

    {closed, open} = collect_leaf_branches(final_root)
    
        # Step 7: Prepare the final result.

    result = %{
      closed_branches: closed, 
      open_branches: open,
      is_valid: length(open) == 0,
      total_branches: length(closed) + length(open),
      tree_root: final_root
    }
    
    {result, detailed_steps}
  end

  defp expand_tableau_with_correct_steps(state) do
    expand_tableau_rec(state, 1, [])
  end

  # This function drives the recursive expansion of the tableau.

  defp expand_tableau_rec(state, step_num, steps_acc) do
    cond do

          # Safeguard: Stop if we've taken too many steps (prevents infinite loops).

      step_num > @max_steps -> 
        {state, Enum.reverse(steps_acc)}
       
       # Find a node in the tree that still has formulas to expand.
        # This function intelligently picks the next formula to work on.

      true ->
        case find_next_expandable_node(state.root) do
          nil ->       # No more formulas to expand anywhere in the tree.

            {state, Enum.reverse(steps_acc)}
          
          {node, formula} ->

          # Apply the appropriate tableau rule to the chosen formula.
            # This is where the tree branches or extends.

            {new_state, step} = apply_rule_with_enhanced_tracking(formula, node, state, step_num)

            # Recursively call itself to continue the expansion with the updated state.

            expand_tableau_rec(new_state, step_num + 1, [step | steps_acc])
        end
    end
  end

  defp apply_rule_with_enhanced_tracking(formula, node, state, step_num) do
    case formula do
      {:not, {:imp, f1, f2}} ->
        apply_alpha_rule_enhanced(formula, [f1, {:not, f2}], node, state, step_num, 
          "¬→ decomposition", "Negated implication: ¬(A→B) becomes A∧¬B")
      
      {:and, f1, f2} ->
        apply_alpha_rule_enhanced(formula, [f1, f2], node, state, step_num, 
          "∧ decomposition", "Conjunction: A∧B becomes A, B")
      
      {:not, {:or, f1, f2}} ->
        apply_alpha_rule_enhanced(formula, [{:not, f1}, {:not, f2}], node, state, step_num, 
          "¬∨ decomposition", "De Morgan's law: ¬(A∨B) becomes ¬A∧¬B")
      
      {:not, {:not, f}} ->
        apply_alpha_rule_enhanced(formula, [f], node, state, step_num, 
          "¬¬ elimination", "Double negation: ¬¬A becomes A")
          
      {:imp, f1, f2} ->
        apply_beta_rule_enhanced(formula, [{:not, f1}, f2], node, state, step_num, 
          "→ branching", "Implication: A→B becomes ¬A∨B (branches)")
      
      {:or, f1, f2} ->
        apply_beta_rule_enhanced(formula, [f1, f2], node, state, step_num, 
          "∨ branching", "Disjunction: A∨B creates two branches")
      
      {:not, {:and, f1, f2}} ->
        apply_beta_rule_enhanced(formula, [{:not, f1}, {:not, f2}], node, state, step_num, 
          "¬∧ branching", "De Morgan's law: ¬(A∧B) becomes ¬A∨¬B (branches)")
          
      {:forall, var, type, body} ->
        apply_gamma_rule_enhanced(formula, var, type, body, node, state, step_num, 
          "∀ elimination", "Universal: ∀x P(x) instantiated to P(c)")
      
      {:not, {:exists, var, type, body}} ->
        apply_gamma_rule_enhanced(formula, var, type, {:not, body}, node, state, step_num, 
          "¬∃ elimination", "Negated existential: ¬∃x P(x) becomes ∀x ¬P(x)")
          
      {:exists, var, type, body} ->
        apply_delta_rule_enhanced(formula, var, type, body, node, state, step_num, 
          "∃ elimination", "Existential: ∃x P(x) instantiated to P(c)")
      
      {:not, {:forall, var, type, body}} ->
        apply_delta_rule_enhanced(formula, var, type, {:not, body}, node, state, step_num, 
          "¬∀ elimination", "Negated universal: ¬∀x P(x) becomes ∃x ¬P(x)")
          
      _ ->
        step = create_step_enhanced(step_num, "no-op", node.formulas, node.formulas, 
          node.branch_path, [], formula, "No applicable rule")
        {state, step}
    end
  end

  defp apply_alpha_rule_enhanced(target_formula, new_formulas, parent_node, state, step_num, rule_name, rule_desc) do
    remaining_formulas = List.delete(parent_node.formulas, target_formula)
    updated_formulas = new_formulas ++ remaining_formulas
    
    {is_closed, closure_reason} = check_closure_comprehensive(updated_formulas)
    
    if is_closed do
      closed_node = %{parent_node | 
        formulas: updated_formulas,
        rule: rule_name,
        rule_description: rule_desc,
        closed: true,
        closure_reason: closure_reason,
        node_type: :closed,
        original_formula: target_formula,
        step: step_num
      }
      
      new_root = replace_node_in_tree(state.root, parent_node, closed_node)
      new_state = %{state | root: new_root}
      
      step = create_step_enhanced(step_num, rule_name, parent_node.formulas, updated_formulas, 
                                parent_node.branch_path, [], target_formula, rule_desc)
      
      {new_state, step}
    else
      child_node = %Structs.TableauNode{
        formulas: updated_formulas,
        id: state.node_counter,
        rule: nil,
        branch_path: parent_node.branch_path,
        instantiations: parent_node.instantiations,
        closed: false,
        node_type: :open,
        original_formula: target_formula,
        step: step_num
      }
      
      updated_parent = %{parent_node | 
        children: [child_node],
        formulas: [],
        rule: rule_name,
        rule_description: rule_desc,
        node_type: :intermediate,
        original_formula: target_formula,
        step: step_num
      }
      
      new_root = replace_node_in_tree(state.root, parent_node, updated_parent)
      new_state = %{state | root: new_root, node_counter: state.node_counter + 1}
      
      step = create_step_enhanced(step_num, rule_name, parent_node.formulas, updated_formulas, 
                                parent_node.branch_path, [], target_formula, rule_desc)
      
      {new_state, step}
    end
  end

  defp apply_beta_rule_enhanced(target_formula, branch_formulas, parent_node, state, step_num, rule_name, rule_desc) do
    [left_formula, right_formula] = branch_formulas
    remaining_formulas = List.delete(parent_node.formulas, target_formula)
    
    left_formulas = [left_formula | remaining_formulas]
    {left_closed, left_reason} = check_closure_comprehensive(left_formulas)
    
    left_child = %Structs.TableauNode{
      formulas: left_formulas,
      id: state.node_counter,
      branch_path: parent_node.branch_path ++ ["left"],
      instantiations: parent_node.instantiations,
      closed: left_closed,
      closure_reason: left_reason,
      node_type: if(left_closed, do: :closed, else: :open),
      original_formula: target_formula,
      rule: if(left_closed, do: "Closure", else: nil),
      rule_description: if(left_closed, do: "Contradiction found", else: nil),
      step: step_num
    }
    
    right_formulas = [right_formula | remaining_formulas]
    {right_closed, right_reason} = check_closure_comprehensive(right_formulas)
    
    right_child = %Structs.TableauNode{
      formulas: right_formulas,
      id: state.node_counter + 1,
      branch_path: parent_node.branch_path ++ ["right"],
      instantiations: parent_node.instantiations,
      closed: right_closed,
      closure_reason: right_reason,
      node_type: if(right_closed, do: :closed, else: :open),
      original_formula: target_formula,
      rule: if(right_closed, do: "Closure", else: nil),
      rule_description: if(right_closed, do: "Contradiction found", else: nil),
      step: step_num
    }
    
    updated_parent = %{parent_node | 
      children: [left_child, right_child],
      formulas: [],
      rule: rule_name,
      rule_description: rule_desc,
      node_type: :intermediate,
      original_formula: target_formula,
      step: step_num
    }
    
    new_root = replace_node_in_tree(state.root, parent_node, updated_parent)
    new_state = %{state | root: new_root, node_counter: state.node_counter + 2}
    
    step = create_step_enhanced(step_num, rule_name, parent_node.formulas, 
      "Left: #{format_formulas(left_formulas)} | Right: #{format_formulas(right_formulas)}", 
      parent_node.branch_path, [], target_formula, rule_desc)
    
    {new_state, step}
  end

  defp apply_gamma_rule_enhanced(target_formula, var, type, body, parent_node, state, step_num, rule_name, rule_desc) do
    {const, new_state, instantiation} = get_fresh_constant(var, type, state)
    instantiated_body = Term.subst(body, var, const)
    
    remaining_formulas = List.delete(parent_node.formulas, target_formula)
    updated_formulas = case rule_name do
      "∀ elimination" -> [target_formula, instantiated_body | remaining_formulas]
      "¬∃ elimination" -> [instantiated_body | remaining_formulas]
      _ -> [instantiated_body | remaining_formulas]
    end
    
    {is_closed, closure_reason} = check_closure_comprehensive(updated_formulas)
    
    child_node = %Structs.TableauNode{
      formulas: updated_formulas,
      id: new_state.node_counter,
      rule: if(is_closed, do: "Closure", else: nil),
      rule_description: if(is_closed, do: "Contradiction found", else: nil),
      branch_path: parent_node.branch_path,
      instantiations: parent_node.instantiations ++ [instantiation],
      closed: is_closed,
      closure_reason: closure_reason,
      node_type: if(is_closed, do: :closed, else: :open),
      original_formula: target_formula,
      step: step_num
    }
    
    updated_parent = %{parent_node | 
      children: [child_node],
      formulas: [],
      rule: rule_name,
      rule_description: rule_desc,
      node_type: :intermediate,
      original_formula: target_formula,
      step: step_num
    }
    
    final_root = replace_node_in_tree(new_state.root, parent_node, updated_parent)
    final_state = %{new_state | root: final_root, node_counter: new_state.node_counter + 1}
    
    step = create_step_enhanced(step_num, rule_name, parent_node.formulas, updated_formulas, 
      parent_node.branch_path, [instantiation], target_formula, rule_desc)
    
    {final_state, step}
  end

  defp apply_delta_rule_enhanced(target_formula, var, type, body, parent_node, state, step_num, rule_name, rule_desc) do
    {const, new_state, instantiation} = get_fresh_constant(var, type, state)
    instantiated_body = Term.subst(body, var, const)
    
    remaining_formulas = List.delete(parent_node.formulas, target_formula)
    updated_formulas = [instantiated_body | remaining_formulas]
    
    {is_closed, closure_reason} = check_closure_comprehensive(updated_formulas)
    
    child_node = %Structs.TableauNode{
      formulas: updated_formulas,
      id: new_state.node_counter,
      rule: if(is_closed, do: "Closure", else: nil),
      rule_description: if(is_closed, do: "Contradiction found", else: nil),
      branch_path: parent_node.branch_path,
      instantiations: parent_node.instantiations ++ [instantiation],
      closed: is_closed,
      closure_reason: closure_reason,
      node_type: if(is_closed, do: :closed, else: :open),
      original_formula: target_formula,
      step: step_num
    }
    
    updated_parent = %{parent_node | 
      children: [child_node],
      formulas: [],
      rule: rule_name,
      rule_description: rule_desc,
      node_type: :intermediate,
      original_formula: target_formula,
      step: step_num
    }
    
    final_root = replace_node_in_tree(new_state.root, parent_node, updated_parent)
    final_state = %{new_state | root: final_root, node_counter: new_state.node_counter + 1}
    
    step = create_step_enhanced(step_num, rule_name, parent_node.formulas, updated_formulas, 
      parent_node.branch_path, [instantiation], target_formula, rule_desc)
    
    {final_state, step}
  end

  defp create_step_enhanced(step_num, rule_name, before_formulas, after_result, branch_path, instantiations, target_formula, rule_desc) do
    description = case {rule_name, target_formula} do
      {"¬→ decomposition", {:not, {:imp, f1, f2}}} ->
        "#{rule_desc}: ¬(#{format_fol_term(f1)} → #{format_fol_term(f2)}) → #{format_fol_term(f1)} ∧ ¬#{format_fol_term(f2)}"
      
      {"→ branching", {:imp, f1, f2}} ->
        "#{rule_desc}: (#{format_fol_term(f1)} → #{format_fol_term(f2)}) ≡ ¬#{format_fol_term(f1)} ∨ #{format_fol_term(f2)}"
      
      {"∧ decomposition", {:and, f1, f2}} ->
        "#{rule_desc}: (#{format_fol_term(f1)} ∧ #{format_fol_term(f2)}) → #{format_fol_term(f1)}, #{format_fol_term(f2)}"
      
      {"¬∨ decomposition", {:not, {:or, f1, f2}}} ->
        "#{rule_desc}: ¬(#{format_fol_term(f1)} ∨ #{format_fol_term(f2)}) → ¬#{format_fol_term(f1)} ∧ ¬#{format_fol_term(f2)}"
      
      {"∨ branching", {:or, f1, f2}} ->
        "#{rule_desc}: (#{format_fol_term(f1)} ∨ #{format_fol_term(f2)})"
      
      {"¬∧ branching", {:not, {:and, f1, f2}}} ->
        "#{rule_desc}: ¬(#{format_fol_term(f1)} ∧ #{format_fol_term(f2)}) → ¬#{format_fol_term(f1)} ∨ ¬#{format_fol_term(f2)}"
      
      {"¬¬ elimination", {:not, {:not, f}}} ->
        "#{rule_desc}: ¬¬#{format_fol_term(f)} → #{format_fol_term(f)}"
      
      _ ->
        rule_desc || get_rule_description(rule_name, instantiations)
    end
    
    %{
      num: step_num,
      rule: rule_name,
      description: description,
      before_state: format_formulas(before_formulas),
      after_state: format_step_result(after_result),
      branch_path: branch_path,
      instantiations: instantiations
    }
  end

  defp find_direct_contradiction(formulas) do
  # This function iterates through all pairs of formulas in a branch.
    # It checks if one formula "matches" the negation of another.
    # This often involves calling the [Unification System](06_unification_system_.md)
    # to see if a formula like `P(x)` and `¬P(a)` could be contradictory if `x` can be `a`.
    # ... simplified logic ...
    # Extract atomic formulas and their negations


    atomic_formulas = Enum.flat_map(formulas, fn 
      {:not, f} -> [{:negative, f}]
      f -> [{:positive, f}]
    end)
    
    # Try to unify positive and negative formulas
    Enum.find_value(atomic_formulas, fn 
      {:positive, pos_formula} ->
        Enum.find_value(atomic_formulas, fn 
          {:negative, neg_formula} ->
            # Convert to unification format
            pos_unif = UnificationAdapter.to_unification_term(pos_formula)
            neg_unif = UnificationAdapter.to_unification_term(neg_formula)
            
            case Unification.unify(pos_unif, neg_unif) do
              {:ok, _subst} ->
                "#{format_fol_term(pos_formula)} ∧ ¬#{format_fol_term(pos_formula)}"
              _ ->
                nil
            end
          _ -> nil
        end)
      _ -> nil
    end)
  end


# This function checks if a list of formulas contains a contradiction.

  defp check_closure_comprehensive(formulas) do

    # It looks for a formula and its negation (e.g., 'A' and '¬A')

    direct_contradiction = find_direct_contradiction(formulas)
    if direct_contradiction do
      {true, direct_contradiction}       # Yes, a contradiction was found!
    else
      {false, nil}          # No contradiction here.
    end
  end   

  defp terms_match?(t1, t2) do
    # Convert to unification format and check unification
    t1_unif = UnificationAdapter.to_unification_term(t1)
    t2_unif = UnificationAdapter.to_unification_term(t2)
    
    case Unification.unify(t1_unif, t2_unif) do
      {:ok, _} -> true
      _ -> t1 == t2
    end
  end

  # This function helps find the next formula to work on in the entire tree.

  defp find_next_expandable_node(node) do
  #    # If the node is closed, we don't need to expand it further.

    cond do
      node.closed -> 
        nil
      
    # If this node has formulas, find one to expand.
    # ... logic to prioritize which formula to expand ...

    # Otherwise, check its children.
    # ... logic to recurse into children ...

      node.formulas != [] ->
        case Enum.find(node.formulas, &expandable_formula?/1) do
          nil -> 
            find_in_children(node.children)
          formula -> 
            {node, formula}
        end
      
      true -> 
        find_in_children(node.children)
    end
  end

  defp find_in_children([]), do: nil
  defp find_in_children([child | rest]) do
    case find_next_expandable_node(child) do
      nil -> find_in_children(rest)
      result -> result
    end
  end

  defp expandable_formula?(formula) do
    case formula do
      {:not, {:not, _}} -> true
      {:and, _, _} -> true
      {:not, {:or, _, _}} -> true
      {:not, {:imp, _, _}} -> true
      {:or, _, _} -> true
      {:imp, _, _} -> true
      {:not, {:and, _, _}} -> true
      {:forall, _, _, _} -> true
      {:exists, _, _, _} -> true
      {:not, {:forall, _, _, _}} -> true
      {:not, {:exists, _, _, _}} -> true
      _ -> false
    end
  end

  defp get_fresh_constant(var, type, state) do
    case Map.get(state.var_map, var) do
      nil ->
        id = state.witness_counter + 1
        const_name = String.to_atom("c#{id}")
        const_term = {:const, const_name, type}
        instantiation = {var, const_name}
        
        new_var_map = Map.put(state.var_map, var, const_term)
        new_state = %{state | witness_counter: id, var_map: new_var_map}
        
        {const_term, new_state, instantiation}
      
      existing_const ->
        const_name = case existing_const do
          {:const, name, _} -> name
          _ -> existing_const
        end
        instantiation = {var, const_name}
        {existing_const, state, instantiation}
    end
  end

  defp replace_node_in_tree(current_node, target_node, replacement_node) do
    if current_node == target_node do
      replacement_node
    else
      new_children = Enum.map(current_node.children, &replace_node_in_tree(&1, target_node, replacement_node))
      %{current_node | children: new_children}
    end
  end

  defp classify_all_nodes(node) do
    classified_children = Enum.map(node.children, &classify_all_nodes/1)
    updated_node = %{node | children: classified_children}
    
    cond do
      updated_node.children == [] ->
        if updated_node.closed do
          %{updated_node | node_type: :closed}
        else
          %{updated_node | node_type: :open}
        end
      
      true ->
        %{updated_node | node_type: :intermediate}
    end
  end

  defp collect_leaf_branches(node) do
    if node.children == [] do
      if node.closed do
        {[node], []}
      else
        {[], [node]}
      end
    else
      Enum.reduce(node.children, {[], []}, fn child, {closed_acc, open_acc} ->
        {child_closed, child_open} = collect_leaf_branches(child)
        {closed_acc ++ child_closed, open_acc ++ child_open}
      end)
    end
  end

  defp get_rule_description(rule_name, instantiations) do
    base_desc = case rule_name do
      "¬¬ elimination" -> "Remove double negation"
      "∧ decomposition" -> "Split conjunction"
      "¬∨ decomposition" -> "De Morgan's law: ¬(A ∨ B) → ¬A ∧ ¬B"
      "¬→ decomposition" -> "Negated implication: ¬(A → B) → A ∧ ¬B"
      "∨ branching" -> "Disjunction branching"
      "→ branching" -> "Implication branching: A → B ≡ ¬A ∨ B"
      "¬∧ branching" -> "De Morgan's law: ¬(A ∧ B) → ¬A ∨ ¬B"
      "∀ elimination" -> "Universal instantiation"
      "∃ elimination" -> "Existential instantiation"
      "¬∀ elimination" -> "Negated universal: ¬∀x P(x) → ∃x ¬P(x)"
      "¬∃ elimination" -> "Negated existential: ¬∃x P(x) → ∀x ¬P(x)"
      _ -> rule_name
    end
    
    if instantiations != [] do
      inst_desc = Enum.map_join(instantiations, ", ", fn {var, const} -> 
        "#{var} → #{const}" 
      end)
      "#{base_desc} [#{inst_desc}]"
    else
      base_desc
    end
  end

  defp format_step_result(result) do
    case result do
      formulas when is_list(formulas) -> format_formulas(formulas)
      branches when is_binary(branches) -> branches
      _ -> "#{inspect(result)}"
    end
  end

  # Helper function to negate a term (e.g., A becomes ¬A, ¬A becomes A)

  defp negate_term(term) do
    case term do
      {:not, t} -> t
      t -> {:not, t}
    end
  end

  @doc """
  Format a FOL term as a string.
  """
  def format_fol_term(term) do
    case term do
      {:var, name, _} -> "#{name}"
      {:const, name, _} -> "#{name}"
      {:app, f, x} -> "(#{format_fol_term(f)} #{format_fol_term(x)})"
      {:forall, var, type, body} -> "∀#{var}:#{format_type(type)}.(#{format_fol_term(body)})"
      {:exists, var, type, body} -> "∃#{var}:#{format_type(type)}.(#{format_fol_term(body)})"
      {:not, t} -> "¬#{format_fol_term(t)}"
      {:and, t1, t2} -> "(#{format_fol_term(t1)} ∧ #{format_fol_term(t2)})"
      {:or, t1, t2} -> "(#{format_fol_term(t1)} ∨ #{format_fol_term(t2)})"
      {:imp, t1, t2} -> "(#{format_fol_term(t1)} → #{format_fol_term(t2)})"
      {:equals, t1, t2} -> "(#{format_fol_term(t1)} = #{format_fol_term(t2)})"
      _ -> "#{inspect(term)}"
    end
  end

  defp format_type(type) do
    case type do
      :o -> "o"
      :i -> "i"
      {:arrow, t1, t2} -> "(#{format_type(t1)} → #{format_type(t2)})"
      _ -> "#{inspect(type)}"
    end
  end

  defp format_formulas(formulas) do
    if formulas == [] do
      "[empty]"
    else
      Enum.map_join(formulas, ", ", &format_fol_term/1)
    end
  end
end