defmodule EctoRanked.ScopedTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{Model, Repo}

  @min -2147483648
  @max 2147483647

  def ranked_ids(scope) do
    Model
    |> select([m], m.id)
    |> where(scope: ^scope)
    |> order_by(:rank)
    |> Repo.all
  end

  describe "insertions" do
    test "an item inserted with no position is given a rank" do
      for s <- 1..10, i <- 1..10 do
        model = Model.changeset(%Model{scope: s, title: "no position, going to be ##{i}"}, %{})
        |> Repo.insert!
        assert model.rank != nil
      end
      for s <- 1..10 do
        models = Model
                |> select([m], m.rank)
                |> order_by(asc: :id)
                |> where(scope: ^s)
                |> Repo.all
        assert models == Enum.sort_by(models, &(&1))
      end
    end

    test "inserting item with a correct appending position" do
      scope1_model1 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope2_model1 = %Model{} |> Model.changeset(%{scope: 2}) |> Repo.insert!
      scope1_model2 = %Model{} |> Model.changeset(%{scope: 1, position: 2}) |> Repo.insert!

      assert ranked_ids(1) == [scope1_model1.id, scope1_model2.id]
    end

    test "inserting item with an inserting position" do
      scope1_model1 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope1_model2 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope1_model3 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope1_model4 = %Model{} |> Model.changeset(%{scope: 1, position: 1}) |> Repo.insert!
      assert ranked_ids(1) == [scope1_model1.id, scope1_model4.id, scope1_model2.id, scope1_model3.id]
    end

    test "allow the same rank for different scopes" do
      scope1_model1 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope1_model2 = %Model{} |> Model.changeset(%{scope: 1}) |> Repo.insert!
      scope2_model1 = %Model{} |> Model.changeset(%{scope: 2}) |> Repo.insert!
      refute Repo.get(Model, scope1_model1.id).rank == Repo.get(Model, scope1_model2.id).rank
      assert Repo.get(Model, scope1_model1.id).rank == Repo.get(Model, scope2_model1.id).rank
    end

    test "moving between scopes" do
      scope1_model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!
      scope1_model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!
      scope1_model3 = Model.changeset(%Model{scope: 1, title: "item #3"}, %{}) |> Repo.insert!

      scope2_model1 = Model.changeset(%Model{scope: 2, title: "item #1"}, %{}) |> Repo.insert!
      scope2_model2 = Model.changeset(%Model{scope: 2, title: "item #2"}, %{}) |> Repo.insert!
      scope2_model3 = Model.changeset(%Model{scope: 2, title: "item #3"}, %{}) |> Repo.insert!
      scope1_model2 |> Model.changeset(%{position: 1, scope: 2}) |> Repo.update
      assert ranked_ids(1) == [scope1_model1.id, scope1_model3.id]
      assert ranked_ids(2) == [scope2_model1.id, scope1_model2.id, scope2_model2.id, scope2_model3.id]
    end

    test "moving between scopes without a specified position moves to the end of the new scope" do
      scope1_model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!
      scope1_model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!
      scope2_model1 = Model.changeset(%Model{scope: 2, title: "item #1"}, %{}) |> Repo.insert!
      scope2_model2 = Model.changeset(%Model{scope: 2, title: "item #2"}, %{}) |> Repo.insert!
      scope1_model1 = scope1_model1 |> Model.changeset(%{scope: 2}) |> Repo.update!
      assert ranked_ids(2) == [scope2_model1.id, scope2_model2.id, scope1_model1.id]
    end

    test "treats a missing scope as its own scope" do
      scope1_model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!
      scope1_model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!
      noscope_model1 = Model.changeset(%Model{title: "no scope"}, %{}) |> Repo.insert!
      assert Repo.get(Model, scope1_model1.id).rank == Repo.get(Model, noscope_model1.id).rank
    end
  end
end
