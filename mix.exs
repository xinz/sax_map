defmodule SaxMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :sax_map,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      source_url: "https://github.com/xinz/sax_map"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:saxy, "~> 1.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A fast and efficient tool for converting XML to Elixir Map"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Xin Zou"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xinz/sax_map"}
    ]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: [
       "README.md"
      ]
    ]
  end
end
