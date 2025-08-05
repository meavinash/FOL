defmodule FOLVisualiser.TreeVisualizer do
  @moduledoc """
  Professional tree visualization module for FOL tableau proofs.
  
  Generates HTML/SVG visualization of proof trees with a dark blue color scheme.
  """

  alias FOLVisualiser.FOL

  @doc """
  Generate HTML for the tableau proof tree visualization.
  """
  def generate_tree_html(root, formula_str) do
    {positioned_tree, max_width, max_height} = calculate_tree_layout(root)
    
    css = professional_tree_css()
    svg_tree = generate_professional_svg_tree(positioned_tree, max_width, max_height)
    
    html_content = """
    <div class="tableau-container">
      <h2 class="formula-header">Tableau Proof Tree for: #{formula_str}</h2>
      <div class="tree-container">
        #{svg_tree}
      </div>
    </div>
    """
    css <> html_content
  end
  
  defp calculate_tree_layout(root) do
    positioned_tree = assign_positions(root, 600, 100, 1)
    
    all_nodes = collect_all_nodes(positioned_tree)
    positions = Enum.map(all_nodes, & &1.position)
    
    min_x = if positions != [], do: Enum.min(Enum.map(positions, & &1.x)), else: 0
    max_x = if positions != [], do: Enum.max(Enum.map(positions, & &1.x)), else: 1200
    max_y = if positions != [], do: Enum.max(Enum.map(positions, & &1.y)), else: 300
    
    width = max(1400, max_x - min_x + 600)
    height = max_y + 200
    
    {positioned_tree, width, height}
  end
  
  defp collect_all_nodes(node) do
    [node | Enum.flat_map(node.children, &collect_all_nodes/1)]
  end
  
  defp assign_positions(node, x, y, depth) do
    positioned_node = Map.put(node, :position, %{x: x, y: y, depth: depth})
    
    case node.children do
      [] -> positioned_node
      children ->
        child_count = length(children)
        horizontal_spacing = max(300, 600 / depth)
        vertical_spacing = 180
        
        start_x = x - (child_count - 1) * horizontal_spacing / 2
        child_y = y + vertical_spacing
        
        positioned_children = children
        |> Enum.with_index()
        |> Enum.map(fn {child, index} ->
          child_x = start_x + index * horizontal_spacing
          assign_positions(child, child_x, child_y, depth + 1)
        end)
        
        %{positioned_node | children: positioned_children}
    end
  end
  
  defp generate_professional_svg_tree(tree_data, width, height) do
    """
    <svg width="#{width}" height="#{height}" class="tree-svg" viewBox="0 0 #{width} #{height}">
      <defs>
        <marker id="arrowhead" markerWidth="12" markerHeight="8" 
                refX="11" refY="4" orient="auto">
          <polygon points="0 0, 12 4, 0 8" fill="#60a5fa"/>
        </marker>
      </defs>
      #{generate_edges(tree_data)}
      #{generate_professional_nodes(tree_data)}
    </svg>
    """
  end
  
  defp generate_edges(node) do
    case node.children do
      [] -> ""
      children ->
        parent_x = node.position.x
        parent_y = node.position.y + 80
        
        child_edges = Enum.map(children, fn child ->
          child_x = child.position.x
          child_y = child.position.y - 15
          
          """
          <line x1="#{parent_x}" y1="#{parent_y}" 
                x2="#{child_x}" y2="#{child_y}" 
                class="tree-edge" marker-end="url(#arrowhead)"/>
          """
        end)
        
        child_subtrees = Enum.map(children, &generate_edges/1)
        
        Enum.join(child_edges ++ child_subtrees)
    end
  end
  
  defp generate_professional_nodes(node) do
    node_html = generate_professional_single_node(node)
    children_html = case node.children do
      [] -> ""
      children -> Enum.map_join(children, &generate_professional_nodes/1)
    end
    node_html <> children_html
  end
  
  defp generate_professional_single_node(node) do
    x = node.position.x
    y = node.position.y
    
    {status_class, status_color, status_text} = get_node_status(node)
    
    formulas_text = if node.formulas != [] do
      node.formulas
      |> Enum.map(&FOL.format_fol_term/1)
      |> Enum.join(", ")
    else
      if node.original_formula do
        FOL.format_fol_term(node.original_formula)
      else
        "[root]"
      end
    end
    
    rule_text = node.rule || "Start"
    rule_desc = node.rule_description || get_default_rule_description(node.rule)
    
    original_text = if node.original_formula do
      "Reducing: #{FOL.format_fol_term(node.original_formula)}"
    else
      "Initial formula"
    end
    
    closure_text = if node.closure_reason, do: "(#{node.closure_reason})", else: ""
    
    instantiation_text = if node.instantiations != [] do
      inst_text = Enum.map_join(node.instantiations, ", ", fn {var, const} -> "#{var} → #{const}" end)
      "[#{inst_text}]"
    else
      ""
    end
    
    """
    <g class="tree-node #{status_class}" transform="translate(#{x-150}, #{y-70})">
      <!-- Main node rectangle -->
      <rect width="300" height="140" rx="8" fill="#f8fafc" 
            stroke="#1e3a8a" stroke-width="2" class="node-rect"/>
      
      <!-- Node ID and Status -->
      <text x="150" y="20" text-anchor="middle" class="node-id">
        Node #{node.id} - #{status_text}
      </text>
      
      <!-- Rule being applied -->
      <text x="150" y="38" text-anchor="middle" class="rule-name">
        Rule: #{rule_text}
      </text>
      
      <!-- Rule description -->
      <text x="150" y="52" text-anchor="middle" class="rule-description">
        #{rule_desc}
      </text>
      
      <!-- Original formula being reduced -->
      <text x="150" y="72" text-anchor="middle" class="original-formula">
        #{truncate_text(original_text, 40)}
      </text>
      
      <!-- Current formulas -->
      <text x="150" y="92" text-anchor="middle" class="current-formulas">
        Result: #{truncate_text(formulas_text, 35)}
      </text>
      
      <!-- Closure reason and instantiations -->
      <text x="150" y="112" text-anchor="middle" class="node-details">
        #{closure_text} #{instantiation_text}
      </text>
      
      <!-- Status indicator -->
      <circle cx="270" cy="25" r="12" fill="#1e3a8a" stroke="white" stroke-width="2"/>
      <text x="270" y="30" text-anchor="middle" fill="white" font-size="12" font-weight="bold">
        #{get_status_symbol(node)}
      </text>
      
      <!-- Step number badge -->
      <rect x="10" y="10" width="28" height="18" rx="4" fill="#1e3a8a" opacity="0.8"/>
      <text x="24" y="22" text-anchor="middle" fill="white" font-size="11" font-weight="bold">
        #{node.step}
      </text>
    </g>
    """
  end
  
  defp get_node_status(node) do
    cond do
      node.children != [] -> 
        {"intermediate", "#1e3a8a", "INTERMEDIATE"}
      node.closed -> 
        {"closed", "#059669", "CLOSED"}
      true -> 
        {"open", "#dc2626", "OPEN"}
    end
  end
  
  defp get_status_symbol(node) do
    cond do
      node.children != [] -> "•"
      node.closed -> "✓"
      true -> "○"
    end
  end
  
  defp get_default_rule_description(rule) do
    case rule do
      "¬→ decomposition" -> "¬(A→B) ≡ A∧¬B"
      "∧ decomposition" -> "A∧B → A, B"
      "→ branching" -> "A→B ≡ ¬A∨B"
      "∨ branching" -> "A∨B branches to A | B"
      "¬∧ branching" -> "¬(A∧B) ≡ ¬A∨¬B"
      "¬∨ decomposition" -> "¬(A∨B) ≡ ¬A∧¬B"
      "¬¬ elimination" -> "¬¬A ≡ A"
      "∀ elimination" -> "∀x P(x) → P(c)"
      "∃ elimination" -> "∃x P(x) → P(c)"
      "¬∀ elimination" -> "¬∀x P(x) → ∃x ¬P(x)"
      "¬∃ elimination" -> "¬∃x P(x) → ∀x ¬P(x)"
      _ -> "Logical transformation"
    end
  end
  
  defp truncate_text(text, max_length) do
    if String.length(text) <= max_length do
      text
    else
      String.slice(text, 0, max_length - 3) <> "..."
    end
  end
  
  defp professional_tree_css do
    """
    <style>
      .tableau-container {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        background: #1e3a8a;
        padding: 30px;
        border-radius: 12px;
        max-width: 2500px;
        margin: 0 auto;
        box-shadow: 0 15px 35px rgba(0,0,0,0.3);
      }
      
      .formula-header {
        color: #f8fafc;
        text-align: center;
        margin-bottom: 30px;
        padding: 20px;
        background: #1e40af;
        border-radius: 8px;
        font-size: 24px;
        font-weight: 600;
        border: 1px solid #3b82f6;
      }
      
      .tree-container {
        background: #f8fafc;
        padding: 40px;
        border-radius: 12px;
        box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        overflow-x: auto;
        min-height: 600px;
      }
      
      .tree-svg {
        display: block;
        margin: 0 auto;
      }
      
      .tree-edge {
        stroke: #60a5fa;
        stroke-width: 2;
        opacity: 0.8;
      }
      
      .tree-node {
        cursor: pointer;
        transition: all 0.2s ease;
      }
      
      .tree-node:hover .node-rect {
        filter: brightness(0.95);
        stroke-width: 3;
        transform: scale(1.02);
      }
      
      .node-id {
        font-size: 13px;
        font-weight: 600;
        fill: #1e293b;
      }
      
      .rule-name {
        font-size: 12px;
        font-weight: 600;
        fill: #1e3a8a;
      }
      
      .rule-description {
        font-size: 10px;
        fill: #64748b;
        font-style: italic;
      }
      
      .original-formula {
        font-size: 11px;
        font-family: 'Monaco', 'Courier New', monospace;
        fill: #1e40af;
        font-weight: 500;
      }
      
      .current-formulas {
        font-size: 11px;
        font-family: 'Monaco', 'Courier New', monospace;
        fill: #1e293b;
      }
      
      .node-details {
        font-size: 10px;
        fill: #64748b;
        font-weight: 500;
      }
      
      .intermediate .node-rect {
        stroke: #1e3a8a;
        fill: #f8fafc;
      }
      
      .closed .node-rect {
        stroke: #059669;
        fill: #f8fafc;
      }
      
      .open .node-rect {
        stroke: #dc2626;
        fill: #f8fafc;
      }
      
      .tree-node {
        animation: nodeAppear 0.3s ease-out;
      }
      
      @keyframes nodeAppear {
        from {
          opacity: 0;
          transform: scale(0.9);
        }
        to {
          opacity: 1;
          transform: scale(1);
        }
      }
      
      .tree-edge {
        animation: edgeAppear 0.5s ease-out;
      }
      
      @keyframes edgeAppear {
        from {
          opacity: 0;
          stroke-dasharray: 100;
          stroke-dashoffset: 100;
        }
        to {
          opacity: 0.8;
          stroke-dasharray: 0;
          stroke-dashoffset: 0;
        }
      }
    </style>
    """
  end
end