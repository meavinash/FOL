defmodule FOLVisualiser do
  @moduledoc """
  First-Order Logic (FOL) tableau proving and visualization library.
  
  This module provides functionality for:
  - Parsing FOL formulas
  - Automated theorem proving using semantic tableau method
  - Professional visualization of proof trees
  """

  alias FOLVisualiser.{Parser, FOL, TreeVisualizer}

  @doc """
  Parse and visualize a FOL formula.
  
  ## Examples
  
      iex> FOLVisualiser.prove_and_visualize("(A → B) → (¬B → ¬A)")
      # Returns Kino.HTML with visualization
  
  """
  def prove_and_visualize(formula_str) do
    case Parser.parse(formula_str) do
      {:ok, ast} ->
        {result, detailed_steps} = FOL.prove_with_detailed_steps(ast)
        
        tree_html = TreeVisualizer.generate_tree_html(result.tree_root, formula_str)
        summary_html = generate_professional_proof_summary(formula_str, result, detailed_steps)
        steps_html = generate_professional_steps_html(detailed_steps)
        
        complete_html = """
        <div style="max-width: 2500px; margin: 0 auto; padding: 20px;">
          #{summary_html}
          <div style="margin-top: 40px;">
            #{tree_html}
          </div>
          #{steps_html}
        </div>
        """
        
        # Return HTML string if Kino is not available, otherwise Kino.HTML
        if Code.ensure_loaded?(Kino) do
          Kino.HTML.new(complete_html)
        else
          complete_html
        end
        
      {:error, reason} ->
        error_html = """
        <div style="background: #1e3a8a; border: 2px solid #3b82f6; color: #f8fafc; padding: 30px; border-radius: 12px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; box-shadow: 0 8px 25px rgba(0,0,0,0.3);">
          <h3 style="margin-top: 0; font-size: 22px;">Parse Error</h3>
          <p style="font-size: 16px;"><strong>Error:</strong> #{reason}</p>
          <p style="font-size: 16px;"><strong>Formula:</strong> <code style="background: #1e40af; color: #f8fafc; padding: 4px 8px; border-radius: 4px;">#{formula_str}</code></p>
          <div style="background: #1e40af; padding: 20px; border-radius: 8px; margin-top: 20px;">
            <p style="margin-bottom: 12px;"><strong>Note:</strong> Use Unicode symbols for logical operators:</p>
            <ul style="margin-left: 20px; line-height: 1.6;">
              <li><strong>→</strong> for implication</li>
              <li><strong>∧</strong> for conjunction</li>
              <li><strong>∨</strong> for disjunction</li>
              <li><strong>¬</strong> for negation</li>
              <li><strong>∀</strong> for universal quantification</li>
              <li><strong>∃</strong> for existential quantification</li>
              <li><strong>=</strong> for equality</li>
            </ul>
          </div>
        </div>
        """
        
        if Code.ensure_loaded?(Kino) do
          Kino.HTML.new(error_html)
        else
          error_html
        end
    end
  end

  defp generate_professional_proof_summary(formula_str, result, detailed_steps) do
    validity_color = if result.is_valid, do: "#059669", else: "#dc2626"
    validity_text = if result.is_valid, do: "VALID (Provable)", else: "INVALID (Not Provable)"
    
    """
    <div style="background: #1e3a8a; border-radius: 12px; padding: 30px; box-shadow: 0 12px 30px rgba(0,0,0,0.3); margin-bottom: 30px;">
      <h1 style="color: #f8fafc; margin-bottom: 30px; text-align: center; font-size: 28px;">
        FOL Tableau Proof Analysis
      </h1>
      
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 25px; margin-bottom: 30px;">
        <div style="background: #1e40af; padding: 20px; border-radius: 10px; border: 1px solid #3b82f6;">
          <h3 style="margin-top: 0; color: #f8fafc; font-size: 18px;">Formula</h3>
          <code style="background: #f8fafc; color: #1e293b; padding: 12px; border-radius: 6px; display: block; font-size: 16px; font-weight: 600;">#{formula_str}</code>
        </div>
        
        <div style="background: #1e40af; padding: 20px; border-radius: 10px; border: 1px solid #3b82f6;">
          <h3 style="margin-top: 0; color: #f8fafc; font-size: 18px;">Result</h3>
          <p style="font-size: 18px; font-weight: 600; color: #{validity_color}; margin: 0; background: #f8fafc; padding: 10px; border-radius: 6px;">#{validity_text}</p>
          <p style="color: #e2e8f0; font-size: 14px; margin: 10px 0 0 0;">
            Closed branches: <strong>#{length(result.closed_branches)}</strong> | Open branches: <strong>#{length(result.open_branches)}</strong>
          </p>
        </div>
      </div>
      
      <div style="background: #1e40af; padding: 20px; border-radius: 10px; border: 1px solid #3b82f6;">
        <h3 style="margin-top: 0; color: #f8fafc; font-size: 18px;">Proof Statistics</h3>
        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px;">
          <div style="text-align: center;">
            <div style="font-size: 24px; font-weight: 600; color: #f8fafc;">#{length(detailed_steps)}</div>
            <div style="color: #e2e8f0; font-size: 14px;">Total Steps</div>
          </div>
          <div style="text-align: center;">
            <div style="font-size: 24px; font-weight: 600; color: #f8fafc;">#{result.total_branches}</div>
            <div style="color: #e2e8f0; font-size: 14px;">Total Branches</div>
          </div>
          <div style="text-align: center;">
            <div style="font-size: 24px; font-weight: 600; color: #f8fafc;">#{length(result.closed_branches)}</div>
            <div style="color: #e2e8f0; font-size: 14px;">Closed Branches</div>
          </div>
          <div style="text-align: center;">
            <div style="font-size: 16px; font-weight: 600; color: #f8fafc;">FOL Tableau</div>
            <div style="color: #e2e8f0; font-size: 14px;">Proof Method</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp generate_professional_steps_html(detailed_steps) do
    if detailed_steps == [] do
      """
      <div style="background: #1e3a8a; padding: 30px; border-radius: 12px; text-align: center; margin-top: 30px;">
        <h3 style="color: #f8fafc; margin: 0;">No proof steps required - Formula is immediately valid!</h3>
      </div>
      """
    else
      steps_html = detailed_steps
      |> Enum.with_index(1)
      |> Enum.map_join(fn {step, index} ->
        branch_path_html = case Map.get(step, :branch_path, []) do
          [] -> ""
          path -> 
            path_text = Enum.map_join(path, " → ", fn 
              "root" -> "Root"
              "left" -> "Left"
              "right" -> "Right"
              other -> other
            end)
            "<div style=\"font-size: 14px; color: #64748b; margin-bottom: 10px;\">Path: #{path_text}</div>"
        end
        
        step_color = case rem(index, 4) do
          1 -> "#1e3a8a"
          2 -> "#1e40af"
          3 -> "#2563eb"
          0 -> "#3b82f6"
        end
        
        """
        <div style="background: #f8fafc; border-left: 4px solid #{step_color}; margin-bottom: 20px; border-radius: 0 8px 8px 0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
          <div style="padding: 25px;">
            #{branch_path_html}
            
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
              <h4 style="margin: 0; color: #{step_color}; font-size: 18px;">
                Step #{step.num}: #{step.rule}
              </h4>
              <span style="background: #{step_color}; color: #f8fafc; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;">
                #{step.rule}
              </span>
            </div>
            
            <div style="background: #f1f5f9; padding: 15px; border-radius: 6px; margin-bottom: 15px;">
              <p style="margin: 0; font-size: 15px; color: #1e293b; line-height: 1.5;"><strong>Description:</strong> #{step.description}</p>
            </div>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 15px;">
              <div>
                <div style="background: #{step_color}; color: #f8fafc; padding: 8px 15px; border-radius: 4px 4px 0 0; font-weight: 600; font-size: 13px;">
                  BEFORE STATE
                </div>
                <div style="background: #e2e8f0; padding: 15px; border-radius: 0 0 4px 4px; font-family: 'Monaco', 'Courier New', monospace; font-size: 13px; min-height: 50px; border: 2px solid #{step_color}; color: #1e293b;">
                  #{step.before_state}
                </div>
              </div>
              <div>
                <div style="background: #{step_color}; color: #f8fafc; padding: 8px 15px; border-radius: 4px 4px 0 0; font-weight: 600; font-size: 13px;">
                  AFTER STATE
                </div>
                <div style="background: #dcfce7; padding: 15px; border-radius: 0 0 4px 4px; font-family: 'Monaco', 'Courier New', monospace; font-size: 13px; min-height: 50px; border: 2px solid #{step_color}; color: #1e293b;">
                  #{step.after_state}
                </div>
              </div>
            </div>
            
            #{if Map.get(step, :instantiations, []) != [] do
              inst_html = Enum.map_join(step.instantiations, ", ", fn {var, const} -> 
                "<span style=\"background: #1e3a8a; color: #f8fafc; padding: 2px 8px; border-radius: 10px; font-size: 11px;\">#{var} ↦ #{const}</span>" 
              end)
              """
              <div style="background: #1e3a8a; padding: 15px; border-radius: 6px; margin-top: 15px;">
                <div style="color: #f8fafc; font-weight: 600; margin-bottom: 8px;">Variable Instantiations:</div>
                <div>#{inst_html}</div>
              </div>
              """
            else
              ""
            end}
          </div>
        </div>
        """
      end)
      
      """
      <div style="background: #f8fafc; padding: 30px; border-radius: 12px; box-shadow: 0 8px 25px rgba(0,0,0,0.15); margin-top: 40px;">
        <h2 style="color: #1e293b; margin-bottom: 25px; text-align: center; font-size: 26px;">
          Detailed Proof Steps Analysis
        </h2>
        <div style="background: #dbeafe; padding: 20px; border-radius: 8px; margin-bottom: 25px;">
          <p style="margin: 0; text-align: center; color: #1e293b; font-size: 16px;">
            This proof required <strong>#{length(detailed_steps)} logical transformation steps</strong> to establish validity through systematic tableau expansion.
          </p>
        </div>
        #{steps_html}
      </div>
      """
    end
  end
end