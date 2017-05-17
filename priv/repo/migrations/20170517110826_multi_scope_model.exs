defmodule EctoRanked.Test.Repo.Migrations.MultiScopeModel do
  use Ecto.Migration

  def change do
    create table(:multi_scope_models) do
      add :title, :string
      add :rank, :integer
      add :first_scope, :integer
      add :second_scope, :integer
    end
  end
end
