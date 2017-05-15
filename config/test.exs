use Mix.Config

config :ecto_ranked, EctoRankedTest.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ecto_ranked_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  hostname: "localhost"

config :ecto_ranked,
  ecto_repos: [EctoRankedTest.Repo]

config :logger, level: :warn
