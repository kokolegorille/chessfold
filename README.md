# Chessfold

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chessfold` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chessfold, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chessfold](https://hexdocs.pm/chessfold).

## Description

This is a translation from Erlang to Elixir

https://github.com/fcardinaux/chessfold

```elixir
iex> Chessfold.all_possible_moves(p) |> Enum.map(fn m -> m.new_position.pieces |> Enum.map(fn p -> Chessfold.square_to_string(p.square) end) end)

iex> Chessfold.all_possible_moves(p) |> Enum.each(fn m -> Chessfold.print_position(m.new_position) end)

iex> Chessfold.all_possible_moves(p) |> Enum.each(fn m -> IO.inspect(m); IO.inspect Chessfold.print_position(m.new_position) end)


```

"""
  [
    0,0,0,0,0,0,0,0,0,5,0,0,0,0,0,0,2,0,0,0, # 0-19
    0,0,0,5,0,0,5,0,0,0,0,0,2,0,0,0,0,0,5,0, # 20-39
    0,0,0,5,0,0,0,0,2,0,0,0,0,5,0,0,0,0,0,0, # 40-59
    5,0,0,0,2,0,0,0,5,0,0,0,0,0,0,0,0,5,0,0, # 60-79
    2,0,0,5,0,0,0,0,0,0,0,0,0,0,5,6,2,6,5,0, # 80-99
    0,0,0,0,0,0,0,0,0,0,6,4,1,4,6,0,0,0,0,0, # 100-119
    0,2,2,2,2,2,2,1,0,1,2,2,2,2,2,2,0,0,0,0, # 120-139
    0,0,6,3,1,3,6,0,0,0,0,0,0,0,0,0,0,0,5,6, # 140-159
    2,6,5,0,0,0,0,0,0,0,0,0,0,5,0,0,2,0,0,5, # 160-179
    0,0,0,0,0,0,0,0,5,0,0,0,2,0,0,0,5,0,0,0, # 180-199
    0,0,0,5,0,0,0,0,2,0,0,0,0,5,0,0,0,0,5,0, # 200-219
    0,0,0,0,2,0,0,0,0,0,5,0,0,5,0,0,0,0,0,0, # 220-239
    2,0,0,0,0,0,0,5,0,0,0,0,0,0,0,0,0        # 240-256
  ]
"""