defmodule Chessfold do
  @moduledoc false
  use Bitwise

  alias Chessfold.{Move, Piece, Position}

  # Noticeable values in 0x88 representation: 
  @row_span 16
  @move_up 16
  @move_up_left 15
  @move_up_right 17
  @move_up_2 32
  @move_down -16
  @move_down_left -17
  @move_down_right -15
  @move_down_2 -32
  @bottom_left_corner 0
  @bottom_right_corner 7
  @top_left_corner 112
  @top_right_corner 119
  @castling_all 15
  @castling_white_king 8
  @castling_white_queen 4
  @castling_black_king 2
  @castling_black_queen 1

  # Thoses are used as index accessor for Erlang Record
  # Not needed with Elixir map!

  # @piece_record_color     2
  # @piece_record_type      3
  # @piece_record_square    4

  # Attack- and delta-array and constants (source: Jonatan Pettersson (mediocrechess@gmail.com))
  # Deltas that no piece can move
  @attack_none 0
  # One square up down left and right
  @attack_kqr 1
  # More than one square up down left and right
  @attack_qr 2
  # One square diagonally up
  @attack_kqbwp 3
  # One square diagonally down
  @attack_kqbbp 4
  # More than one square diagonally
  @attack_qb 5
  # Knight moves
  @attack_n 6

  # Code.eval_string is used to preserve data structure from being formatted
  # https://elixirforum.com/t/configure-formatter-to-ignore-some-part-of-code/16081

  # Formula: attacked_square - attacking_square + 128 = pieces able to attack
  @attack_array Code.eval_string("""
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
                """)
                |> elem(0)

  # Same as attack array but gives the delta needed to get to the square
  @delta_array Code.eval_string("""
               [  
                 0,   0,   0,   0,   0,   0,   0,   0,   0, -17,   0,   0,   0,   0,   0,   0, -16,   0,   0,   0,
                 0,   0,   0, -15,   0,   0, -17,   0,   0,   0,   0,   0, -16,   0,   0,   0,   0,   0, -15,   0,
                 0,   0,   0, -17,   0,   0,   0,   0, -16,   0,   0,   0,   0, -15,   0,   0,   0,   0,   0,   0,
                 -17,   0,   0,   0, -16,   0,   0,   0, -15,   0,   0,   0,   0,   0,   0,   0,   0, -17,   0,   0,
                 -16,   0,   0, -15,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, -17, -33, -16, -31, -15,   0,
                 0,   0,   0,   0,   0,   0,   0,   0,   0,   0, -18, -17, -16, -15, -14,   0,   0,   0,   0,   0,
                 0,  -1,  -1,  -1,  -1,  -1,  -1,  -1,   0,   1,   1,   1,   1,   1,   1,   1,   0,   0,   0,   0,
                 0,   0,  14,  15,  16,  17,  18,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  15,  31,
                 16,  33,  17,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  15,   0,   0,  16,   0,   0,  17,
                 0,   0,   0,   0,   0,   0,   0,   0,  15,   0,   0,   0,  16,   0,   0,   0,  17,   0,   0,   0,
                 0,   0,   0,  15,   0,   0,   0,   0,  16,   0,   0,   0,   0,  17,   0,   0,   0,   0,  15,   0,
                 0,   0,   0,   0,  16,   0,   0,   0,   0,   0,  17,   0,   0,  15,   0,   0,   0,   0,   0,   0,
                 16,   0,   0,   0,   0,   0,   0,  17,   0,   0,   0,   0,   0,   0,   0,   0,   0
               ]
               """)
               |> elem(0)

  # ADDITIONAL
  @san_regex ~r/([BKNPQR])?(([a-h])?([1-8])?)(x)?([a-h])([1-8])(\s*[eE]\.?[pP]\.?\s*)?=?([BNQR])?[\+#]?/
  @coordinates_regex ~r/^([a-h])?([1-8])?([a-h])?([1-8])?$/

  def player_color(%Position{turn: turn}), do: turn

  def player_color(position_string) when is_binary(position_string) do
    player_color(string_to_position(position_string))
  end

  def opponent_color(position_or_string) do
    case player_color(position_or_string) do
      :white -> :black
      _ -> :white
    end
  end

  def pieces(%Position{pieces: pieces}), do: pieces

  def pieces(position_string) do
    position_string
    |> string_to_position()
    |> pieces()
  end

  def is_king_attacked(%Position{pieces: pieces, turn: player_color} = position) do
    is_square_in_attack(pieces, opponent_color(position), king_square(pieces, player_color))
  end

  def is_king_attacked(position_string) when is_binary(position_string) do
    position_string
    |> string_to_position()
    |> is_king_attacked()
  end

  defp king_square(pieces, king_color) do
    the_func = fn piece ->
      case {piece.color, piece.type} do
        {^king_color, :king} -> true
        _ -> false
      end
    end

    case Enum.filter(pieces, the_func) do
      [player_king] -> player_king.square
      _ -> false
    end
  end

  def string_to_position(position_string) do
    try do
      [
        board_string,
        turn_string,
        allowed_castling_string,
        en_passant | remaining
      ] = String.split(position_string, " ")

      {half_move_clock, move_number} =
        case remaining do
          [hmc_char, mn_char] -> {String.to_integer(hmc_char), String.to_integer(mn_char)}
          [hmc_char] -> {String.to_integer(hmc_char), 1}
          [] -> {0, 1}
        end

      pieces = board_string_to_pieces(board_string)

      allowed_castling =
        allowed_castling_string
        |> to_charlist()
        |> allowed_castling_string_to_value()

      en_passant_square =
        en_passant
        |> to_charlist()
        |> en_passant_string_to_square()

      turn =
        case turn_string do
          "w" -> :white
          _ -> :black
        end

      %Position{
        pieces: pieces,
        turn: turn,
        allowed_castling: allowed_castling,
        en_passant_square: en_passant_square,
        half_move_clock: half_move_clock,
        move_number: move_number
      }
    rescue
      e -> {:error, "failed to parse string, #{inspect(e)} #{position_string}"}
    end
  end

  defp board_string_to_pieces(board_string) do
    row_strings =
      board_string
      |> String.split("/")
      |> Enum.reverse()
      |> to_charlist()

    row_strings_to_pieces(row_strings)
  end

  defp row_strings_to_pieces(row_strings), do: row_strings_to_pieces(row_strings, [], 0)
  defp row_strings_to_pieces([], pieces, 8), do: pieces

  defp row_strings_to_pieces([], _, row_id) when row_id < 8,
    do: raise("too many rows defined #{row_id}")

  defp row_strings_to_pieces([], _, row_id) when row_id > 8,
    do: raise("not enough rows defined #{row_id}")

  defp row_strings_to_pieces(row_strings, pieces, row_id) do
    [row_string | remaining] = row_strings

    row_strings_to_pieces(
      remaining,
      square_chars_to_pieces(to_charlist(row_string), pieces, row_id),
      row_id + 1
    )
  end

  defp square_chars_to_pieces(row_string, pieces, row_id),
    do: square_chars_to_pieces(row_string, pieces, row_id * @row_span, row_id * @row_span + 7)

  defp square_chars_to_pieces([], _pieces, current_square_id, last_square_id_of_row)
       when current_square_id - last_square_id_of_row > 1,
       do: raise("too many squares defined #{current_square_id - last_square_id_of_row}")

  defp square_chars_to_pieces([], _pieces, current_square_id, last_square_id_of_row)
       when current_square_id - last_square_id_of_row < 1,
       do: raise("not enough squares defined #{current_square_id - last_square_id_of_row}")

  defp square_chars_to_pieces([], pieces, _, _), do: pieces

  defp square_chars_to_pieces(row_string, pieces, current_square_id, last_square_id_of_row) do
    [square_charcode | remaining] = row_string

    {square_increment, new_piece} =
      case square_charcode do
        ?1 -> {1, :empty_square}
        ?2 -> {2, :empty_square}
        ?3 -> {3, :empty_square}
        ?4 -> {4, :empty_square}
        ?5 -> {5, :empty_square}
        ?6 -> {6, :empty_square}
        ?7 -> {7, :empty_square}
        ?8 -> {8, :empty_square}
        ?r -> {1, charcode_to_pieces(square_charcode)}
        ?n -> {1, charcode_to_pieces(square_charcode)}
        ?b -> {1, charcode_to_pieces(square_charcode)}
        ?q -> {1, charcode_to_pieces(square_charcode)}
        ?k -> {1, charcode_to_pieces(square_charcode)}
        ?p -> {1, charcode_to_pieces(square_charcode)}
        ?R -> {1, charcode_to_pieces(square_charcode)}
        ?N -> {1, charcode_to_pieces(square_charcode)}
        ?B -> {1, charcode_to_pieces(square_charcode)}
        ?Q -> {1, charcode_to_pieces(square_charcode)}
        ?K -> {1, charcode_to_pieces(square_charcode)}
        ?P -> {1, charcode_to_pieces(square_charcode)}
        _ -> raise("Unexpected character: #{square_charcode}")
      end

    new_pieces =
      case new_piece do
        :empty_square -> pieces
        _ -> [%{new_piece | square: current_square_id} | pieces]
      end

    square_chars_to_pieces(
      remaining,
      new_pieces,
      current_square_id + square_increment,
      last_square_id_of_row
    )
  end

  defp charcode_to_pieces(charcode) do
    case charcode do
      ?r -> %Piece{color: :black, type: :rook}
      ?n -> %Piece{color: :black, type: :knight}
      ?b -> %Piece{color: :black, type: :bishop}
      ?q -> %Piece{color: :black, type: :queen}
      ?k -> %Piece{color: :black, type: :king}
      ?p -> %Piece{color: :black, type: :pawn}
      ?R -> %Piece{color: :white, type: :rook}
      ?N -> %Piece{color: :white, type: :knight}
      ?B -> %Piece{color: :white, type: :bishop}
      ?Q -> %Piece{color: :white, type: :queen}
      ?K -> %Piece{color: :white, type: :king}
      ?P -> %Piece{color: :white, type: :pawn}
      _ -> false
    end
  end

  defp en_passant_string_to_square('-'), do: false

  defp en_passant_string_to_square([col_code, row_code])
       when ?a <= col_code and col_code <= ?h and ?1 <= row_code and row_code <= ?8 do
    col_value = col_code - ?a
    row_value = row_code - ?1
    square_reference(row_value, col_value)
  end

  defp en_passant_string_to_square(en_passant),
    do: raise("invalid en passant string #{en_passant}")

  def position_to_string(
        %Position{half_move_clock: half_move_clock, move_number: move_number} = position
      ) do
    Enum.join(
      [
        position_to_string_without_counters(position),
        to_string(half_move_clock),
        to_string(move_number)
      ],
      " "
    )
  end

  def position_to_string_without_counters(%Position{
        pieces: pieces,
        turn: turn,
        allowed_castling: allowed_castling,
        en_passant_square: en_passant_square
      }) do
    board_string = pieces_to_board_string(pieces)

    turn_char =
      case turn do
        :white -> "w"
        _ -> "b"
      end

    allowed_castling = allowed_castling_value_to_string(allowed_castling)
    en_passant = en_passant_square_to_string(en_passant_square)
    Enum.join([board_string, turn_char, allowed_castling, en_passant], " ")
  end

  defp en_passant_square_to_string(false), do: "-"
  defp en_passant_square_to_string(square_number), do: square_to_string(square_number)

  defp pieces_to_board_string(pieces) do
    pieces_to_row_strings(pieces)
    |> Enum.join("/")
  end

  defp pieces_to_row_strings(pieces), do: pieces_to_row_strings(pieces, 0, [])
  defp pieces_to_row_strings(_, 8, acc), do: acc

  defp pieces_to_row_strings(pieces, row_id, acc) when row_id < 0,
    do: raise("invalid parameters #{inspect(pieces)} #{row_id} #{inspect(acc)}")

  defp pieces_to_row_strings(pieces, row_id, acc) when row_id > 8,
    do: raise("invalid parameters #{inspect(pieces)} #{row_id} #{inspect(acc)}")

  defp pieces_to_row_strings(pieces, row_id, acc) do
    new_row = chess_grid_to_row_chars(pieces, row_id)
    pieces_to_row_strings(pieces, row_id + 1, [new_row | acc])
  end

  defp chess_grid_to_row_chars(pieces, row_id),
    do: chess_grid_to_row_chars(pieces, row_id, 7, [], 0)

  defp chess_grid_to_row_chars(_, _, -1, acc, counter) do
    case counter do
      0 -> acc
      _ -> [to_string(counter) | acc]
    end
    |> Enum.join("")
  end

  defp chess_grid_to_row_chars(pieces, row_id, col_id, acc, counter) do
    square_key = square_reference(row_id, col_id)

    piece_char =
      case get_piece_on_square(pieces, square_key) do
        false -> false
        piece -> piece_to_char(piece)
      end

    {new_acc, new_counter} =
      case {piece_char, counter} do
        {false, _} -> {acc, counter + 1}
        {_, 0} -> {[piece_char | acc], 0}
        _ -> {[piece_char, to_string(counter) | acc], 0}
      end

    chess_grid_to_row_chars(pieces, row_id, col_id - 1, new_acc, new_counter)
  end

  def piece_to_char(%Piece{color: color, type: type}) do
    case {color, type} do
      {:black, :rook} -> "r"
      {:black, :knight} -> "n"
      {:black, :bishop} -> "b"
      {:black, :queen} -> "q"
      {:black, :king} -> "k"
      {:black, :pawn} -> "p"
      {:white, :rook} -> "R"
      {:white, :knight} -> "N"
      {:white, :bishop} -> "B"
      {:white, :queen} -> "Q"
      {:white, :king} -> "K"
      {:white, :pawn} -> "P"
      _ -> false
    end
  end

  def piece_to_char(_), do: false

  def move_to_string(move) do
    square_to_string(move_origin(move)) ++ square_to_string(move_target(move))
  end

  ###############################################################
  ## ALL POSSIBLE MOVES
  ###############################################################

  def all_possible_moves(%Position{} = position) do
    position
    |> all_pseudo_legal_moves()
    |> eliminate_illegal_moves()
  end

  def all_possible_moves(position_string) when is_binary(position_string) do
    position_string
    |> string_to_position
    |> all_possible_moves
  end

  def all_possible_moves_from(%Position{} = position, %Piece{} = start_piece) do
    accumulate_pseudo_legal_moves_of_piece(position, start_piece, [])
    |> eliminate_illegal_moves()
  end

  def all_possible_moves_from(%Position{pieces: pieces} = position, start_square) do
    get_piece_on_square(pieces, start_square)
    |> (fn p -> all_possible_moves_from(position, p) end).()
  end

  defp all_pseudo_legal_moves(%Position{pieces: pieces, turn: turn} = position) do
    player_pieces = pieces_of_color(pieces, turn)

    the_func = fn player_piece, move_list ->
      accumulate_pseudo_legal_moves_of_piece(position, player_piece, move_list)
    end

    player_pieces
    |> List.foldl([], the_func)
  end

  defp accumulate_pseudo_legal_moves_of_piece(
         position,
         %Piece{color: piece_color, type: piece_type} = moved_piece,
         move_list_acc
       ) do
    opponent = opponent_color(position)

    case {piece_color, piece_type} do
      {^opponent, _} -> move_list_acc
      {_, :pawn} -> accumulate_pseudo_legal_pawn_moves(position, moved_piece, move_list_acc)
      {_, :rook} -> accumulate_pseudo_legal_rook_moves(position, moved_piece, move_list_acc)
      {_, :knight} -> accumulate_pseudo_legal_knight_moves(position, moved_piece, move_list_acc)
      {_, :bishop} -> accumulate_pseudo_legal_bishop_moves(position, moved_piece, move_list_acc)
      {_, :queen} -> accumulate_pseudo_legal_queen_moves(position, moved_piece, move_list_acc)
      {_, :king} -> accumulate_pseudo_legal_king_moves(position, moved_piece, move_list_acc)
      _ -> raise({:error, "invalid piece type #{piece_type}"})
    end
  end

  defp accumulate_pseudo_legal_pawn_moves(
         %Position{turn: turn, en_passant_square: en_passant_square} = position,
         %Piece{square: square} = moved_piece,
         move_list_acc
       ) do
    {row_id, col_id} = {div(square, @row_span), rem(square, @row_span)}

    next_row =
      case turn do
        :white -> row_id + 1
        _ -> row_id - 1
      end

    {increment, other_increment, is_promotion} =
      case {turn, row_id} do
        # absurd in normal play
        {:white, 7} ->
          {false, false, false}

        # absurd in normal play
        {:black, 0} ->
          {false, false, false}

        {:white, 1} ->
          {@move_up, @move_up_2, false}

        {:white, 6} ->
          {@move_up, false, true}

        {:black, 6} ->
          {@move_down, @move_down_2, false}

        {:black, 1} ->
          {@move_down, false, true}

        {:white, _} ->
          {@move_up, false, false}

        {:black, _} ->
          {@move_down, false, false}
      end

    # Forward moves, including initial two-row move, resulting in en-passant for the next player

    {move_list_with_forward_1, forward_2_is_blocked} =
      case increment do
        false ->
          {move_list_acc, true}

        _ ->
          new_square_1 = square + increment

          case square_has_piece(position, new_square_1) do
            true ->
              {move_list_acc, true}

            _ ->
              {insert_pseudo_legal_move(
                 move_list_acc,
                 position,
                 moved_piece,
                 %{moved_piece | square: new_square_1},
                 false,
                 false,
                 false,
                 is_promotion
               ), false}
          end
      end

    move_list_with_forward_2 =
      case {forward_2_is_blocked, other_increment} do
        {true, _} ->
          move_list_with_forward_1

        {_, false} ->
          move_list_with_forward_1

        _ ->
          new_square_2 = square + other_increment

          case square_has_piece(position, new_square_2) do
            true ->
              move_list_with_forward_1

            _ ->
              insert_pseudo_legal_move(
                move_list_with_forward_1,
                position,
                moved_piece,
                %{moved_piece | square: new_square_2},
                false,
                false,
                square + increment,
                false
              )
          end
      end

    # Taking moves
    opponent = opponent_color(position)

    move_list_with_left_taking =
      case col_id do
        0 ->
          move_list_with_forward_2

        _ ->
          # Try to take on the left
          left_square = square_reference(next_row, col_id - 1)
          left_taken_piece = get_piece_on_square(position, left_square)

          case {left_taken_piece, en_passant_square} do
            # Don't forget the caret!
            {_, ^left_square} ->
              # En passant
              insert_pseudo_legal_move(
                move_list_with_forward_2,
                position,
                moved_piece,
                %{moved_piece | square: left_square},
                %Piece{
                  color: opponent,
                  type: :pawn,
                  square: square_reference(row_id, col_id - 1)
                },
                false,
                false,
                false
              )

            {false, _} ->
              move_list_with_forward_2

            _ ->
              if left_taken_piece.color == turn do
                move_list_with_forward_2
              else
                insert_pseudo_legal_move(
                  move_list_with_forward_2,
                  position,
                  moved_piece,
                  %{moved_piece | square: left_square},
                  left_taken_piece,
                  false,
                  false,
                  is_promotion
                )
              end
          end
      end

    case col_id do
      7 ->
        move_list_with_left_taking

      _ ->
        # Try to take on the right
        right_square = square_reference(next_row, col_id + 1)
        right_taken_piece = get_piece_on_square(position, right_square)

        case {right_taken_piece, en_passant_square} do
          # Don't forget the caret!
          {_, ^right_square} ->
            # En passant
            insert_pseudo_legal_move(
              move_list_with_left_taking,
              position,
              moved_piece,
              %{moved_piece | square: right_square},
              %Piece{color: opponent, type: :pawn, square: square_reference(row_id, col_id + 1)},
              false,
              false,
              false
            )

          {false, _} ->
            move_list_with_left_taking

          _ ->
            if right_taken_piece.color == turn do
              move_list_with_left_taking
            else
              insert_pseudo_legal_move(
                move_list_with_left_taking,
                position,
                moved_piece,
                %{moved_piece | square: right_square},
                right_taken_piece,
                false,
                false,
                is_promotion
              )
            end
        end
    end
  end

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

  defp accumulate_pseudo_legal_knight_moves(
         %Position{turn: turn} = position,
         %Piece{square: square} = moved_piece,
         move_list_acc
       ) do
    move_list_acc
    |> accumulate_moves(position, moved_piece, square, -33, turn, false)
    # 32 + 1 (0x88 representation)
    |> accumulate_moves(position, moved_piece, square, 33, turn, false)
    |> accumulate_moves(position, moved_piece, square, -31, turn, false)
    # 32 - 1 (0x88 representation)
    |> accumulate_moves(position, moved_piece, square, 31, turn, false)
    |> accumulate_moves(position, moved_piece, square, -18, turn, false)
    # 16 + 2 (0x88 representation)
    |> accumulate_moves(position, moved_piece, square, 18, turn, false)
    |> accumulate_moves(position, moved_piece, square, -14, turn, false)
    # 16 - 2 (0x88 representation)
    |> accumulate_moves(position, moved_piece, square, 14, turn, false)
  end

  defp accumulate_pseudo_legal_bishop_moves(
         %Position{turn: turn} = position,
         %Piece{square: square} = moved_piece,
         move_list_acc
       ) do
    move_list_acc
    |> accumulate_moves(position, moved_piece, square, @move_down_left, turn, true)
    |> accumulate_moves(position, moved_piece, square, @move_up_right, turn, true)
    |> accumulate_moves(position, moved_piece, square, @move_down_right, turn, true)
    |> accumulate_moves(position, moved_piece, square, @move_up_left, turn, true)
  end

  defp accumulate_pseudo_legal_queen_moves(position, moved_piece, move_list_acc) do
    # Don't forget to call the anonymous funtion in the pipe!
    move_list_acc
    # Because move_acc_list is at the end!
    |> (fn x -> accumulate_pseudo_legal_rook_moves(position, moved_piece, x) end).()
    # Because move_acc_list is at the end!
    |> (fn x -> accumulate_pseudo_legal_bishop_moves(position, moved_piece, x) end).()
  end

  defp accumulate_pseudo_legal_king_moves(
         %Position{turn: turn, allowed_castling: allowed_castling} = position,
         %Piece{square: square} = moved_piece,
         move_list_acc
       ) do
    move_list_acc
    |> accumulate_moves(position, moved_piece, square, @move_down_left, turn, false)
    |> accumulate_moves(position, moved_piece, square, @move_up_right, turn, false)
    |> accumulate_moves(position, moved_piece, square, @move_down_right, turn, false)
    |> accumulate_moves(position, moved_piece, square, @move_up_left, turn, false)
    |> accumulate_moves(position, moved_piece, square, -1, turn, false)
    |> accumulate_moves(position, moved_piece, square, 1, turn, false)
    |> accumulate_moves(position, moved_piece, square, @move_down, turn, false)
    |> accumulate_moves(position, moved_piece, square, @move_up, turn, false)
    |> queen_side_castling(position, moved_piece, allowed_castling)
    |> king_side_castling(position, moved_piece, allowed_castling)
  end

  # puts move_list_acc as first param for easy pipe!
  # This will also change params order from original function
  defp king_side_castling(
         move_list_acc,
         %Position{turn: turn} = position,
         %Piece{square: square} = moved_piece,
         allowed_castling
       ) do
    turn_king =
      case turn do
        :white -> @castling_white_king
        _ -> @castling_black_king
      end

    case band(turn_king, allowed_castling) do
      0 ->
        move_list_acc

      _ ->
        piece_on_column_f = get_piece_on_square(position, square + 1)
        piece_on_column_g = get_piece_on_square(position, square + 2)

        cond do
          piece_on_column_f != false ->
            move_list_acc

          piece_on_column_g != false ->
            move_list_acc

          true ->
            insert_pseudo_legal_move(
              move_list_acc,
              position,
              moved_piece,
              %{moved_piece | square: square + 2},
              false,
              :king,
              false,
              false
            )
        end
    end
  end

  defp queen_side_castling(
         move_list_acc,
         %Position{turn: turn} = position,
         %Piece{square: square} = moved_piece,
         allowed_castling
       ) do
    turn_queen =
      case turn do
        :white -> @castling_white_queen
        _ -> @castling_black_queen
      end

    case band(turn_queen, allowed_castling) do
      0 ->
        move_list_acc

      _ ->
        piece_on_column_d = get_piece_on_square(position, square - 1)
        piece_on_column_c = get_piece_on_square(position, square - 2)
        piece_on_column_b = get_piece_on_square(position, square - 3)

        cond do
          piece_on_column_d != false ->
            move_list_acc

          piece_on_column_c != false ->
            move_list_acc

          piece_on_column_b != false ->
            move_list_acc

          true ->
            insert_pseudo_legal_move(
              move_list_acc,
              position,
              moved_piece,
              %{moved_piece | square: square - 2},
              false,
              :queen,
              false,
              false
            )
        end
    end
  end

  # puts move_list_acc as first param for easy pipe!
  # This will also change params order from original function
  defp accumulate_moves(_, _, _, _, 0, _, _), do: raise("invalid increment 0")

  defp accumulate_moves(
         move_list_acc,
         position,
         moved_piece,
         current_square,
         increment,
         turn,
         continue
       ) do
    new_square = current_square + increment

    case is_border_reached(new_square) do
      true ->
        move_list_acc

      _ ->
        occupying_piece = get_piece_on_square(position, new_square)

        case occupying_piece do
          %Piece{color: color} when color == turn ->
            move_list_acc

          false ->
            new_move_list =
              insert_pseudo_legal_move(
                move_list_acc,
                position,
                moved_piece,
                %{moved_piece | square: new_square},
                false,
                false,
                false,
                false
              )

            if continue do
              accumulate_moves(
                new_move_list,
                position,
                moved_piece,
                new_square,
                increment,
                turn,
                continue
              )
            else
              new_move_list
            end

          _ ->
            insert_pseudo_legal_move(
              move_list_acc,
              position,
              moved_piece,
              %{moved_piece | square: new_square},
              occupying_piece,
              false,
              false,
              false
            )
        end
    end
  end

  # Promotion
  defp insert_pseudo_legal_move(
         move_list_acc,
         position,
         from,
         to,
         taken,
         _castling,
         _new_en_passant,
         true
       ) do
    move_list_acc
    |> insert_pseudo_legal_move(position, from, %{to | type: :knight}, taken, false, false, false)
    |> insert_pseudo_legal_move(position, from, %{to | type: :bishop}, taken, false, false, false)
    |> insert_pseudo_legal_move(position, from, %{to | type: :rook}, taken, false, false, false)
    |> insert_pseudo_legal_move(position, from, %{to | type: :queen}, taken, false, false, false)
  end

  # Not a promotion
  defp insert_pseudo_legal_move(
         move_list_acc,
         position,
         from,
         to,
         taken,
         castling,
         new_en_passant,
         false
       ) do
    new_position = get_new_position(position, from, to, taken, castling, new_en_passant)

    move = %Move{
      from: from,
      to: to,
      new_position: new_position,
      castling: castling,
      taken: taken
    }

    [move | move_list_acc]
  end

  defp get_new_position(
         %Position{
           pieces: pieces,
           turn: turn,
           allowed_castling: allowed_castling,
           half_move_clock: half_move_clock,
           move_number: move_number
         },
         from,
         to,
         taken,
         castling,
         new_en_passant
       ) do
    # Delete taken piece
    new_pieces1 =
      case taken do
        # n when n in [false, nil] -> pieces
        false ->
          pieces

        _ ->
          pieces |> Enum.reject(fn p -> p.square == taken.square end)
      end

    # Move piece
    new_pieces2 = move_piece(new_pieces1, from, to)

    # In case of castling, move the rook as well
    new_pieces3 =
      case castling do
        false ->
          new_pieces2

        :queen ->
          rook_square = from.square - 4
          rook_from = %Piece{color: turn, type: :rook, square: rook_square}
          rook_to = %Piece{color: turn, type: :rook, square: rook_square + 3}
          move_piece(new_pieces2, rook_from, rook_to)

        :king ->
          rook_square = from.square + 3
          rook_from = %Piece{color: turn, type: :rook, square: rook_square}
          rook_to = %Piece{color: turn, type: :rook, square: rook_square - 2}
          move_piece(new_pieces2, rook_from, rook_to)
      end

    # Calculate new castling information
    eliminated_castling_of_player =
      case {from.type, from.color, from.square} do
        {:king, :white, _} -> bor(@castling_white_queen, @castling_white_king)
        {:king, _, _} -> bor(@castling_black_queen, @castling_black_king)
        {:rook, _, @bottom_left_corner} -> @castling_white_queen
        {:rook, _, @bottom_right_corner} -> @castling_white_king
        {:rook, _, @top_left_corner} -> @castling_black_queen
        {:rook, _, @top_right_corner} -> @castling_black_king
        _ -> 0
      end

    filter1 = bxor(@castling_all, eliminated_castling_of_player)

    # Calculate the opponent's new castling information (if a tower is taken)
    eliminated_castling_of_opponent =
      case taken do
        false ->
          0

        %Piece{color: victim_color, type: victim_type} ->
          case victim_type do
            :rook ->
              victim_left_square =
                case victim_color do
                  :black -> 112
                  _ -> 0
                end

              case to.square - victim_left_square do
                0 ->
                  case victim_color do
                    :white -> @castling_white_queen
                    _ -> @castling_black_queen
                  end

                7 ->
                  case victim_color do
                    :white -> @castling_white_king
                    _ -> @castling_black_king
                  end

                _ ->
                  0
              end

            _ ->
              0
          end
      end

    filter2 = bxor(@castling_all, eliminated_castling_of_opponent)

    new_allowed_castling =
      allowed_castling
      |> band(filter1)
      |> band(filter2)

    # Update turn and move number
    {new_turn, new_move_number} =
      case turn do
        :white -> {:black, move_number}
        _ -> {:white, move_number + 1}
      end

    # Update half-move clock
    new_half_move_clock =
      cond do
        taken != false -> 0
        from.type == :pawn -> 0
        true -> half_move_clock + 1
      end

    %Position{
      pieces: new_pieces3,
      turn: new_turn,
      allowed_castling: new_allowed_castling,
      en_passant_square: new_en_passant,
      half_move_clock: new_half_move_clock,
      move_number: new_move_number
    }
  end

  defp move_piece(pieces, %Piece{square: from_square} = _from, %Piece{} = to)
       when is_list(pieces) do
    new_pieces =
      pieces
      |> Enum.reject(fn p -> p.square == from_square end)

    [to | new_pieces]
  end

  defp is_border_reached(square) do
    # 16#88 = 136
    case band(square, 136) do
      0 -> false
      _ -> true
    end
  end

  ###############################################################
  ## CHECK FOR ILLEGAL MOVES
  ###############################################################

  defp eliminate_illegal_moves(moves), do: eliminate_illegal_moves(moves, [])
  defp eliminate_illegal_moves([], legal_moves_acc), do: legal_moves_acc

  defp eliminate_illegal_moves([move | remaining_moves] = _moves, legal_moves_acc) do
    # Determine if there is an attack *after* the move
    pieces = move.new_position.pieces
    player_color = move.from.color
    opponent_color = move.new_position.turn

    # The king of the player who has *just played*, i.e. not the same king as if we called is_king_attacked on the resulting position
    kg_square = king_square(pieces, player_color)
    player_king_attacked = is_square_in_attack(pieces, opponent_color, kg_square)

    # In case of castling, verify the start and median square as well
    start_square = move.from.square
    illegal = case {player_king_attacked, move.castling} do
      {true,       _} -> true;
      {false,  false} -> false;
      {false,  :king} -> is_any_square_in_attack(pieces, opponent_color, [start_square, start_square + 1]);
      {false, :queen} -> is_any_square_in_attack(pieces, opponent_color, [start_square, start_square - 1])
    end

    case illegal do
      false -> eliminate_illegal_moves(remaining_moves, [move | legal_moves_acc])
      _ -> eliminate_illegal_moves(remaining_moves, legal_moves_acc)
    end
  end

  defp is_any_square_in_attack(_pieces, _attacking_piece_color, []), do: false

  defp is_any_square_in_attack(pieces, attacking_piece_color, targets) do
    [target | remaining_targets] = targets

    case is_square_in_attack(pieces, attacking_piece_color, target) do
      true -> true
      _ -> is_any_square_in_attack(pieces, attacking_piece_color, remaining_targets)
    end
  end

  # MOVE

  def position_after_move(%Move{new_position: new_position}), do: new_position

  def move_origin(%Move{from: from}), do: from

  def move_target(%Move{to: to}), do: to

  # PIECE

  # def piece_color(%Piece{color: color}), do: color
  #
  # def piece_type(%Piece{type: type}), do: type
  #
  # def piece_square(%Piece{square: square}), do: square

  # SQUARE

  def square_reference(row, col), do: @row_span * row + col

  def square_to_string(%Piece{square: square}), do: square_to_string(square)

  def square_to_string(square) when square > @top_right_corner,
    do: raise("invalid square number #{square}")

  def square_to_string(square) when square < @bottom_left_corner,
    do: raise("invalid square number #{square}")

  def square_to_string(square) do
    # 0x88 representation
    row_value = div(square, @row_span)
    # 0x88 representation
    col_value = rem(square, @row_span)
    
    [col_value + ?a, row_value + ?1]
  end

  def allowed_castling_value_to_string(allowed_castling) do
    wq_char =
      case band(allowed_castling, @castling_white_queen) do
        0 -> ""
        _ -> "Q"
      end

    wk_char =
      case band(allowed_castling, @castling_white_king) do
        0 -> ""
        _ -> "K"
      end

    bq_char =
      case band(allowed_castling, @castling_black_queen) do
        0 -> ""
        _ -> "q"
      end

    bk_char =
      case band(allowed_castling, @castling_black_king) do
        0 -> ""
        _ -> "k"
      end

    allowed_castling_string = Enum.join([wk_char, wq_char, bk_char, bq_char], "")

    case allowed_castling_string do
      "" -> "-"
      allowed_castling_string -> allowed_castling_string
    end
  end

  def allowed_castling_string_to_value(allowed_castling_string) do
    the_func = fn x, value ->
      cond do
        x == ?K -> value + @castling_white_king
        x == ?Q -> value + @castling_white_queen
        x == ?k -> value + @castling_black_king
        x == ?q -> value + @castling_black_queen
        true -> value
      end
    end

    List.foldl(allowed_castling_string, 0, the_func)
  end

  defp get_piece_on_square(%Position{pieces: pieces}, square_key),
    do: get_piece_on_square(pieces, square_key)

  defp get_piece_on_square(pieces, square_key) when is_list(pieces) do
    piece =
      pieces
      |> Enum.filter(fn p -> p.square == square_key end)
      |> List.first()

    if is_nil(piece), do: false, else: piece
  end

  defp square_has_piece(%Position{pieces: pieces}, square_key),
    do: square_has_piece(pieces, square_key)

  defp square_has_piece(pieces, square_key) when is_list(pieces) do
    piece = get_piece_on_square(pieces, square_key)

    case piece do
      false -> false
      _ -> true
    end
  end

  defp is_square_in_attack(pieces, attacking_piece_color, attacked_square) do
    opponent_pieces = pieces_of_color(pieces, attacking_piece_color)

    the_func = fn piece, is_already_in_attack ->
      case is_already_in_attack do
        true ->
          true

        false ->
          attacking_square = piece.square

          attack_array_key =
            try do
              attacked_square - attacking_square + 129
            rescue
              e in ArithmeticError ->
                IO.puts("is_square_in_attack error : #{inspect(e)}")
                0
            end

          # Erlang lists:nth starts at 1!
          # PiecesAbleToAttack  = lists:nth(AttackArrayKey, ?ATTACK_ARRAY),
          pieces_able_to_attack = Enum.at(@attack_array, attack_array_key - 1)

          attacking_piece_type = piece.type

          is_possible_attack =
            case {pieces_able_to_attack, attacking_piece_color, attacking_piece_type} do
              {@attack_none, _, _} -> false
              {@attack_kqr, _, :king} -> true
              {@attack_kqr, _, :queen} -> true
              {@attack_kqr, _, :rook} -> true
              {@attack_qr, _, :queen} -> true
              {@attack_qr, _, :rook} -> true
              {@attack_kqbwp, _, :king} -> true
              {@attack_kqbwp, _, :queen} -> true
              {@attack_kqbwp, _, :bishop} -> true
              {@attack_kqbwp, :white, :pawn} -> true
              {@attack_kqbbp, _, :king} -> true
              {@attack_kqbbp, _, :queen} -> true
              {@attack_kqbbp, _, :bishop} -> true
              {@attack_kqbbp, :black, :pawn} -> true
              {@attack_qb, _, :queen} -> true
              {@attack_qb, _, :bishop} -> true
              {@attack_n, _, :knight} -> true
              _ -> false
            end

          case {is_possible_attack, attacking_piece_type} do
            {false, _} ->
              false

            {true, :pawn} ->
              true

            {true, :knight} ->
              true

            {true, :king} ->
              true

            _ ->
              increment = Enum.at(@delta_array, attack_array_key - 1)

              case is_piece_on_the_way(pieces, attacking_square, attacked_square, increment) do
                true -> false
                _ -> true
              end
          end
      end
    end

    opponent_pieces |> List.foldl(false, the_func)
  end

  defp is_piece_on_the_way(_pieces, square1, square2, _increment) when square1 == square2,
    do: false

  defp is_piece_on_the_way(_pieces, square1, square2, increment)
       when square1 + increment == square2,
       do: false

  defp is_piece_on_the_way(pieces, square1, square2, increment) do
    new_square1 = square1 + increment

    case square_has_piece(pieces, new_square1) do
      true -> true
      _ -> is_piece_on_the_way(pieces, new_square1, square2, increment)
    end
  end

  defp pieces_of_color(pieces, color) do
    pieces
    |> Enum.filter(fn p -> p.color == color end)
  end

  ###############################################################
  ## ADDITIONAL !!
  ###############################################################
  
  def play(%Position{} = position, move) do
    case Chessfold.all_possible_moves(position) |> Chessfold.select_move(move) do
      {:ok, m} -> {:ok, m.new_position}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # This accept san (eg. "e4") or coordinates (eg. "e2e4")
  def select_move(moves, move, promotion_piece \\ :queen) do
    case Regex.run(@coordinates_regex, move) do
      [_, _, _, _, _] -> select_move_by_coordinates(moves, move, promotion_piece)
      _ -> select_move_by_san(moves, move)
    end
  end
  
  defp select_move_by_san([], _), do: {:error, "no moves found"}
  defp select_move_by_san(moves, "O-O") when is_list(moves) do
    [first_move | _tails] = moves
    case first_move.from.color do
      :white -> select_move(moves, "e1g1")
      _ -> select_move(moves, "e8g8")
    end
  end
  defp select_move_by_san(moves, "O-O-O") when is_list(moves) do
    [first_move | _tails] = moves
    case first_move.from.color do
      :white -> select_move_by_coordinates(moves, "e1c1")
      _ -> select_move_by_coordinates(moves, "e8c8")
    end
  end
  defp select_move_by_san(moves, san) when is_list(moves) and is_binary(san) do
    case Regex.run(@san_regex, sanitize_san(san)) do
      [_san, piece, _prefix, from_file, from_rank, _capture, to_rank, to_file] = _splitted_san ->
        filter = fn %Move{from: %Piece{type: from_piece, square: from_square}, to: %Piece{square: to_square}} = _move ->

          to_coordinates = to_square |> Chessfold.square_to_string |> to_string

          [f, r] = from_square |> Chessfold.square_to_string
          rank = char_to_rank_or_file(from_rank)
          file = char_to_rank_or_file(from_file)
          
          to_coordinates == (to_rank <> to_file) &&
          charpiece_to_symbol(piece) == from_piece &&
          (is_nil(rank) || rank == r - ?1) &&
          (is_nil(file) || file == f - ?a)
        end
        
        result = moves |> Enum.filter(&filter.(&1))
        case result do
          [] -> {:error, "no move found"}
          [%Move{} = move] -> {:ok, move}
          [_move|_tail] = _moves -> {:error, "ambigous search, found multipe moves"}
        end
      
      [_san, piece, _prefix, from_file, from_rank, _capture, to_rank, to_file, _ep, promoted_piece] = _splitted_san ->
        filter = fn %Move{from: %Piece{type: from_piece, square: from_square}, to: %Piece{type: to_piece, square: to_square}} = _move -> 
          to_coordinates = to_square |> Chessfold.square_to_string |> to_string

          [f, r] = from_square |> Chessfold.square_to_string
          rank = char_to_rank_or_file(from_rank)
          file = char_to_rank_or_file(from_file)
        
          to_coordinates == (to_rank <> to_file) &&
          charpiece_to_symbol(piece) == from_piece &&
          charpiece_to_symbol(promoted_piece) == to_piece &&
          (is_nil(rank) || rank == r - ?1) &&
          (is_nil(file) || file == f - ?a)
        end
        
        result = moves |> Enum.filter(&filter.(&1))
        case result do
          [] -> {:error, "no move found"}
          [%Move{} = move] -> {:ok, move}
          [_move|_tail] = _moves -> {:error, "ambigous search, found multipe moves"}
        end
        
      _ ->
        {:error, "Could not select by san #{san}"}
    end
  end
  
  defp charpiece_to_symbol(charpiece) do
    case charpiece do
      "K" -> :king
      "Q" -> :queen
      "R" -> :rook
      "B" -> :bishop
      "N" -> :knight
      _ -> :pawn
    end
  end
  
  defp char_to_rank_or_file(char) do
    case char do
      c when c in ["1", "a"] -> 0
      c when c in ["2", "b"] -> 1
      c when c in ["3", "c"] -> 2
      c when c in ["4", "d"] -> 3
      c when c in ["5", "e"] -> 4
      c when c in ["6", "f"] -> 5
      c when c in ["7", "g"] -> 6
      c when c in ["8", "h"] -> 7
      _ -> nil
    end
  end
  
  defp sanitize_san(san) do
    san
    |> String.trim()
    |> String.replace("+", "")
    |> String.replace("!", "")
    |> String.replace("?", "")
    |> String.replace_trailing("-", "")
    |> String.replace_trailing("=", "")
  end
  
  defp select_move_by_coordinates(moves, coordinates, promotion_piece \\ :queen)
  defp select_move_by_coordinates([], _, _), do: {:error, "no moves found"}
  defp select_move_by_coordinates(moves, coordinates, promotion_piece) when is_list(moves) and is_binary(coordinates) do
    filter_string = coordinates |> to_charlist
    filter = fn m -> move_to_string(m) == filter_string end
    
    result = moves |> Enum.filter(&filter.(&1))
    case result do
      [] -> {:error, "no move found"}
      [%Move{} = move] -> {:ok, move}
      [_move|_tail] = moves -> 
        # Promotion!
        case moves |> Enum.filter(fn m -> m.to.type == promotion_piece end) do
          [] -> {:error, "no move found"}
          [%Move{} = move] -> {:ok, move}
          [_move|_tail] = _moves -> {:error, "ambigous search, found multipe moves"}
        end
    end
  end

  # DEBUG

  def print_position(%Position{pieces: pieces} = _position) do
    for row <- 7..0, col <- 0..7 do
      square_key = 16 * row + col

      piece =
        pieces
        |> Enum.filter(fn p -> p.square == square_key end)
        |> List.first()

      if piece do
        piece_to_char(piece)
      else
        "."
      end
    end
    |> Enum.chunk_every(8)
  end
end
