defmodule EctoRanked.PrefixedTest do
  use EctoRanked.TestCase
  import Ecto.Query
  alias EctoRanked.Test.Repo
  alias EctoRanked.Test.PrefixedModel, as: Model

  @min -2147483648
  @max 2147483647

  def ranked_ids do
    Model
    |> select([m], m.id)
    |> order_by(:my_rank)
    |> Repo.all(prefix: "tenant")
  end

  def insert(changeset), do: Repo.insert!(changeset, prefix: "tenant")
  def update(changeset), do: Repo.update!(changeset, prefix: "tenant")

  describe "insertions" do
    test "an item inserted with no position is given a rank" do
      for i <- 1..10 do
        model = %Model{}
        |> Model.changeset(%{title: "item with no position, going to be ##{i}"})
        |> insert
        refute is_nil(model.my_rank)
      end

      model_ids = Model |> select([m], m.id) |> order_by(asc: :id) |> Repo.all(prefix: "tenant")
      assert ranked_ids() == model_ids
    end

    test "inserting item with a correct appending position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{my_position: 1}) |> insert
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with a gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{my_position: 10}) |> insert
      assert ranked_ids() == [model1.id, model2.id]
    end

    test "inserting item with an inserting position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model4 = %Model{} |> Model.changeset(%{my_position: 1}) |> insert
      assert ranked_ids() == [model1.id, model4.id, model2.id, model3.id]
    end

    test "inserting item with an inserting position at index 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model4 = %Model{} |> Model.changeset(%{my_position: 0}) |> insert
      assert ranked_ids() == [model4.id, model1.id, model2.id, model3.id]
    end

    test "inserting at an invalid position" do
      assert_raise ArgumentError, "invalid position", fn ->
        Model.changeset(%Model{}, %{my_position: "wrong"}) |> insert
      end
    end
  end

  describe "updates" do
    test "updating item without changing the position" do
      model = %Model{} |> Model.changeset(%{title: "original title"}) |> insert
      updated = model |> Model.changeset(%{title: "new title"}) |> update
      assert model.my_rank == updated.my_rank
    end

    test "moving an item when its the only one in its scope" do
      model = %Model{} |> Model.changeset(%{}) |> insert
      updated = model |> Model.changeset(%{my_position: 1}) |> update
      assert updated.my_rank == 0
    end

    test "moving an item up to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: 1}) |> update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down to a specific position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model1 |> Model.changeset(%{my_position: 1}) |> update
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item down to a high gapped position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model1 |> Model.changeset(%{my_position: 100}) |> update
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up to a position < 0" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: -100}) |> update
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the first position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: "first"}) |> update
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the :first position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: :first}) |> update
      assert ranked_ids() == [model3.id, model1.id, model2.id]
    end

    test "moving an item to the last position" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model1 |> Model.changeset(%{my_position: "last"}) |> update
      assert ranked_ids() == [model2.id, model3.id, model1.id]
    end

    test "moving an item up" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: "up"}) |> update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item down" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model1 |> Model.changeset(%{my_position: "down"}) |> update
      assert ranked_ids() == [model2.id, model1.id, model3.id]
    end

    test "moving an item up when it's already first" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model1 |> Model.changeset(%{my_position: "up"}) |> update
      assert model1.my_rank == Repo.get(Model, model1.id, prefix: "tenant").my_rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item down when it's already last" do
      model1 = %Model{} |> Model.changeset(%{}) |> insert
      model2 = %Model{} |> Model.changeset(%{}) |> insert
      model3 = %Model{} |> Model.changeset(%{}) |> insert
      model3 |> Model.changeset(%{my_position: "down"}) |> update
      assert model3.my_rank == Repo.get(Model, model3.id, prefix: "tenant").my_rank
      assert ranked_ids() == [model1.id, model2.id, model3.id]
    end

    test "moving an item :down with consecutive rankings" do
      model1 = %Model{} |> Model.changeset(%{my_rank: @max - 2}) |> insert
      model2 = %Model{} |> Model.changeset(%{my_rank: @max - 1}) |> insert
      model3 = %Model{} |> Model.changeset(%{my_rank: @max}) |> insert
      model2 |> Model.changeset(%{my_position: "down"}) |> update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end

    test "moving an item to a specific position with no gaps in ranking" do
      model1 = %Model{} |> Model.changeset(%{my_rank: 0}) |> insert
      model2 = %Model{} |> Model.changeset(%{my_rank: 1}) |> insert
      model3 = %Model{} |> Model.changeset(%{my_rank: 2}) |> insert
      assert [0, 1, 2] == [model1.my_rank, model2.my_rank, model3.my_rank]
      model3 |> Model.changeset(%{my_position: 1}) |> update
      assert ranked_ids() == [model1.id, model3.id, model2.id]
    end
  end

  describe "rebalancing" do
    test "rebalancing lots of items stays in the proper order" do
      models = Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "1_#{101-item}", my_position: 0}) |> insert
      end) |> Enum.reverse

      models = models ++ Enum.map(1..100, fn(item) ->
        Model.changeset(%Model{}, %{title: "2_#{item}"}) |> insert
      end)

      assert ranked_ids() == Enum.map(models, &(&1.id))
    end

    test "rebalancing at a middle position shifts items >= down" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> insert
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> insert
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> insert
      model4 = Model.changeset(%Model{}, %{my_rank: 0}) |> insert
      assert ranked_ids() == [model1.id, model4.id, model3.id, model2.id]
    end

    test "rebalancing at the first position shifts all items down" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> insert
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> insert
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> insert
      model4 = Model.changeset(%Model{}, %{my_rank: @min}) |> insert
      assert ranked_ids() == [model4.id, model1.id, model3.id, model2.id]
    end

    test "rebalancing at the last position shifts all items up" do
      model1 = Model.changeset(%Model{}, %{my_rank: @min}) |> insert
      model2 = Model.changeset(%Model{}, %{my_rank: @max}) |> insert
      model3 = Model.changeset(%Model{}, %{my_rank: 0}) |> insert
      model4 = Model.changeset(%Model{}, %{my_rank: @max}) |> insert
      assert ranked_ids() == [model1.id, model3.id, model2.id, model4.id]
    end
  end
end
