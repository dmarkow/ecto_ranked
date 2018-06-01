defmodule EctoRanked.RankedTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.{Model, Repo}

  @min -2147483648
  @max 2147483647

  def ranked_ids do
    Model
    |> select([m], m.id)
    |> order_by(:my_rank)
    |> Repo.all
  end

  describe "insertions" do
    test "an item inserted with no position is given a rank" do
      for i <- 1..10 do
        model = %Model{}
        |> Model.changeset(%{title: "item with no position, going to be ##{i}"})
        |> Repo.insert!
        refute is_nil(model.my_rank)
      end

      model_ids = Model |> select([m], m.id) |> order_by(asc: :id) |> Repo.all
      assert ranked_ids() == model_ids
    end

    test "inserting item with a correct appending position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{my_position: 1}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with a gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{my_position: 10}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with an inserting position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model4 = %Model{} |> Model.changeset(%{my_position: 1}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model4.id, model2.id, model3.id]
    end

    test "inserting item with an inserting position at index 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model4 = %Model{} |> Model.changeset(%{my_position: 0}) |> Repo.insert!
      assert ranked_ids() == [model4.id, model1.id, model2.id, model3.id]
    end

    test "inserting at an invalid position" do
      assert_raise ArgumentError, "invalid position", fn ->
        Model.changeset(%Model{}, %{my_position: "wrong"}) |> Repo.insert!
      end
    end
  end

  describe "updates" do
    test "updating item without changing the position" do
      model = %Model{} |> Model.changeset(%{title: "original title"}) |> Repo.insert!
      updated = model |> Model.changeset(%{title: "new title"}) |> Repo.update!
      assert model.my_rank == updated.my_rank
    end

    test "moving an item up to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: 1}) |> Repo.update!
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{my_position: 1}) |> Repo.update!
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item down to a high gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{my_position: 100}) |> Repo.update!
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up to a position < 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: -100}) |> Repo.update!
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the first position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: "first"}) |> Repo.update!
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the :first position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: :first}) |> Repo.update!
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the last position" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{my_position: "last"}) |> Repo.update!
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: "up"}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{my_position: "down"}) |> Repo.update
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item up when it's already first" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model1 |> Model.changeset(%{my_position: "up"}) |> Repo.update
      assert model1.my_rank == Repo.get(Model, model1.id).my_rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item down when it's already last" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 |> Model.changeset(%{my_position: "down"}) |> Repo.update
      assert model3.my_rank == Repo.get(Model, model3.id).my_rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item :down with consecutive rankings" do
      model1 = %Model{} |> Model.changeset(%{my_rank: @max - 2}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{my_rank: @max - 1}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{my_rank: @max}) |> Repo.insert!
      model2 |> Model.changeset(%{my_position: "down"}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item to a specific position with no gaps in ranking" do
      model1 = %Model{} |> Model.changeset(%{my_rank: 0}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{my_rank: 1}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{my_rank: 2}) |> Repo.insert!
      assert [0, 1, 2] == [model1.my_rank, model2.my_rank, model3.my_rank]
      model3 |> Model.changeset(%{my_position: 1}) |> Repo.update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end
  end

  describe "legacy records" do
    test "new record can be inserted" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!

      # reset models to uninitialized rank
      Model |> Repo.update_all(set: [my_rank: nil])

      model4 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      assert ranked_ids() == [model4.id, model1.id, model2.id, model3.id]
    end

    test "new record can be positioned" do
      model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      model3 = %Model{} |> Model.changeset(%{}) |> Repo.insert!

      # reset models to uninitialized rank
      Model |> Repo.update_all(set: [my_rank: nil])

      model4 = %Model{} |> Model.changeset(%{my_position: 1}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model4.id, model2.id, model3.id]
    end

    test "additional records placed after ranked records" do
      _model1 = %Model{} |> Model.changeset(%{}) |> Repo.insert!
      _model2 = %Model{} |> Model.changeset(%{}) |> Repo.insert!

      # reset models to uninitialized rank
      Model |> Repo.update_all(set: [my_rank: nil])

      _model3 = %Model{} |> Model.changeset(%{my_position: 0}) |> Repo.insert!
      generated_ranks = ranked_ids()
      model4 = %Model{} |> Model.changeset(%{my_position: 0}) |> Repo.insert!
      model5 = %Model{} |> Model.changeset(%{my_position: 0}) |> Repo.insert!

      assert ranked_ids() == [model5.id, model4.id] ++ generated_ranks
    end

  end

  describe "rebalancing" do
    test "rebalancing lots of items stays in the proper order" do
      models = Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "1_#{101-item}", my_position: 0}) |> Repo.insert!
      end) |> Enum.reverse

      models = models ++ Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "2_#{item}"}) |> Repo.insert!
      end)

      assert ranked_ids() == Enum.map(models, &(&1.id))
    end

    test "rebalancing at a middle position shifts items >= down" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{my_rank: 0}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model4.id, model3.id, model2.id]
    end

    test "rebalancing at the first position shifts all items down" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{my_rank: @min}) |> Repo.insert!
      assert ranked_ids() == [model4.id, model1.id, model3.id, model2.id]
    end

    test "rebalancing at the last position shifts all items up" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> Repo.insert!
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> Repo.insert!
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> Repo.insert!
      model4 = Model.changeset(%Model{}, %{my_rank: @max}) |> Repo.insert!
      assert ranked_ids() == [model1.id, model3.id, model2.id, model4.id]
    end
  end
end
