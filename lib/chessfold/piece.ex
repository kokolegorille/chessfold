defmodule Chessfold.Piece do
  @moduledoc false

  @type color() :: :black | :white
  @type type() :: :pawn | :knight | :bishop | :rook | :queen | :king

  defstruct(
    color: nil,
    type: nil,
    square: false
  )
end
