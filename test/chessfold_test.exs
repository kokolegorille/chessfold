defmodule ChessfoldTest do
  use ExUnit.Case
  # doctest Chessfold
  
  alias Chessfold.Position
  
  describe "unit tests" do
    test "allowed_castling_value" do
      assert Chessfold.allowed_castling_value_to_string(15) == "KQkq"
      assert Chessfold.allowed_castling_value_to_string(14) == "KQk"
      assert Chessfold.allowed_castling_value_to_string(13) == "KQq"
      assert Chessfold.allowed_castling_value_to_string(12) == "KQ"
      assert Chessfold.allowed_castling_value_to_string(11) == "Kkq"
      assert Chessfold.allowed_castling_value_to_string(10) == "Kk"
      assert Chessfold.allowed_castling_value_to_string(9) == "Kq"
      assert Chessfold.allowed_castling_value_to_string(8) == "K"
      assert Chessfold.allowed_castling_value_to_string(7) == "Qkq"
      assert Chessfold.allowed_castling_value_to_string(6) == "Qk"
      assert Chessfold.allowed_castling_value_to_string(5) == "Qq"
      assert Chessfold.allowed_castling_value_to_string(4) == "Q"
      assert Chessfold.allowed_castling_value_to_string(3) == "kq"
      assert Chessfold.allowed_castling_value_to_string(2) == "k"
      assert Chessfold.allowed_castling_value_to_string(1) == "q"
      assert Chessfold.allowed_castling_value_to_string(0) == "-"
    end
  end
  
  describe "start position" do
    setup _context do
      {:ok, start_pos: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"}
    end
    
    test "string_to_position", context do
      assert %Position{} = Chessfold.string_to_position(context.start_pos)
    end

    test "string_to_position and reverse", context do
      assert context.start_pos == context.start_pos 
      |> Chessfold.string_to_position 
      |> Chessfold.position_to_string
    end
    
    test "all_possible_moves", context do
      position = Chessfold.string_to_position(context.start_pos)
      moves = Chessfold.all_possible_moves(position)
      assert Enum.count(moves) == 20
    end
  end
  
  describe "play" do
    setup _context do
      {:ok, position: Chessfold.string_to_position("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")}
    end
    
    test "melimate", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("f2f3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e7e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("g2g4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d8h4")
      
      assert Chessfold.is_king_attacked(m.new_position) == true
      assert Chessfold.all_possible_moves(m.new_position) == []
    end
    
    test "promotion", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d7d5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e4d5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("c7c6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d5c6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e7e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("c6b7")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("g8f6")
      
      # Default to queen
      {:ok, promotion} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8")
      assert promotion.to.type == :queen && promotion.to.color == :white
      
      {:ok, promotion} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8", :rook)
      assert promotion.to.type == :rook && promotion.to.color == :white
      
      {:ok, promotion} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8", :bishop)
      assert promotion.to.type == :bishop && promotion.to.color == :white
      
      {:ok, promotion} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8", :knight)
      assert promotion.to.type == :knight && promotion.to.color == :white
      
      assert {:error, "no move found"} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8", :king)
      assert{:error, "no move found"} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("b7a8", :pawn)
    end
    
    test "it allows capture en passant", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("c7c5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e4e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d7d5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e5d6")
      
      assert !!m.taken
    end
    
    test "it check for check", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("f7f5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d1h5")
      
      assert Chessfold.is_king_attacked(m.new_position) == true
      assert Chessfold.all_possible_moves(m.new_position) |> Enum.count == 1
    end
    
    test "it recognize castling", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("h2h3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e7e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("h1h2")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "Qkq"
      
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("a2a3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e7e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("a1a2")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "Kkq"
      
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("h7h6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("g1f3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("h8h7")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "KQq"
      
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("a7a6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("g1f3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("a8a7")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "KQk"
      
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e2e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e7e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e1e2")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "kq"
      
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e8e7")
      
      assert m.new_position.allowed_castling 
      |> Chessfold.allowed_castling_value_to_string() == "-"
    end
    
    ##############################################
    # SAN
    ##############################################
    
    test "it understands san notation", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("e5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Bc4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nc6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Qf3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Qxf7+")
      
      assert Chessfold.is_king_attacked(m.new_position) == true
      assert Chessfold.all_possible_moves(m.new_position) == []
    end
    
    test "it understands ambigous san notation", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("Nf3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nf6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d5")
      
      assert {:error, _reason} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nd2")
      
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nbd2")
      
      assert {:error, _reason} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nd7")
      assert {:ok, _m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nfd7")
    end
    
    test "it understand castling symbol", context do
      {:ok, m} = Chessfold.all_possible_moves(context.position) |> Chessfold.select_move("e4")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nf3")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Nc6")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Bb5")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Bg4")
      
      assert {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("O-O")
      
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("Qd7")
      {:ok, m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("d3")
      
      assert {:ok, _m} = Chessfold.all_possible_moves(m.new_position) |> Chessfold.select_move("O-O-O")
    end
    
    ##############################################
    # PLAY
    ##############################################
    
    test "it can play san move", context do
      {:ok, position} = Chessfold.play(context.position, "e4")
      {:ok, position} = Chessfold.play(position, "c5")
      {:ok, position} = Chessfold.play(position, "Nf3")
      {:ok, position} = Chessfold.play(position, "d6")
      {:ok, position} = Chessfold.play(position, "d4")
      {:ok, position} = Chessfold.play(position, "cxd4")
      {:ok, position} = Chessfold.play(position, "Nxd4")
      {:ok, position} = Chessfold.play(position, "Nf6")
      {:ok, position} = Chessfold.play(position, "Nc3")

      assert Chessfold.position_to_string(position) == "rnbqkb1r/pp2pppp/3p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R b KQkq - 2 5"
    end
    
    test "it can play multiple san moves", context do
      final_position = ["e4", "c5", "Nf3", "d6"]
      |> Enum.reduce(context.position, fn(m, acc) -> {:ok, acc} = Chessfold.play(acc, m); acc end)
      
      assert Chessfold.position_to_string(final_position) == "rnbqkbnr/pp2pppp/3p4/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3"
    end
    
    test "it can play multiple san moves from a long string", context do
      pgn_moves = """
      e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3 Nb8 d4 Nbd7 c4 c6 cxb5 axb5 Nc3 Bb7 Bg5 b4 Nb1 h6 Bh4 c5 dxe5 Nxe4 Bxe7 
      Qxe7 exd6 Qf6 Nbd2 Nxd6 Nc4 Nxc4 Bxc4 Nb6 Ne5 Rae8 Bxf7+ Rxf7 Nxf7 Rxe1+ Qxe1 Kxf7 Qe3 Qg5 Qxg5 hxg5 b3 Ke6 a3 Kd6 axb4 cxb4 Ra5 Nd5 
      f3 Bc8 Kf2 Bf5 Ra7 g6 Ra6+ Kc5 Ke1 Nf4 g3 Nxh3 Kd2 Kb5 Rd6 Kc5 Ra6 Nf2 g4 Bd3 Re6
      """
      
      final_position = pgn_moves 
      |> String.split(" ") 
      |> Enum.reduce(context.position, fn(m, acc) -> {:ok, acc} = Chessfold.play(acc, m); acc end)
      
      assert Chessfold.position_to_string(final_position) == "8/8/4R1p1/2k3p1/1p4P1/1P1b1P2/3K1n2/8 b - - 2 43"
    end
    
    test "it can play promotion", context do
      pgn_moves = """ 
      "e4 Nf6 e5 Nd5 d4 d6 Nf3 Bg4 Be2 Nc6 e6 fxe6 Ng5 Bxe2 Qxe2 Nxd4 Qe4 c5 Nxh7 Nf6 Nxf6 exf6 Qg6 Kd7 Na3 Qe8 Qd3 Qh5 Be3 Nc6 Rd1 Rd8 Qb3 
      b6 Nb5 Qh4 c3 Rh5 Na3 Kc7 h3 d5 g4 Re5 Kf1 Re4 Qc2 Rxg4 f3 Rg3 Qh2 Kb7 Ke2 Rg6 Rhg1 Rxg1 Rxg1 g5 Rg4 Qh7 f4 d4 cxd4 Nxd4 Kf2 Qe4 Qg2 
      Qxg2 Rxg2 gxf4 Bxf4 e5 Be3 Nf5 Rg6 Be7 Rg1 Rd3 Re1 Rxe3 Rxe3 Nxe3 Kxe3 f5 Nc4 f4 Ke4 Bf6 Kf5 Bh8 Ke4 Kc6 Nd2 Kb5 h4 Kb4 h5 c4 h6 Kc5 
      Nf3 Kd6 Nh4 Bf6 h7 b5 Ng6 Ke6 Nf8 Kd6 Ng6 Ke6 Nf8 Kd6 Ng6 Ke6 Nf8 Kf7 Nd7 Bg7 Nxe5 Ke6 Ng6 f3 Nf4 Kd6 Kxf3 Bxb2 Ke4 b4 Ng6 a5 h8=Q Bxh8 
      Nxh8 Kc5 Ng6 a4 Nf4 b3 axb3 a3 Ne6 Kd6 Nd4 a2 bxc4 a1=Q c5 Kc7 Kd5 Qa2 Ke5 Qc4 c6 Qc5 Ke4 Kd6 c7 Qe5"
      """
      
      final_position = pgn_moves 
      |> String.split(" ") 
      |> Enum.reduce(context.position, fn(m, acc) -> {:ok, acc} = Chessfold.play(acc, m); acc end)
      
      assert Chessfold.position_to_string(final_position) == "8/2P5/3k4/4q3/3NK3/8/8/8 w - - 1 81"
    end
    
  end
end
