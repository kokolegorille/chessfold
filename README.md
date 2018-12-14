# Chessfold

This is a translation from Erlang to Elixir

https://github.com/fcardinaux/chessfold

## Installation

This package is not available on Hex.

## Description

* Constants definition are not totally equivalent

-type chessfold_square()        :: ?BOTTOM_LEFT_CORNER..?TOP_RIGHT_CORNER. % In 0x88 representation

but @bottom_left_corner..@top_right_corner does not work in Elixir!

* rewrite lists:.. to Elixir equvalent

lists:filter
lists:keyfind
lists:keydelete
lists:foldl
lists:nth

* functions are mostly piped from the end -> adapt for Elixir

eg. Erlang

```erlang
accumulate_pseudo_legal_rook_moves(#chessfold_position{turn = Turn} = Position, MovedPiece, MoveListAcc) ->
    Square = MovedPiece#chessfold_piece.square,
    accumulate_moves(Position, MovedPiece, Square,  ?ROW_SPAN, Turn, true, 
    accumulate_moves(Position, MovedPiece, Square, -?ROW_SPAN, Turn, true, 
    accumulate_moves(Position, MovedPiece, Square,   1, Turn, true, 
    accumulate_moves(Position, MovedPiece, Square,  -1, Turn, true, MoveListAcc)))).
```

Elixir equivalent (accumulate_move has been modified to accept the list as first param.)

```elixir
  defp accumulate_pseudo_legal_rook_moves(
         %Position{turn: turn} = position,
         %Piece{square: square} = moved_piece,
         move_list_acc
       ) do
    move_list_acc
    |> accumulate_moves(position, moved_piece, square, -1, turn, true)
    |> accumulate_moves(position, moved_piece, square, 1, turn, true)
    |> accumulate_moves(position, moved_piece, square, -@row_span, turn, true)
    |> accumulate_moves(position, moved_piece, square, @row_span, turn, true)
  end
```


* Strings are not equivalent in Erlang/Elixir
* Erlang is using hrl files


## Sample usage

```elixir
iex> string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
iex> p = Chessfold.string_to_position string
iex> Chessfold.all_possible_moves(p) |> Enum.map(fn m -> m.new_position.pieces |> Enum.map(fn p -> Chessfold.square_to_string(p.square) end) end)
iex> Chessfold.all_possible_moves(p) |> Enum.each(fn m -> Chessfold.print_position(m.new_position) end)
iex> Chessfold.all_possible_moves(p) |> Enum.each(fn m -> IO.inspect(m); IO.inspect Chessfold.print_position(m.new_position) end)
```

Load position from fen string

```elixir
iex> string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
iex> position = Chessfold.string_to_position string
iex> Chessfold.all_possible_moves(p) |> Enum.map(&Chessfold.move_to_string(&1))
['h2h3', 'h2h4', 'g2g3', 'g2g4', 'f2f3', 'f2f4', 'e2e3', 'e2e4', 'd2d3', 'd2d4',
 'c2c3', 'c2c4', 'b2b3', 'b2b4', 'a2a3', 'a2a4', 'g1h3', 'g1f3', 'b1c3', 'b1a3']

iex> e4 = Chessfold.all_possible_moves(position) |> Chessfold.select_move("e2e4")
iex> e5 = Chessfold.all_possible_moves(e4.new_position) |> Chessfold.select_move("e7e5")
```

Mate in two

```elixir
iex> f3 = Chessfold.all_possible_moves(p) |> Chessfold.select_move("f2f3")
iex> e5 = Chessfold.all_possible_moves(f3.new_position) |> Chessfold.select_move("e7e5")
iex> g4 = Chessfold.all_possible_moves(e5.new_position) |> Chessfold.select_move("g2g4")
iex> qh4 = Chessfold.all_possible_moves(g4.new_position) |> Chessfold.select_move("d8h4")

iex> Chessfold.is_king_attacked qh4.new_position
true
iex> Chessfold.all_possible_moves(qh4.new_position)
[]
iex> Chessfold.print_position qh4.new_position
[
  ["r", "n", "b", ".", "k", "b", "n", "r"],
  ["p", "p", "p", "p", ".", "p", "p", "p"],
  [".", ".", ".", ".", ".", ".", ".", "."],
  [".", ".", ".", ".", "p", ".", ".", "."],
  [".", ".", ".", ".", ".", ".", "P", "q"],
  [".", ".", ".", ".", ".", "P", ".", "."],
  ["P", "P", "P", "P", "P", ".", ".", "P"],
  ["R", "N", "B", "Q", "K", "B", "N", "R"]
]
```

Play API

```elixir
iex> string = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
iex> p = Chessfold.string_to_position string
iex> ["e4", "c5", "Nf3", "d6"] |> Enum.reduce(p, fn(m, acc) -> {:ok, acc} = Chessfold.play(acc, m); acc end) |> Chessfold.print_position

iex> pgn_moves = """
e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3 Nb8 d4 Nbd7 c4 c6 cxb5 axb5 Nc3 Bb7 Bg5 b4 Nb1 h6 Bh4 c5 dxe5 Nxe4 Bxe7 
Qxe7 exd6 Qf6 Nbd2 Nxd6 Nc4 Nxc4 Bxc4 Nb6 Ne5 Rae8 Bxf7+ Rxf7 Nxf7 Rxe1+ Qxe1 Kxf7 Qe3 Qg5 Qxg5 hxg5 b3 Ke6 a3 Kd6 axb4 cxb4 Ra5 Nd5 
f3 Bc8 Kf2 Bf5 Ra7 g6 Ra6+ Kc5 Ke1 Nf4 g3 Nxh3 Kd2 Kb5 Rd6 Kc5 Ra6 Nf2 g4 Bd3 Re6
"""
iex> final_position = pgn_moves |> String.split(" ") |> Enum.reduce(p, fn(m, acc) -> {:ok, acc} = Chessfold.play(acc, m); acc end) |> Chessfold.print_position
```
