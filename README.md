# EctoRanked

This package adds automatic ranking to your Ecto models. It's heavily based on
the Rails [ranked-model](https://github.com/mixonic/ranked-model) gem.

## Installation

The package can be installed by adding `ecto_ranked` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ecto_ranked, "~> 0.1.0"}]
end
```

## Usage

To get started:

- ```import EctoRanked```
- Add a `:rank` integer field to your model
- Call `set_rank()` in your changeset
- Optionally, add a virtual `:position` field (with a type of `:any`) so you can move items in your list.

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

## Documentation

Documentation can be found at [https://hexdocs.pm/ecto_ranked](https://hexdocs.pm/ecto_ranked).

## Thanks

- Everyone who contributed to [ranked-model](https://github.com/mixonic/ranked-model/graphs/contributors), of which this package is a rough clone.
- [EctoOrdered](https://github.com/zovafit/ecto-ordered), which provided a great starting point.
