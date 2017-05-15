defmodule EctoRanked.RankedTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{Model, Repo}
  doctest EctoRanked

  @min -2147483648
  @max 2147483647

  def ranked_ids do
    Model
    |> select([m], m.id)
    |> order_by(:rank)
    |> Repo.all
  end

  describe "insertions" do
    test "an item inserted with no position is given a rank" do
      for i <- 1..10 do
        model = %Model{}
        |> Model.changeset(%{title: "item with no position, going to be ##{i}"})
        |> Repo.insert!
        refute is_nil(model.rank)
      end

      model_ids = Model |> select([m], m.id) |> order_by(asc: :id) |> Repo.all
      assert ranked_ids() == model_ids
    end

    test "inserting item with a correct appending position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{position: 1}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with a gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{position: 10}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with an inserting position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model4 = %Model{} |> Model.changeset(%{position: 1}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model4.id, model2.id, model3.id]
    end

    test "inserting item with an inserting position at index 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model4 = %Model{} |> Model.changeset(%{position: 0}) |> Repo.insert!
      assert ranked_ids() == [model4.id, model1.id, model2.id, model3.id]
    end

    test "inserting at an invalid position" do
      assert_raise ArgumentError, "invalid position", fn ->
        Model.changeset(%Model{}, %{position: "wrong"}) |> Repo.insert!
      end
    end
  end

  describe "updates" do
    test "updating item without changing the position" do
      model = %Model{} |> Model.changeset(%{title: "original title"}) |> Repo.insert!
      updated = model |> Model.changeset(%{title: "new title"}) |> Repo.update!
      assert model.rank == updated.rank
    end

    test "moving an item up to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{position: 1}) |> Repo.update!
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{position: 1}) |> Repo.update!
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item down to a high gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{position: 100}) |> Repo.update!
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up to a position < 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{position: -100}) |> Repo.update!
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the first position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{position: "first"}) |> Repo.update!
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the last position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{position: "last"}) |> Repo.update!
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{position: "up"}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{position: "down"}) |> Repo.update
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item up when it's already first" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{position: "up"}) |> Repo.update
      assert model1.rank == Repo.get(Model, model1.id).rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item down when it's already last" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{position: "down"}) |> Repo.update
      assert model3.rank == Repo.get(Model, model3.id).rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item :down with consecutive rankings" do
      model1 = %Model{} |> Model.changeset(%{rank: @max - 2}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{rank: @max - 1}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{rank: @max}) |> Repo.insert!
      model2 |> Model.changeset(%{position: "down"}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item to a specific position with no gaps in ranking" do
      model1 = %Model{} |> Model.changeset(%{rank: 0}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{rank: 1}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{rank: 2}) |> Repo.insert!
      assert [0, 1, 2] == [model1.rank, model2.rank, model3.rank]
      model3 |> Model.changeset(%{position: 1}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end
  end

  describe "rebalancing" do
    test "rebalancing lots of items stays in the proper order" do
      models = Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "1_#{101-item}", position: 0}) |> Repo.insert!
      end) |> Enum.reverse

      models = models ++ Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "2_#{item}"}) |> Repo.insert!
      end)

      assert ranked_ids() == Enum.map(models, &(&1.id))
    end

    test "rebalancing at a middle position shifts items >= down" do
      model1 = Model.changeset(%Model{}, %{rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{rank: 0}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model4.id, model3.id, model2.id]
    end

    test "rebalancing at the first position shifts all items down" do
      model1 = Model.changeset(%Model{}, %{rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{rank: @min}) |> Repo.insert!
      assert ranked_ids() == [model4.id, model1.id, model3.id, model2.id]
    end

    test "rebalancing at the last position shifts all items down" do
      model1 = Model.changeset(%Model{}, %{rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{rank: @max}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model3.id, model2.id, model4.id]
    end
  end
end
