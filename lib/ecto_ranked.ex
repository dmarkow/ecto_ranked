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

    cs
    |> update_index_from_position(options, get_change(cs, :position))
    |> assure_unique_position(options)
  end

  def before_update(cs, scope_field) do
    options = %{
      module: cs.data.__struct__,
      scope_field: scope_field
    }

    cs
    |> update_index_from_position(options, get_change(cs, :position))
    |> assure_unique_position(options)
  end

  defp update_index_from_position(cs, options, position) do
    case position do
      "first" ->
        first = get_current_first(cs, options)
        rank_between(cs, @min, first || @max)
      "last" ->
        last = get_current_last(cs, options)
        rank_between(cs, last || @min, @max)
      number when is_integer(number) ->
        {min, max} = find_neighbors(cs, options, number)
        rank_between(cs, min, max)
      nil ->
        if get_field(cs, :rank) && (!options.scope_field || !get_change(cs, options.scope_field)) do
          cs
        else
          update_index_from_position(cs, options, "last")
        end
      _ -> raise ArgumentError, "invalid position"
    end
  end

  defp rank_between(cs, min, max) do
    rank = EctoRanked.Utils.ceiling((max - min) / 2) + min
    rank_at(cs, rank)
  end

  defp rank_at(cs, rank) do
    # IO.inspect {"setting rank", rank}
    put_change(cs, :rank, rank)
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
    finder(cs, options)
    |> where(rank: ^rank)
    |> limit(1)
    |> cs.repo.one
  end

  defp rearrange_ranks(cs, options) do
    rank = get_field(cs, :rank)
    scope = get_field(cs, options.scope_field)
    current_first = get_current_first(cs, options)
    current_last = get_current_last(cs, options)
    cond do
      current_first && current_first > @min && rank == @max ->#decrement lteq rank
        finder(cs, options)
        |> where([m], m.rank <= ^rank)
        |> cs.repo.update_all([inc: [rank: -1]])
        cs
      current_last && current_last < @max - 1 && rank < current_last -> #increment gteq rank
        finder(cs, options)
        |> where([m], m.rank >= ^rank)
        |> cs.repo.update_all([inc: [rank: 1]])
        cs
      current_first && current_first > @min && rank > current_first -> #decrement ltrank
        finder(cs, options)
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
    items = finder(cs, options)
            |> order_by(asc: :rank)
            |> cs.repo.all
    rank = get_field(cs, :rank)
    rank_row(cs, options, items, 1, rank)
  end

  defp rank_row(cs, options, items, index, rank, set_self \\ false) do
    if index > length(items) + 1 do
      cs
    else
      rank_value = EctoRanked.Utils.ceiling(((@max - @min) / (length(items) + 2)) * index) + @min
      current_index = index - 1
      item = Enum.at(items, current_index)

      if !set_self && (!item || (item.rank && item.rank < @max  && item.rank >= rank)) do
        cs = cs |> put_change(:rank, rank_value)
        rank_row(cs, options, items, index + 1, rank_value, true)
      else
        current_index = if set_self, do: current_index - 1, else: current_index
        item = Enum.at(items, current_index)
        change(item, %{rank: rank_value}) |> cs.repo.update!
        rank_row(cs, options, items, index + 1, rank, set_self)
      end
    end
  end

  defp find_neighbors(cs, options, position) when position > 0 do
    results = finder(cs, options)
              |> order_by(asc: :rank)
              |> limit(2)
              |> offset(^(position - 1))
              |> select([m], m.rank)
              |> cs.repo.all

    case results do
      [] -> {get_current_last(cs, options), @max}
      [lower] -> {lower, @max}
      [lower, upper] -> {lower, upper}
    end
  end

  defp find_neighbors(cs, options, _) do
    first = get_current_first(cs, options)

    case first do
      nil -> {@min, @max}
      first -> {@min, first}
    end
  end

  defp find_neighbors

  defp get_current_first(cs, options) do
    first = finder(cs, options)
            |> order_by(asc: :rank)
            |> limit(1)
            |> select([m], m.rank)
            |> cs.repo.one
  end

  defp get_current_last(cs, options) do
    last = finder(cs, options)
           |> order_by(desc: :rank)
           |> limit(1)
           |> select([m], m.rank)
           |> cs.repo.one
  end

  defp finder(cs, options) do
    query = options.module

    query = if options.scope_field do
      scope = get_field(cs, options.scope_field)
      if scope do
        query |> where([q], field(q, ^options.scope_field) == ^scope)
      else
        query |> where([q], is_nil(field(q, ^options.scope_field)))
      end
    else
      query
    end

    if cs.data.id do
      query |> where([m], m.id != ^cs.data.id)
    else
      query
    end
  end
end
