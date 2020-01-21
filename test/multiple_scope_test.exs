defmodule EctoRanked.MultipleScopeTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{MultiScopeModel, Repo}

  def ranked_ids(scope1, scope2) do
    MultiScopeModel
    |> select([m], m.id)
    |> where(first_scope: ^scope1)
    |> where(second_scope: ^scope2)
    |> order_by(:rank)
    |> Repo.all()
  end

  test "maintain multiple ranking columns on a model" do
    group1_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group2_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model2 |> MultiScopeModel.changeset(%{position: :up}) |> Repo.update!()
    assert ranked_ids(1, 1) == [group1_model1.id, group1_model2.id, group1_model3.id]
    assert ranked_ids(1, 2) == [group2_model2.id, group2_model1.id, group2_model3.id]
  end

  test "moving between scopes" do
    group1_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group2_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group1_model2 |> MultiScopeModel.changeset(%{position: 1, second_scope: 2}) |> Repo.update()

    assert ranked_ids(1, 1) == [group1_model1.id, group1_model3.id]

    assert ranked_ids(1, 2) == [
             group2_model1.id,
             group1_model2.id,
             group2_model2.id,
             group2_model3.id
           ]
  end

  test "moving to a new scope" do
    group1_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group1_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 1})
      |> Repo.insert!()

    group2_model1 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model2 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group2_model3 =
      %MultiScopeModel{}
      |> MultiScopeModel.changeset(%{first_scope: 1, second_scope: 2})
      |> Repo.insert!()

    group1_model2 |> MultiScopeModel.changeset(%{first_scope: 2}) |> Repo.update()

    assert ranked_ids(1, 1) == [group1_model1.id, group1_model3.id]
    assert ranked_ids(1, 2) == [group2_model1.id, group2_model2.id, group2_model3.id]
    assert ranked_ids(2, 1) == [group1_model2.id]
  end
end
