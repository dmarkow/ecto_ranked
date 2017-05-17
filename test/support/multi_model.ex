defmodule EctoRanked.Test.MultiModel do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoRanked

  schema "multi_models" do
    field :title, :string
    field :my_rank, :integer
    field :scope, :integer
    field :global_rank, :integer
    field :global_position, :any, virtual: true
    field :my_position, :any, virtual: true
  end

  def changeset(model, params) do
    model
    |> cast(params, [:my_position, :title, :scope, :my_rank, :global_position, :global_rank])
    |> set_rank(rank: :my_rank, position: :my_position, scope: :scope)
    |> set_rank(rank: :global_rank, position: :global_position)
  end
end
