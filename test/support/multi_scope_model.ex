defmodule EctoRanked.Test.MultiScopeModel do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoRanked

  schema "multi_scope_models" do
    field :title, :string
    field :rank, :integer
    field :first_scope, :integer
    field :second_scope, :integer
    field :position, :any, virtual: true
  end

  def changeset(model, params) do
    model
    |> cast(params, [:position, :title, :first_scope, :second_scope, :rank])
    |> set_rank(scope: [:first_scope, :second_scope])
  end
end
