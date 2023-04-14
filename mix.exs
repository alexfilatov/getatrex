defmodule Getatrex.Mixfile do
  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :getatrex,
      version: @version,
      elixir: "~> 1.10",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      test_coverage: [tool: ExCoveralls],
      source_url: "https://github.com/alexfilatov/getatrex",
      name: "Getatrex",
      docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
      description: description(),
      package: package()
    ]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :hackney]]
  end

  defp deps do
    [
      {:gettext, "~> 0.22"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:goth, "~> 1.4"},
      {:remix, "~> 0.0.2", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3", only: :test},
      {:excoveralls, "~> 0.16", only: :test},
      {:ex_doc, "~> 0.29", only: :dev}
    ]
  end

  defp description do
    "Automatic Gettext locale translator for Elixir/Phoenix projects."
  end

  defp package do
    [
      maintainers: ["Alex Filatov"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/alexfilatov/getatrex"}
    ]
  end
end
