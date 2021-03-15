defmodule EctoRanked.Test.BaseQueryableModel do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import EctoRanked

  schema "base_queryable_models" do
    field :my_field, :string
    field :rank, :integer
    field :position, :any, virtual: true
  end

  def changeset(model, params) do
    model
    |> cast(params, [:my_field])
    |> set_rank()
  end

  def base_queryable_changeset(model, params) do
    model
    |> cast(params, [:position])
    |> set_rank(base_queryable: &build_base_queryable/2)
  end

  defp build_base_queryable(module, _options) do
    module
    |> where([m], not is_nil(m.my_field))
  end
end
