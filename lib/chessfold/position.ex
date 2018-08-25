defmodule Chessfold.Position do
  @moduledoc false

  defstruct(
    pieces: [],
    turn: nil,
    allowed_castling: 0,
    en_passant_square: false,
    half_move_clock: 0,
    move_number: 0
  )
end
