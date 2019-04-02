defmodule EctoRanked.Mixfile do
  use Mix.Project

  def project do
    [app: :ecto_ranked,
     version: "0.4.2",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     docs: [main: "readme", extras: ["README.md"]],
     aliases: aliases(),
     package: package(),
     deps: deps()]
  end

  defp package do
    [description: "Add and maintain rankings to sort your data with Ecto",
     files: ["lib", "mix.exs", "README*"],
     maintainers: ["Dylan Markow"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/dmarkow/ecto_ranked"}
    ]
  end
  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [test: ["ecto.create --quiet", "ecto.migrate", "test"]]
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
    [{:ecto_sql, "~> 3.0"},
     {:postgrex, "~> 0.14", only: :test},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end
end
