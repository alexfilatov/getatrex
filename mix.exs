defmodule Getatrex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :getatrex,
      version: "0.1.0",
      elixir: "~> 1.6.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:jason, ">= 0.0.0"},
      {:goth, git: "https://github.com/alexfilatov/goth.git"},
      {:gcloudex, git: "https://github.com/alexfilatov/gcloudex.git"},
      {:remix, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end
end
