defmodule FOLVisualiser.MixProject do
  use Mix.Project

  def project do
    [
      app: :fol_visualiser,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "FOL Visualiser",
      description: "First-Order Logic Tableau Prover with Visualization",
      package: package(),
      source_url: "https://github.com/yourusername/fol_visualiser",
      homepage_url: "https://github.com/yourusername/fol_visualiser"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:kino, "~> 0.12.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/fol_visualiser"}
    ]
  end
end