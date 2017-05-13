defmodule EctoRanked do
  @moduledoc """
  EctoRanked uses a rank column to  provides changeset methods for updating ordering an ordering column
  """
  import Ecto.Changeset
  import Ecto.Query

  @min -2147483648
  @max 2147483647

  @doc """
  Updates the given changeset with the appropriate ranking, and updates/ranks
  the other items in the list as necessary.
  """
  def set_rank(changeset, scope_field) do
     prepare_changes(changeset, fn changeset ->
      case changeset.action do
        :insert -> EctoRanked.before_insert changeset, scope_field
        :update -> EctoRanked.before_update changeset, scope_field
      end
    end)
  end

  def before_insert(cs, scope_field) do
    options = %{
      module: cs.data.__struct__,
      scope_field: scope_field
    }

    last = get_current_last(cs, options)
    rank = if last do
      EctoRanked.Utils.ceiling((@max - last) / 2) + last
    else
      0
    end

    cs |> put_change(:rank, rank) |> assure_unique_position(options)
  end

  def before_update(cs, scope_field) do
    options = %{
      module: cs.data.__struct__,
      scope_field: scope_field
    }

    case fetch_change(cs, :position) do
      {:ok, position} -> cs |> update_rank(options, position)
      nil -> cs
    end
  end

  defp update_rank(cs, options, position) do
    {min, max} = find_neighbors(cs, options, position)
    rank_at(cs, min, max)
    |> assure_unique_position(options)
    # min, max = find neighbors
    # rank_at(min, max)
    # assure unique positions
  end

  defp assure_unique_position(cs, options) do
    rank = get_change(cs, :rank)
    if rank && (rank > @max || current_at_rank(cs, options)) do
      rearrange_ranks(cs, options)
    else
      cs
    end
  end

  defp current_at_rank(cs, options) do
    rank = get_field(cs, :rank)
    scope = get_field(cs, options.scope_field)
    options.module
    |> where([m], field(m, ^options.scope_field) == ^scope)
    |> exclude_existing(cs)
    |> where(rank: ^rank)
    |> limit(1)
    |> cs.repo.one
  end

  defp exclude_existing(query, cs) do
    if cs.data.id do
      query |> where([m], m.id != ^cs.data.id)
    else
      query
    end
  end

  defp rearrange_ranks(cs, options) do
    rank = get_field(cs, :rank)
    scope = get_field(cs, options.scope_field)
    current_first = get_current_first(cs, options)
    current_last = get_current_last(cs, options)
    cond do
      current_first && current_first > @min && rank == @max ->#decrement lteq rank
        options.module
        |> where([m], field(m, ^options.scope_field) == ^scope)
        |> exclude_existing(cs)
        |> where([m], m.rank <= ^rank)
        |> cs.repo.update_all([inc: [rank: -1]])
        cs
      current_last && current_last < @max - 1 && rank < current_last -> #increment gteq rank
        options.module
        |> where([m], field(m, ^options.scope_field) == ^scope)
        |> exclude_existing(cs)
        |> where([m], m.rank >= ^rank)
        |> cs.repo.update_all([inc: [rank: 1]])
        cs
      current_first && current_first > @min && rank > current_first -> #decrement ltrank
        options.module
        |> where([m], field(m, ^options.scope_field) == ^scope)
        |> exclude_existing(cs)
        |> where([m], m.rank < ^rank)
        |> cs.repo.update_all([inc: [rank: -1]])
        put_change(cs, :rank, rank - 1)
      true -> rebalance_ranks(cs, options)
    end
    #   current_first > @min && rank == @max -> decrement_other_ranks(options, cs)
    #   current_last < @max - 1 && current_rank < current_last -> increment_other_ranks(options, cs)
    #   true -> rebalance_ranks(options, cs)
    # end
  end

  defp rebalance_ranks(cs, options) do
    scope = get_field(cs, options.scope_field)
    items = options.module |> order_by(asc: :rank) |> exclude_existing(cs) |> where([m], field(m, ^options.scope_field) == ^scope)|> cs.repo.all
    rank = get_field(cs, :rank)
    Enum.each(items, fn item -> IO.inspect {"item", item.title} end)
    rank_row(cs, options, items, 1, rank)
  end

  defp rank_row(cs, options, items, index, rank, set_self \\ false) do
    if index > length(items) + 1 do
      cs
    else
      rank_value = EctoRanked.Utils.ceiling(((@max - @min) / (length(items) + 2)) * index) + @min
      current_index = index - 1
      item = Enum.at(items, current_index)
      if !set_self && (!item || (item.rank && item.rank >= rank)) do
        IO.puts "RANKING US AT #{rank_value} (#{current_index})"
        IO.inspect {get_field(cs, :title), rank_value}
        cs = cs |> put_change(:rank, rank_value)
        rank_row(cs, options, items, index + 1, rank_value, true)
      else
        current_index = if set_self, do: current_index - 1, else: current_index
        item = Enum.at(items, current_index)
        IO.inspect {item.title, rank_value}
        change(item, %{rank: rank_value}) |> cs.repo.update!
        rank_row(cs, options, items, index + 1, rank, set_self)
      end
    end
  end

  defp rank_at(cs, min, max) do
    ranking = EctoRanked.Utils.ceiling((max - min) / 2) + min
    put_change(cs, :rank, ranking)
  end

  defp find_neighbors(cs, options, 0) do
    first = get_current_first(cs, options)

    case first do
      nil -> {@min, @max}
      first -> {@min, first}
    end
  end

  defp find_neighbors(cs, options, position) do
    scope = get_field(cs, options.scope_field)
    results = options.module
    |> where([m], field(m, ^options.scope_field) == ^scope)
    |> order_by(asc: :rank)
    |> limit(2)
    |> offset(^(position - 1))
    |> select([m], m.rank)
    |> exclude_existing(cs)
    |> cs.repo.all

    case results do
      [] -> {get_current_last(cs, options), @max}
      [lower] -> {lower, @max}
      [lower, upper] -> {lower, upper}
    end
  end

  defp get_current_first(cs, options) do
    scope = get_field(cs, options.scope_field)
    first = options.module
    |> where([m], field(m, ^options.scope_field) == ^scope)
    |> order_by(asc: :rank)
    |> limit(1)
    |> select([m], m.rank)

    first = if cs.data.id do
      first |> exclude_existing(cs)
    else
      first
    end

    first |> cs.repo.one
  end

  defp get_current_last(cs, options) do
    scope = get_field(cs, options.scope_field)
    last = options.module
    |> where([m], field(m, ^options.scope_field) == ^scope)
    |> order_by(desc: :rank)
    |> limit(1)
    |> select([m], m.rank)

    last = if cs.data.id do
      last |> exclude_existing(cs)
    else
      last
    end

    last |> cs.repo.one
  end
end
