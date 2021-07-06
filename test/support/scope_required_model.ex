defmodule EctoRanked.Test.ScopeRequiredModel do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoRanked

  schema "models" do
    field :title, :string
    field :my_rank, :integer
    field :scope, :integer
    field :my_position, :any, virtual: true
  end

  def changeset(model, params) do
    model
    |> cast(params, [:my_position, :title, :scope, :my_rank])
    |> set_rank(rank: :my_rank, position: :my_position, scope: :scope, scope_required: true)
  end

  def broken_changeset(model, params) do
    model
    |> cast(params, [:my_position, :title, :scope, :my_rank])
    |> set_rank(rank: :my_rank, position: :my_position, scope_required: true)
  end
end
