defmodule EctoRanked.Mixfile do
  use Mix.Project

  @source_url "https://github.com/dmarkow/ecto_ranked"
  @version "0.5.0"

  def project do
    [
      app: :ecto_ranked,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp package do
    [
      description: "Add and maintain rankings to sort your data with Ecto",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Dylan Markow"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url}
    ]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
