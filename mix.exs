defmodule Getatrex.Mixfile do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :getatrex,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      test_coverage: [tool: ExCoveralls],
      source_url: "https://github.com/alexfilatov/getatrex",
      name: "Getatrex",
      docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :hackney]]
  end

  defp deps do
    [
      {:gettext, "~> 1.0"},
      {:expo, "~> 1.1"},
      {:httpoison, "~> 2.3"},
      {:jason, "~> 1.4"},
      {:goth, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.40", only: :dev}
    ]
  end

  defp description do
    "Automatic Gettext locale translator for Elixir/Phoenix projects."
  end

  defp package do
    [
      maintainers: ["Alex Filatov"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/alexfilatov/getatrex"},
      docs: [
        source_ref: "v#{@version}",
        source_url: "https://github.com/alexfilatov/getatrex",
        dependencies: [
          ex_doc: "~> 0.29.4"
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
