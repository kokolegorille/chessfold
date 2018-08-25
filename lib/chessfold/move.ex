defmodule Chessfold.Move do
  @moduledoc false

  defstruct(
    from: nil,
    to: nil,
    new_position: nil,
    castling: false,
    taken: false
  )
end
