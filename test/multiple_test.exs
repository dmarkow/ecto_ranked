defmodule EctoRanked.MultipleTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{MultiModel, Repo}

  def ranked_ids(scope) do
    MultiModel
    |> select([m], m.id)
    |> where(scope: ^scope)
    |> order_by(:my_rank)
    |> Repo.all()
  end

  def ranked_ids do
    MultiModel
    |> select([m], m.id)
    |> order_by(:global_rank)
    |> Repo.all()
  end

  test "maintain multiple ranking columns on a model" do
    model1 = %MultiModel{} |> MultiModel.changeset(%{scope: 1}) |> Repo.insert!()
    model2 = %MultiModel{} |> MultiModel.changeset(%{scope: 1}) |> Repo.insert!()
    model3 = %MultiModel{} |> MultiModel.changeset(%{scope: 1}) |> Repo.insert!()
    model3 |> MultiModel.changeset(%{global_position: :first}) |> Repo.update!()
    model2 |> MultiModel.changeset(%{my_position: :last}) |> Repo.update!()

    assert ranked_ids(1) == [model1.id, model3.id, model2.id]
    assert ranked_ids() == [model3.id, model1.id, model2.id]
  end
end
