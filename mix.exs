defmodule FOLVisualiser.MixProject do
  use Mix.Project

  # Configuration for the FOL Visualiser project
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
      source_url: "https://github.com/meavinash/FOL.git",
      homepage_url: "https://github.com/meavinash/FOL.git"
    ]
  end

  # Application configuration
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # List of dependencies
  defp deps do
    [
      {:kino, "~> 0.12.0"}
    ]
  end

  # Package information
  defp package do
    [
      licenses: ["MIT"],
      links: %{ "GitHub" => "https://github.com/meavinash/FOL.git"}
    ]
  end
end
