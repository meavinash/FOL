defmodule FOLVisualiser.Parser do
  @moduledoc """
  Parser for FOL formulas.
  
  Parses string representations of FOL formulas into AST structures.
  """

  @doc """
  Parse a FOL formula string into an AST.
  Raises an exception if parsing fails.
  """
  def parse!(str) do
    cleaned = str 
    |> String.replace(~r/\s+/, " ") 
    |> String.trim()
    
    result = parse_expression(cleaned)
    result
  end

  @doc """
  Parse a FOL formula string into an AST.
  Returns {:ok, ast} or {:error, reason}.
  """
  def parse(str) do
    try do
      {:ok, parse!(str)}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp parse_expression(str) do
    str |> tokenize() |> parse_tokens()
  end

  defp tokenize(str) do
    str
    |> String.replace("→", " IMP ")
    |> String.replace("∨", " OR ")
    |> String.replace("∧", " AND ")
    |> String.replace("¬", " NOT ")
    |> String.replace("&", " AND ")   
    |> String.replace("->", " IMP ")  
    |> String.replace("∀", " FORALL ")
    |> String.replace("∃", " EXISTS ")
    |> String.replace("=", " = ")
    |> String.replace("(", " ( ")
    |> String.replace(")", " ) ")
    |> String.replace(".", " . ")
    |> String.replace(":", " : ")
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_tokens(tokens) do
    {expr, []} = parse_implication(tokens)
    expr
  end

  defp parse_implication(tokens) do
    {left, rest} = parse_disjunction(tokens)
    parse_implication_right(left, rest)
  end

  defp parse_implication_right(left, ["IMP" | rest]) do
    {right, rest2} = parse_implication(rest)
    {{:imp, left, right}, rest2}
  end
  defp parse_implication_right(left, rest), do: {left, rest}

  defp parse_disjunction(tokens) do
    {left, rest} = parse_conjunction(tokens)
    parse_disjunction_right(left, rest)
  end

  defp parse_disjunction_right(left, ["OR" | rest]) do
    {right, rest2} = parse_disjunction(rest)
    {{:or, left, right}, rest2}
  end
  defp parse_disjunction_right(left, rest), do: {left, rest}

  defp parse_conjunction(tokens) do
    {left, rest} = parse_equality(tokens)
    parse_conjunction_right(left, rest)
  end

  defp parse_conjunction_right(left, ["AND" | rest]) do
    {right, rest2} = parse_conjunction(rest)
    {{:and, left, right}, rest2}
  end
  defp parse_conjunction_right(left, rest), do: {left, rest}

  defp parse_equality(tokens) do
    {left, rest} = parse_negation(tokens)
    parse_equality_right(left, rest)
  end

  defp parse_equality_right(left, ["=" | rest]) do
    {right, rest2} = parse_equality(rest)
    {{:equals, left, right}, rest2}
  end
  defp parse_equality_right(left, rest), do: {left, rest}

  defp parse_negation(["NOT" | rest]) do
    {expr, rest2} = parse_negation(rest)
    {{:not, expr}, rest2}
  end
  defp parse_negation(tokens), do: parse_quantifier(tokens)

  defp parse_quantifier(["FORALL", var, ":", type, "." | rest]) do
    {body, rest2} = parse_implication(rest)
    type_atom = if type == "o", do: :o, else: :i
    {{:forall, String.to_atom(var), type_atom, body}, rest2}
  end

  defp parse_quantifier(["EXISTS", var, ":", type, "." | rest]) do
    {body, rest2} = parse_implication(rest)
    type_atom = if type == "o", do: :o, else: :i
    {{:exists, String.to_atom(var), type_atom, body}, rest2}
  end
  defp parse_quantifier(tokens), do: parse_atom(tokens)

  defp parse_atom(["(" | rest]) do
    {expr, [")" | rest2]} = parse_implication(rest)
    {expr, rest2}
  end
  defp parse_atom([atom | rest]), do: parse_application([atom | rest])

  defp parse_application(tokens) do
    {term, rest} = parse_atomic(tokens)
    parse_application_rest(term, rest)
  end

  defp parse_application_rest(term, rest_tokens) do
    case rest_tokens do
      [] -> {term, []}
      [next | _] = rest ->
        if next in ["IMP", "OR", "AND", "NOT", "FORALL", "EXISTS", ")", ".", "="] do
          {term, rest}
        else
          {arg, rest2} = parse_atomic(rest)
          parse_application_rest({:app, term, arg}, rest2)
        end
    end
  end

  defp parse_atomic(["(" | rest]) do
    {expr, [")" | rest2]} = parse_implication(rest)
    {expr, rest2}
  end

  defp parse_atomic([atom | rest]) do
    case atom do
      "A" -> {{:const, :A, :o}, rest}
      "B" -> {{:const, :B, :o}, rest}
      "C" -> {{:const, :C, :o}, rest}
      "P" -> {{:const, :P, {:arrow, :i, :o}}, rest}
      "Q" -> {{:const, :Q, {:arrow, :i, :o}}, rest}
      "R" -> {{:const, :R, {:arrow, :i, {:arrow, :i, :o}}}, rest}
      "f" -> {{:const, :f, {:arrow, :i, :i}}, rest}
      "g" -> {{:const, :g, {:arrow, :i, :i}}, rest}
      "h" -> {{:const, :h, {:arrow, :i, :i}}, rest}
      "=" -> {{:const, :=, {:arrow, :i, {:arrow, :i, :o}}}, rest}
      var ->
        if String.length(var) == 1 and var >= "a" and var <= "z" do
          {{:var, String.to_atom(var), :i}, rest}
        else
          {{:const, String.to_atom(var), :i}, rest}
        end
    end
  end
end