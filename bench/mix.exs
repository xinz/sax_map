defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases() do
    [
      "bench.xml_to_map": ["run xml_to_map.exs"]
    ]
  end

  defp deps do
    [
      {:elixir_xml_to_map, "~> 3.0"},
      {:sax_map, path: "../", override: true},
      {:benchee, "~> 1.0", only: :dev, runtime: false}
    ]
  end
end
