defmodule EctoRanked.Test.Repo.Migrations.PrefixedModel do
  use Ecto.Migration

  def change do
    create table(:base_queryable_models) do
      add :my_field, :string, null: true
      add :rank, :integer, null: false
    end
  end
end
