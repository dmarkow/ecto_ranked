defmodule EctoRanked.Test.Model do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoRanked

  schema "models" do
    field :title, :string
    field :rank, :integer
    field :scope, :integer
    field :position, :any, virtual: true
  end

  def changeset(model, params) do
    model
    |> cast(params, [:position, :title, :scope, :rank])
    |> set_rank(:scope)
  end
end
