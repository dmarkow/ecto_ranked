defmodule EctoRanked.Test.Repo.Migrations.Model do
  use Ecto.Migration

  def change do
    create table(:models) do
      add :title, :string
      add :rank, :integer
      add :scope, :integer
    end
  end
end
