defmodule EctoRanked.Test.Repo.Migrations.PrefixedModel do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA \"tenant\""
    create table(:models, prefix: "tenant") do
      add :title, :string
      add :my_rank, :integer
      add :scope, :integer
      add :global_rank, :integer
    end
  end
end
