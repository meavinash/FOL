defmodule FOLVisualiser.Structs do
  @moduledoc """
  Data structures for FOL tableau proving.
  """

  # ---- TYPES FOR TERMS AND FORMULAS ----

  # fol_type represents possible types in your logic system.
  # - :i means "individual" (like a person, object, etc.)
  # - :o means "truth value" (true/false)
  # - {:arrow, a, b} means "function from a to b" (used for predicates/functions of any arity)
  @type fol_type ::
          :i
          | :o
          | {:arrow, fol_type(), fol_type()}

  # fol_term is a union type for every kind of formula or term
  # tableau might work with.
  @type fol_term ::
          # Variable (e.g., {:var, :x, :i} for individual variable x)
          {:var, atom(), fol_type()}

          # Application (e.g., applying function f to x: {:app, f, x})
          | {:app, fol_term(), fol_term()}

          # Constant (predicate, function, or named object)
          | {:const, atom(), fol_type()}

          # Explicit equality (rarely used directly—usually "=" is a constant)
          | {:equals, fol_term(), fol_term()}

          # Standard logical connectives:
          | {:not, fol_term()}                         # Negation
          | {:and, fol_term(), fol_term()}             # Conjunction
          | {:or, fol_term(), fol_term()}              # Disjunction
          | {:imp, fol_term(), fol_term()}             # Implication

          # Quantifiers:
          | {:forall, atom(), fol_type(), fol_term()}  # Universal quantification
          | {:exists, atom(), fol_type(), fol_term()}  # Existential quantification

  # ---- TABLEAU NODES ----
# TableauNode handles individual steps

  defmodule TableauNode do
    @moduledoc """
    Represents a node in the tableau proof tree.
    Each node tracks formulas, closure status, children, and other info
    needed for visualization or rule tracing.
    """

    defstruct [
      formulas: [],         # List of formulas at this point in the branch
      closed: false,        # Is this branch closed? (i.e., does it contain a contradiction?)
      children: [],         # List of child nodes (further steps in the proof)
      id: nil,              # Unique identifier for this node (useful for UI/animation)
      rule: nil,            # Which tableau rule got applied here?
      step: 0,              # Step number in the overall proof (for visualization)
      branch_path: [],      # How we got here (for reconstructing or displaying the branch)
      instantiations: [],   # What variables got instantiated at this step?
      node_type: :open,     # Status, e.g., :open or :closed
      position: nil,        # Optional: screen position for visualization layouts
      closure_reason: nil,  # Why was this branch closed? (for explanations)
      original_formula: nil,# The formula being expanded here (for tracing)
      rule_description: nil # Human-friendly version of the rule applied
    ]
  end

  # ---- TABLEAU STATE ----
# TableauState keeps track of the entire proving process. 

  defmodule TableauState do
    @moduledoc """
    Captures the entire tableau proof's current state.
    Tracks the root node, counters, steps taken, open/closed branches,
    and variable mappings for unification or substitution.
    """

    defstruct [
      root: nil,             # The root TableauNode of the current tableau tree
      node_counter: 0,       # Used to assign unique IDs to nodes as you build the tree
      witness_counter: 0,    # Counter for creating fresh constants/witnesses (e.g., Skolem terms)
      steps: [],             # Sequence of proof steps (for undo/redo/history/animation)
      open_branches: [],     # Currently open branches (proof isn't finished until these are closed)
      closed_branches: [],   # Finished/closed branches (for summary or analysis)
      var_map: %{}           # Variable mappings (renaming, substitutions, etc.)
    ]
  end
end
