defmodule EctoRanked do
  @moduledoc """
  This module provides support for automatic ranking of your Ecto models.
  """
  import Ecto.Changeset
  import Ecto.Query

  @min -2_147_483_648
  @max 2_147_483_647

  @doc """
  Updates the given changeset with the appropriate ranking, and updates/ranks
  the other items in the list as necessary.

  ## Options
  * `:rank` - the field to store the actual ranking in. Defaults to `:rank`
  * `:position` - the field to use for positional changes. Defaults to `:position`
  * `:scope` - the field(s) to scope all rankings to. Defaults to `nil` (no scoping).
  * `:prefix` - the prefix to run all queries on (e.g. the schema path in Postgres). Defaults to `nil` (no prefix).
  """
  @spec set_rank(Ecto.Changeset.t(), Keyword.t()) :: Ecto.Changeset.t()
  def set_rank(changeset, opts \\ []) do
    prepare_changes(changeset, fn cs ->
      if cs.action in [:insert, :update] do
        options = %{
          module: cs.data.__struct__,
          scope_field: Keyword.get(opts, :scope),
          position_field: Keyword.get(opts, :position, :position),
          rank_field: Keyword.get(opts, :rank, :rank),
          prefix: Keyword.get(opts, :prefix, nil),
          base_queryable: Keyword.get(opts, :base_queryable)
        }

        cs
        |> update_index_from_position(options, get_change(cs, options.position_field))
        |> assure_unique_position(options)
      end
    end)
  end

  defp update_index_from_position(cs, options, position) do
    case position do
      pos when pos in ["first", :first] ->
        first = get_current_first(cs, options)

        if first do
          rank_between(cs, options, pos, @min, first || @max)
        else
          update_index_from_position(cs, options, :middle)
        end

      pos when pos in ["middle", :middle] ->
        rank_between(cs, options, pos, @min, @max)

      pos when pos in ["last", :last] ->
        last = get_current_last(cs, options)

        if last do
          rank_between(cs, options, pos, last || @min, @max)
        else
          update_index_from_position(cs, options, :middle)
        end

      pos when pos in ["up", :up] ->
        case find_prev_two(cs, options) do
          nil -> cs
          {min, max} -> rank_between(cs, options, pos, min, max)
        end

      pos when pos in ["down", :down] ->
        case find_next_two(cs, options) do
          nil -> cs
          {min, max} -> rank_between(cs, options, pos, min, max)
        end

      number when is_integer(number) ->
        {min, max} = find_neighbors(cs, options, number)
        rank_between(cs, options, number, min, max)

      nil ->
        if get_field(cs, options.rank_field) &&
             (get_change(cs, options.rank_field) || !options.scope_field ||
                !changes_to_scope_fields(cs, options.scope_field)) do
          cs
        else
          update_index_from_position(cs, options, "last")
        end

      _ ->
        raise ArgumentError, "invalid position"
    end
  end

  defp changes_to_scope_fields(cs, scope_field) when is_list(scope_field) do
    Enum.any?(scope_field, fn field ->
      changes_to_scope_fields(cs, field)
    end)
  end

  defp changes_to_scope_fields(cs, scope_field) do
    get_change(cs, scope_field)
  end

  defp rank_between(cs, options, position, min, max) do
    if max - min <= 1 do
      cs |> rebalance_ranks(options) |> update_index_from_position(options, position)
    else
      rank = EctoRanked.Utils.ceiling((max - min) / 2) + min
      rank_at(cs, options, rank)
    end
  end

  defp rank_at(cs, options, rank) do
    put_change(cs, options.rank_field, rank)
  end

  defp assure_unique_position(cs, options) do
    rank = get_change(cs, options.rank_field)

    if rank && (rank > @max || current_at_rank(cs, options)) do
      rearrange_ranks(cs, options)
    else
      cs
    end
  end

  defp current_at_rank(cs, options) do
    rank = get_field(cs, options.rank_field)

    finder(cs, options)
    |> where([f], field(f, ^options.rank_field) == ^rank)
    |> limit(1)
    |> cs.repo.one(prefix: options.prefix)
  end

  defp rearrange_ranks(cs, options) do
    rank = get_field(cs, options.rank_field)
    current_first = get_current_first(cs, options)
    current_last = get_current_last(cs, options)

    cond do
      # decrement lteq rank
      current_first && current_first > @min && rank == @max ->
        finder(cs, options)
        |> where([m], field(m, ^options.rank_field) <= ^rank)
        |> cs.repo.update_all([inc: [{options.rank_field, -1}]], prefix: options.prefix)

        cs

      # increment gteq rank
      current_last && current_last < @max - 1 && rank < current_last ->
        finder(cs, options)
        |> where([m], field(m, ^options.rank_field) >= ^rank)
        |> cs.repo.update_all([inc: [{options.rank_field, 1}]], prefix: options.prefix)

        cs

      # decrement ltrank
      current_first && current_first > @min && rank > current_first ->
        finder(cs, options)
        |> where([m], field(m, ^options.rank_field) < ^rank)
        |> cs.repo.update_all([inc: [{options.rank_field, -1}]], prefix: options.prefix)

        put_change(cs, options.rank_field, rank - 1)

      true ->
        rebalance_ranks(cs, options)
    end
  end

  defp rebalance_ranks(cs, options) do
    items =
      finder(cs, options)
      |> order_by(asc: ^options.rank_field)
      |> cs.repo.all(prefix: options.prefix)

    rank = get_field(cs, options.rank_field)
    rank_row(cs, options, items, 1, rank)
  end

  defp rank_row(cs, options, items, index, rank, set_self \\ false) do
    if index > length(items) + 1 do
      cs
    else
      rank_value = EctoRanked.Utils.ceiling((@max - @min) / (length(items) + 2) * index) + @min
      current_index = index - 1
      item = Enum.at(items, current_index)

      current_rank = item && Map.get(item, options.rank_field)

      if !set_self && (!item || (current_rank && current_rank < @max && current_rank >= rank)) do
        cs = cs |> put_change(options.rank_field, rank_value)
        rank_row(cs, options, items, index + 1, rank_value, true)
      else
        current_index = if set_self, do: current_index - 1, else: current_index
        item = Enum.at(items, current_index)

        change(item, [{options.rank_field, rank_value}])
        |> cs.repo.update!(prefix: options.prefix)

        rank_row(cs, options, items, index + 1, rank, set_self)
      end
    end
  end

  defp find_neighbors(cs, options, position) when position > 0 do
    results =
      finder(cs, options)
      |> order_by(asc: ^options.rank_field)
      |> limit(2)
      |> offset(^(position - 1))
      |> select([m], field(m, ^options.rank_field))
      |> cs.repo.all(prefix: options.prefix)

    case results do
      [] ->
        {get_current_last(cs, options), @max}

      [lower] ->
        {lower, @max}

      [nil, nil] ->
        rebalance_ranks(cs, options)
        find_neighbors(cs, options, position)

      [lower, upper] ->
        {lower, upper}
    end
  end

  defp find_neighbors(cs, options, _) do
    first = get_current_first(cs, options)

    case first do
      nil -> {@min, @max}
      first -> {@min, first}
    end
  end

  defp get_current_first(cs, options) do
    finder(cs, options)
    |> order_by(asc: ^options.rank_field)
    |> limit(1)
    |> select([m], field(m, ^options.rank_field))
    |> cs.repo.one(prefix: options.prefix)
  end

  defp get_current_last(cs, options) do
    finder(cs, options)
    |> order_by(desc: ^options.rank_field)
    |> limit(1)
    |> select([m], field(m, ^options.rank_field))
    |> cs.repo.one(prefix: options.prefix)
    |> case do
      nil -> @min
      min -> min
    end
  end

  defp find_prev_two(cs, options) do
    rank = get_field(cs, options.rank_field)

    results =
      finder(cs, options)
      |> where([f], field(f, ^options.rank_field) < ^rank)
      |> order_by(desc: ^options.rank_field)
      |> limit(2)
      |> select([f], field(f, ^options.rank_field))
      |> cs.repo.all(prefix: options.prefix)

    case results do
      [] -> nil
      [upper] -> {@min, upper}
      [upper, lower] -> {lower, upper}
    end
  end

  defp find_next_two(cs, options) do
    rank = get_field(cs, options.rank_field)

    results =
      finder(cs, options)
      |> where([f], field(f, ^options.rank_field) > ^rank)
      |> order_by(asc: ^options.rank_field)
      |> limit(2)
      |> select([f], field(f, ^options.rank_field))
      |> cs.repo.all(prefix: options.prefix)

    case results do
      [] -> nil
      [lower] -> {lower, @max}
      [lower, upper] -> {lower, upper}
    end
  end

  defp finder(cs, options) do
    query =
      options
      |> base_query()
      |> scope_query(cs, options.scope_field)

    if cs.data.id do
      query |> where([m], m.id != ^cs.data.id)
    else
      query
    end
  end

  defp base_query(%{base_queryable: base_queryable, module: module} = options)
       when not is_nil(base_queryable),
       do: apply(base_queryable, [module, options])

  defp base_query(options), do: options.module

  defp scope_query(query, cs, scope_field) when is_list(scope_field) do
    Enum.reduce(scope_field, query, fn field, acc ->
      scope_query(acc, cs, field)
    end)
  end

  defp scope_query(query, cs, scope_field) do
    if scope_field do
      scope = get_field(cs, scope_field)

      if scope do
        query |> where([q], field(q, ^scope_field) == ^scope)
      else
        query |> where([q], is_nil(field(q, ^scope_field)))
      end
    else
      query
    end
  end
end
