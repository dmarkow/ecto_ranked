import Config

config :ecto_ranked, EctoRanked.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ecto_ranked_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  hostname: "localhost"

config :ecto_ranked,
  ecto_repos: [EctoRanked.Test.Repo]

config :logger, level: :warning
