defmodule EctoRanked.BaseQueryableTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{BaseQueryableModel, Repo}

  def ranked_ids() do
    BaseQueryableModel
    |> select([m], m.id)
    |> order_by(:rank)
    |> Repo.all()
  end

  test "moving an item with a base queryable" do
    model1 =
      %BaseQueryableModel{}
      |> BaseQueryableModel.changeset(%{my_field: "My field"})
      |> Repo.insert!()

    model2 =
      %BaseQueryableModel{}
      |> BaseQueryableModel.changeset(%{})
      |> Repo.insert!()

    model3 =
      %BaseQueryableModel{}
      |> BaseQueryableModel.changeset(%{my_field: "My field"})
      |> Repo.insert!()

    model3 =
      model3 |> BaseQueryableModel.base_queryable_changeset(%{position: :up}) |> Repo.update!()

    assert ranked_ids() == [model3.id, model1.id, model2.id]
  end
end
