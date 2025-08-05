# FOL Visualiser

A comprehensive First-Order Logic (FOL) tableau proving library with professional visualization capabilities for Elixir.

## Features

- **Automated Theorem Proving**: Implements the semantic tableau method for FOL
- **Professional Visualization**: Interactive HTML/SVG proof trees with dark blue theme
- **Step-by-Step Analysis**: Detailed tracking of proof construction
- **Unification Support**: Pattern matching for term equality and contradiction detection
- **Comprehensive Parser**: Supports Unicode logical operators and type annotations
- **LiveBook Integration**: Ready-to-use LiveMarkdown demonstrations

## Installation

Add `fol_visualiser` to your mix.exs dependencies:

```elixir
def deps do
  [
    {:fol_visualiser, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
alias FOLVisualiser

# Prove and visualize a simple implication
formula = "(A → B) → (¬B → ¬A)"
result = FOLVisualiser.prove_and_visualize(formula)
```

## Usage

### Basic Examples

```elixir
# Simple implication
FOLVisualiser.prove_and_visualize("(A → B) → (¬B → ¬A)")

# Conjunction
FOLVisualiser.prove_and_visualize("A ∧ B")

# Disjunction
FOLVisualiser.prove_and_visualize("A ∨ B")

# Universal quantification
FOLVisualiser.prove_and_visualize("∀x:i. (P(x) → Q(x)) → (∀x:i. P(x) → ∀x:i. Q(x))")

# Existential quantification
FOLVisualiser.prove_and_visualize("∃x:i. P(x) → ¬∀x:i. ¬P(x)")

# Equality
FOLVisualiser.prove_and_visualize("∀x:i. ∀y:i. (x = y → y = x)")
```

### Formula Syntax

The parser supports standard FOL syntax with Unicode operators:

#### Logical Operators
- `→` or `->` for implication
- `∧` or `&` for conjunction  
- `∨` for disjunction
- `¬` for negation
- `=` for equality

#### Quantifiers
- `∀` for universal quantification
- `∃` for existential quantification

#### Variables and Constants
- `a, b, c, ...` for individual variables
- `A, B, C, ...` for propositional constants
- `P, Q, R, ...` for predicate constants
- `f, g, h, ...` for function constants

#### Type Annotations
- `:i` for individual type
- `:o` for propositional type

### Example Formulas

```elixir
# Propositional logic
"A → B"
"¬(A ∧ B)"
"A ∨ (B ∧ C)"

# First-order logic
"∀x:i. P(x)"
"∃x:i. (P(x) ∧ Q(x))"
"∀x:i. ∃y:i. R(x, y)"

# Equality
"∀x:i. ∀y:i. (x = y → y = x)"
"∃x:i. (x = c ∧ P(x))"
```

## LiveBook Integration

The package includes a comprehensive LiveMarkdown demo file (`fol_visualiser_demo.livemd`) that provides:

- Interactive formula input
- Real-time visualization
- Step-by-step proof analysis
- Syntax guide and examples

To use in LiveBook:

```elixir
Mix.install([
  {:kino, "~> 0.12.0"}
])

# Load modules from the current directory
Code.compile_file("lib/fol_visualiser.ex")
Code.compile_file("lib/fol_visualiser/structs.ex")
Code.compile_file("lib/fol_visualiser/term.ex")
Code.compile_file("lib/fol_visualiser/unification_adapter.ex")
Code.compile_file("lib/fol_visualiser/unification.ex")
Code.compile_file("lib/fol_visualiser/fol.ex")
Code.compile_file("lib/fol_visualiser/parser.ex")
Code.compile_file("lib/fol_visualiser/tree_visualizer.ex")

alias FOLVisualiser

# Visualize formula
FOLVisualiser.prove_and_visualize("(A → B) → (¬B → ¬A)")
```

## Architecture

### Core Modules

- `FOLVisualiser` - Main interface and HTML generation
- `FOLVisualiser.Parser` - FOL formula parsing
- `FOLVisualiser.FOL` - Tableau proving engine
- `FOLVisualiser.Term` - Term operations and substitution
- `FOLVisualiser.Unification` - Unification algorithm
- `FOLVisualiser.UnificationAdapter` - Format conversion
- `FOLVisualiser.TreeVisualizer` - SVG/HTML tree generation
- `FOLVisualiser.Structs` - Data structures

### Data Structures

```elixir
# FOL term types
@type fol_type :: :i | :o | {:arrow, fol_type(), fol_type()}
@type fol_term ::
        {:var, atom(), fol_type()}
        | {:const, atom(), fol_type()}
        | {:app, fol_term(), fol_term()}
        | {:not, fol_term()}
        | {:and, fol_term(), fol_term()}
        | {:or, fol_term(), fol_term()}
        | {:imp, fol_term(), fol_term()}
        | {:forall, atom(), fol_type(), fol_term()}
        | {:exists, atom(), fol_type(), fol_term()}
        | {:equals, fol_term(), fol_term()}

# Tableau structures
defmodule TableauNode do
  defstruct formulas: [],
            closed: false,
            children: [],
            id: nil,
            rule: nil,
            step: 0,
            branch_path: [],
            instantiations: [],
            node_type: :open,
            # ... other fields
end
```

### Proof Process

1. **Parsing**: Convert string formulas to AST
2. **Negation**: Negate goal for contradiction proof
3. **Tableau Construction**: Apply rules systematically
4. **Closure Detection**: Check for contradictions using unification
5. **Classification**: Determine proof validity
6. **Visualization**: Generate interactive proof tree

## Visualization Features

The visualization includes:

- **Professional Tree Layout**: Automatic positioning and routing
- **Interactive Nodes**: Hover effects and detailed information
- **Color Coding**: 
  - Blue: Intermediate nodes
  - Green: Closed nodes (contradiction found)
  - Red: Open nodes (no contradiction)
- **Step Tracking**: Complete proof construction history
- **Rule Descriptions**: Clear explanations of each transformation
- **Branch Paths**: Visual representation of proof flow

## Rules Implemented

### Alpha Rules (Non-branching)
- **¬¬ elimination**: Double negation removal
- **∧ decomposition**: Conjunction elimination
- **¬∨ decomposition**: De Morgan's law
- **¬→ decomposition**: Negated implication

### Beta Rules (Branching)
- **→ branching**: Implication to disjunction
- **∨ branching**: Disjunction branching
- **¬∧ branching**: De Morgan's law

### Gamma Rules (Universal)
- **∀ elimination**: Universal instantiation
- **¬∃ elimination**: Negated existential

### Delta Rules (Existential)
- **∃ elimination**: Existential instantiation
- **¬∀ elimination**: Negated universal

## Limitations

- Maximum proof steps: 50 (prevents infinite loops)
- Limited to standard FOL syntax
- Some complex formulas may not terminate
- Equality reasoning is basic
- No support for higher-order logic

## Development

### Running Tests

```bash
mix test
```

### Building Documentation

```bash
mix docs
```

### LiveBook Development

```bash
livebook server
```

Then open `fol_visualiser_demo.livemd` for interactive development.

