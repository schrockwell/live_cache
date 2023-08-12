defmodule LiveCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_cache,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
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
      {:phoenix_live_view, "~> 0.19.0"},
      {:plug, "~> 1.0"},
      {:ex_doc, "~> 0.30.5", only: :dev}
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
end
