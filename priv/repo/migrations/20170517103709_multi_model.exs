defmodule EctoRanked.Test.Repo.Migrations.MultiModel do
  use Ecto.Migration

  def change do
    create table(:multi_models) do
      add :title, :string
      add :my_rank, :integer
      add :scope, :integer
      add :global_rank, :integer
    end
  end
end
