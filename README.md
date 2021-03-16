# EctoRanked

This package adds automatic ranking to your Ecto models. It's heavily based on
the Rails [ranked-model](https://github.com/mixonic/ranked-model) gem.

## Installation

The package can be installed by adding `ecto_ranked` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ecto_ranked, "~> 0.4.0"}]
end
```

## Usage

To get started:

- ```import EctoRanked```
- Add a `:rank` integer field to your model (NOTE: Setting a unique index on this column may cause issues depending on your database platform)
- Call `set_rank()` in your changeset
- Optionally, add a virtual `:position` field (with a type of `:any`) so you can move items in your list. `:position` accepts `:up`, `:down`, `:first`, `:last` or an integer, the integer being the desired position in a 0-based index.

```elixir
defmodule MyApp.Item do
  use MyApp.Web, :model
  import EctoRanked

  schema "items" do
    field :rank, :integer
    field :position, :any, virtual: true
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:position])
    |> set_rank()
  end
end
```

If you need to use field names other than `:rank` and `:position`, you can pass those as options to `set_rank`:

```elixir
defmodule MyApp.Item do
  use MyApp.Web, :model
  import EctoRanked

  schema "items" do
    field :my_ranking_field, :integer
    field :my_position_field, :any, virtual: true
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:my_position_field])
    |> set_rank(rank: :my_ranking_field, position: :my_position_field)
  end
end
```

If you'd like to scope your ranking to a certain field (e.g. an association, string field, etc.),
just add a `:scope` argument to `set_rank`:

```elixir
defmodule MyApp.Item do
  use MyApp.Web, :model
  import EctoRanked

  schema "items" do
    field :rank, :integer
    field :position, :any, virtual: true
    belongs_to :parent, MyApp.Parent
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:position])
    |> set_rank(scope: :parent_id)
  end
end
```

You can scope across multiple fields:

```elixir
struct
|> cast(params, [:position, :parent_id, :category])
|> set_rank(scope: [:parent_id, :category])
```

You can even have multiple rankings that sort independently of each other (e.g. a scoped one and a global one, or multiple global ones):

```elixir
struct
|> cast(params, [:local_position, :global_position, :parent_id])
|> set_rank(rank: :scoped_rank, position: :scoped_position, scope: :parent_id)
|> set_rank(rank: :global_rank, position: :global_position)
```

You can also pass a `:base_queryable` to scope more complex cases:

```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:position])
  |> set_rank(base_queryable: &not_deleted_query/2)
end

def not_deleted_query(module, _options) do
  from(items in module, where: not is_nil(items.deleted))
end
```

Position is a write-only virtual attribute that's meant for placing an item at
a specific rank. By default the `position` attribute  will be `nil` but you can
calculate it on demand:

```elixir
def compute_positions(items \\ []) do
  for {item, i} <- Enum.with_index(items) do
    %{item | position: i}
  end
end

Item
|> order_by([:rank])
|> Repo.all()
|> Item.compute_positions()
```

## Documentation

Documentation can be found at [https://hexdocs.pm/ecto_ranked](https://hexdocs.pm/ecto_ranked).

## Thanks

- Everyone who contributed to [ranked-model](https://github.com/mixonic/ranked-model/graphs/contributors), of which this package is a rough clone.
- [EctoOrdered](https://github.com/zovafit/ecto-ordered), which provided a great starting point.
