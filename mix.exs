defmodule LiveCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_cache,
      version: "0.3.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: description(),
      source_url: "https://github.com/schrockwell/live_cache"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LiveCache.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Prod
      {:phoenix_live_view, "~> 0.18.0"},
      {:plug, "~> 1.0"},

      # Dev
      {:ex_doc, "~> 0.30.5", only: :dev},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},

      # Test
      {:floki, ">= 0.30.0", only: :test},
      {:jason, "~> 1.2", only: :test},
      {:phoenix_view, "~> 2.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "LiveCache"
    ]
  end

  defp description do
    "Optimize assigns during LiveView mounts"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/schrockwell/live_cache"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
