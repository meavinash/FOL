defmodule FOLVisualiser.Structs do
  @moduledoc """
  Data structures for FOL tableau proving.
  """

  @type fol_type :: :i | :o | {:arrow, fol_type(), fol_type()}
  @type fol_term ::
          {:var, atom(), fol_type()}
          | {:app, fol_term(), fol_term()}
          | {:const, atom(), fol_type()}
          | {:equals, fol_term(), fol_term()}
          | {:not, fol_term()}
          | {:and, fol_term(), fol_term()}
          | {:or, fol_term(), fol_term()}
          | {:imp, fol_term(), fol_term()}
          | {:forall, atom(), fol_type(), fol_term()}
          | {:exists, atom(), fol_type(), fol_term()}

  defmodule TableauNode do
    @moduledoc """
    Represents a node in the tableau proof tree.
    """
    defstruct formulas: [],
              closed: false,
              children: [],
              id: nil,
              rule: nil,
              step: 0,
              branch_path: [],
              instantiations: [],
              node_type: :open,
              position: nil,
              closure_reason: nil,
              original_formula: nil,
              rule_description: nil
  end

  defmodule TableauState do
    @moduledoc """
    Represents the state of the tableau proving process.
    """
    defstruct root: nil,
              node_counter: 0,
              witness_counter: 0,
              steps: [],
              open_branches: [],
              closed_branches: [],
              var_map: %{}
  end
end