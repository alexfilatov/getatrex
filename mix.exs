defmodule Getatrex.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :getatrex,
      version: @version,
      elixir: "~> 1.6",
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

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gettext, "~> 0.15.0"},
      {:jason, "~> 1.0.0"},
      {:goth, ">= 0.0.0"},
      {:remix, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:excoveralls, "~> 0.8.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
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
